import {
  createClient,
  type SupabaseClient,
} from "npm:@supabase/supabase-js@2.57.4";

type UserProfileRow = {
  id: string;
  sync_prefix: string;
  hosted_sync_enabled: boolean;
  cloud_profiles_used: number;
};

type HostedProfileDto = {
  id: string;
  name: string;
  browser: string;
  version: string;
  proxyId: string | null;
  vpnId: string | null;
  processId: number | null;
  lastLaunch: number | null;
  releaseType: string;
  groupId: string | null;
  tags: string[];
  note: string | null;
  syncMode: string | null;
  lastSync: number | null;
  hostOs: string | null;
  proxyBypassRules: string[];
  createdById: string | null;
  createdByEmail: string | null;
  isRunning: boolean;
  sourcePrefix: string;
};

function corsHeaders(request: Request): HeadersInit {
  const origin = request.headers.get("Origin") ?? "*";

  return {
    "Access-Control-Allow-Origin": origin,
    "Access-Control-Allow-Headers":
      "authorization, apikey, content-type, x-client-info",
    "Access-Control-Allow-Methods": "GET, OPTIONS",
    "Access-Control-Max-Age": "86400",
    Vary: "Origin",
  };
}

function json(
  request: Request,
  body: Record<string, unknown>,
  status = 200,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...corsHeaders(request),
    },
  });
}

function mapHostedProfile(
  raw: Record<string, unknown>,
  sourcePrefix: string,
): HostedProfileDto | null {
  if (typeof raw.id !== "string" || typeof raw.name !== "string") {
    return null;
  }

  return {
    id: raw.id,
    name: raw.name,
    browser: typeof raw.browser === "string" ? raw.browser : "",
    version: typeof raw.version === "string" ? raw.version : "",
    proxyId: typeof raw.proxy_id === "string" ? raw.proxy_id : null,
    vpnId: typeof raw.vpn_id === "string" ? raw.vpn_id : null,
    processId: typeof raw.process_id === "number" ? raw.process_id : null,
    lastLaunch: typeof raw.last_launch === "number" ? raw.last_launch : null,
    releaseType:
      typeof raw.release_type === "string" ? raw.release_type : "stable",
    groupId: typeof raw.group_id === "string" ? raw.group_id : null,
    tags: Array.isArray(raw.tags)
      ? raw.tags.filter((item): item is string => typeof item === "string")
      : [],
    note: typeof raw.note === "string" ? raw.note : null,
    syncMode: typeof raw.sync_mode === "string" ? raw.sync_mode : null,
    lastSync: typeof raw.last_sync === "number" ? raw.last_sync : null,
    hostOs: typeof raw.host_os === "string" ? raw.host_os : null,
    proxyBypassRules: Array.isArray(raw.proxy_bypass_rules)
      ? raw.proxy_bypass_rules.filter(
          (item): item is string => typeof item === "string",
        )
      : [],
    createdById:
      typeof raw.created_by_id === "string" ? raw.created_by_id : null,
    createdByEmail:
      typeof raw.created_by_email === "string" ? raw.created_by_email : null,
    isRunning: false,
    sourcePrefix,
  };
}

async function listAllFolders(
  adminClient: SupabaseClient,
  bucket: string,
  prefix: string,
): Promise<string[]> {
  const folders: string[] = [];
  let offset = 0;
  const limit = 100;

  while (true) {
    const { data, error } = await adminClient.storage
      .from(bucket)
      .list(prefix, {
        limit,
        offset,
        sortBy: { column: "name", order: "asc" },
      });

    if (error) {
      throw error;
    }

    if (!data || data.length === 0) {
      break;
    }

    for (const item of data) {
      if (item.name) {
        folders.push(item.name);
      }
    }

    if (data.length < limit) {
      break;
    }

    offset += limit;
  }

  return folders;
}

