export class HostedProfileDto {
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
}

export class HostedProfilesResponseDto {
  profiles: HostedProfileDto[];
  total: number;
}

export class HostedProfileResponseDto {
  profile: HostedProfileDto;
}
