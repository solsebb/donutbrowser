import { createClient } from "npm:@supabase/supabase-js@2.57.4";
import { importPKCS8, SignJWT } from "npm:jose@5.9.6";

type UserProfileRow = {
  id: string;
  sync_prefix: string;
  profile_limit: number;
  cloud_profiles_used: number;
  hosted_sync_enabled: boolean;
};

function json(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
    },
  });
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return json({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const supabaseAnonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const supabaseServiceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const syncJwtPrivateKey = Deno.env
    .get("SYNC_JWT_PRIVATE_KEY")
    ?.replace(/\\n/g, "\n");

  if (
    !supabaseUrl ||
    !supabaseAnonKey ||
    !supabaseServiceRoleKey ||
    !syncJwtPrivateKey
  ) {
    return json(
      { error: "Supabase hosted sync function is not fully configured" },
      500,
    );
  }

  const authorization = request.headers.get("Authorization");
  const accessToken = authorization?.replace(/^Bearer\s+/i, "");

  if (!accessToken) {
    return json({ error: "Missing bearer token" }, 401);
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
    return json({ error: userError?.message ?? "Invalid session" }, 401);
  }

  const { data: profile, error: profileError } = await adminClient
    .from("user_profiles")
    .select(
      "id, sync_prefix, profile_limit, cloud_profiles_used, hosted_sync_enabled",
    )
    .eq("id", userData.user.id)
    .single<UserProfileRow>();

  if (profileError || !profile) {
    return json(
      { error: profileError?.message ?? "Hosted user profile not found" },
      404,
    );
  }

  if (!profile.hosted_sync_enabled) {
    return json({ error: "Hosted sync is not enabled for this account" }, 403);
  }

  const privateKey = await importPKCS8(syncJwtPrivateKey, "RS256");
  const syncToken = await new SignJWT({
    prefix: profile.sync_prefix,
    profileLimit: profile.profile_limit,
    teamPrefix: null,
    teamProfileLimit: 0,
  })
    .setProtectedHeader({ alg: "RS256", typ: "JWT" })
    .setSubject(userData.user.id)
    .setIssuedAt()
    .setExpirationTime("1h")
    .sign(privateKey);

  return json({
    syncToken,
    prefix: profile.sync_prefix,
    profileLimit: profile.profile_limit,
    cloudProfilesUsed: profile.cloud_profiles_used,
  });
});