async function readJsonObject<T>(
  adminClient: SupabaseClient,
  bucket: string,
  path: string,
): Promise<T | null> {
  const { data, error } = await adminClient.storage.from(bucket).download(path);

  if (error || !data) {
    console.warn(`Failed to read hosted profile metadata ${path}:`, error);
    return null;
  }

  const text = await data.text();
  if (!text) {
    return null;
  }

  return JSON.parse(text) as T;
}

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response(null, {
      status: 204,
      headers: corsHeaders(request),
    });
  }

  if (request.method !== "GET") {
    return json(request, { error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const hostedSyncBucket =
    Deno.env.get("HOSTED_SYNC_BUCKET") || "twitterbrowser-sync";

  if (!supabaseUrl || !supabaseAnonKey || !supabaseServiceRoleKey) {
    return json(
      request,
      { error: "Hosted profiles function is not fully configured" },
      500,
    );
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.replace(/^Bearer\s+/i, "");

  if (!accessToken) {
    return json(request, { error: "Missing bearer token" }, 401);
  }

  const authClient = createClient(supabaseUrl, supabaseAnonKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  });

  const adminClient = createClient(supabaseUrl, supabaseServiceRoleKey, {
    auth: {
      autoRefreshToken: false,
      persistSession: false,
    },
  });

  const { data: userData, error: userError } =
    await authClient.auth.getUser(accessToken);

  if (userError || !userData.user) {
    return json(
      request,
      { error: userError?.message ?? "Invalid session" },
      401,
    );
  }

  const { data: profile, error: profileError } = await adminClient
    .from("user_profiles")
    .select("id, sync_prefix, hosted_sync_enabled, cloud_profiles_used")
    .eq("id", userData.user.id)
    .single<UserProfileRow>();

  if (profileError || !profile) {
    return json(
      request,
      { error: profileError?.message ?? "Hosted user profile not found" },
      404,
    );
  }

  if (!profile.hosted_sync_enabled) {
    return json(
      request,
      { error: "Hosted sync is not enabled for this account" },
      403,
    );
  }

  const normalizedPrefix = profile.sync_prefix.endsWith("/")
    ? profile.sync_prefix
    : `${profile.sync_prefix}/`;
  const profilesPrefix = `${normalizedPrefix}profiles`;
  const sourcePrefix = normalizedPrefix;
  const profileId = new URL(request.url).searchParams.get("id");

  if (profileId) {
    const metadataPath = `${profilesPrefix}/${profileId}/metadata.json`;
    const rawProfile = await readJsonObject<Record<string, unknown>>(
      adminClient,
      hostedSyncBucket,
      metadataPath,
    );

    if (!rawProfile) {
      return json(request, { error: "Profile not found" }, 404);
    }

    const mappedProfile = mapHostedProfile(rawProfile, sourcePrefix);
    if (!mappedProfile) {
      return json(request, { error: "Profile metadata is invalid" }, 500);
    }

    return json(request, {
      profile: mappedProfile,
    });
  }

  try {
    const profileFolders = await listAllFolders(
      adminClient,
      hostedSyncBucket,
      profilesPrefix,
    );

    const profiles: HostedProfileDto[] = [];

    for (const folderName of profileFolders) {
      const metadataPath = `${profilesPrefix}/${folderName}/metadata.json`;
      const rawProfile = await readJsonObject<Record<string, unknown>>(
        adminClient,
        hostedSyncBucket,
        metadataPath,
      );
      if (!rawProfile) {
        continue;
      }

      const mappedProfile = mapHostedProfile(rawProfile, sourcePrefix);
      if (mappedProfile) {
        profiles.push(mappedProfile);
      }
    }

    profiles.sort((a, b) => a.name.localeCompare(b.name));

    return json(request, {
      profiles,
      total: profiles.length,
      cloudProfilesUsed: profile.cloud_profiles_used,
    });
  } catch (error) {
    console.error("Failed to list hosted profiles:", error);
    return json(
      request,
      { error: "Unable to load hosted profiles from Supabase storage" },
      500,
    );
  }
});
