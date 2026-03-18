import {
  Controller,
  Get,
  NotFoundException,
  Param,
  Req,
  UseGuards,
} from "@nestjs/common";
import type { Request } from "express";
import { AuthGuard } from "../auth/auth.guard.js";
import type { UserContext } from "../auth/user-context.interface.js";
import type {
  HostedProfileResponseDto,
  HostedProfilesResponseDto,
} from "./dto/profile.dto.js";
import { SyncService } from "./sync.service.js";

@Controller("v1/profiles")
@UseGuards(AuthGuard)
export class ProfilesController {
  constructor(private readonly syncService: SyncService) {}

  private getUserContext(req: Request): UserContext {
    return (req as any).user as UserContext;
  }

  @Get()
  async list(@Req() req: Request): Promise<HostedProfilesResponseDto> {
    return this.syncService.listProfiles(this.getUserContext(req));
  }

  @Get(":id")
  async getById(
    @Param("id") id: string,
    @Req() req: Request,
  ): Promise<HostedProfileResponseDto> {
    const profile = await this.syncService.getProfile(
      id,
      this.getUserContext(req),
    );
    if (!profile) {
      throw new NotFoundException("Profile not found");
    }

    return { profile };
  }
}
