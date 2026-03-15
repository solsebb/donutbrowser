import { execFileSync } from "node:child_process";
import { cpSync, mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = dirname(scriptsDir);
const sourceIcon = join(repoRoot, "src-tauri", "icons", "logo_icon_desktop.png");
const iconOutputDir = join(repoRoot, "src-tauri", "icons");
const tempDir = mkdtempSync(join(tmpdir(), "twitterbrowser-app-icon-"));
const stagedIcon = join(tempDir, "logo_icon_desktop_padded.png");

// macOS app icons usually reserve more breathing room than raw square artwork.
// Stage a padded copy for bundling while leaving the user-provided source asset untouched.
const macosVisualInset = "768";

try {
  cpSync(sourceIcon, stagedIcon);
  execFileSync("sips", ["-z", macosVisualInset, macosVisualInset, stagedIcon], {
    stdio: "inherit",
  });
  execFileSync("sips", ["-p", "1024", "1024", stagedIcon], {
    stdio: "inherit",
  });
  execFileSync("pnpm", ["tauri", "icon", stagedIcon, "-o", iconOutputDir], {
    cwd: repoRoot,
    stdio: "inherit",
  });
} finally {
  rmSync(tempDir, { force: true, recursive: true });
}
