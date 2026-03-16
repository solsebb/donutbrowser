import { spawn } from "node:child_process";
import { dirname } from "node:path";
import { fileURLToPath } from "node:url";
import { loadEnvFiles } from "./load-env-files.mjs";

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const env = {
  ...loadEnvFiles(repoRoot),
  ...process.env,
};

const child = spawn(
  process.platform === "win32" ? "pnpm.cmd" : "pnpm",
  ["exec", "tauri", ...process.argv.slice(2)],
  {
    cwd: repoRoot,
    env,
    stdio: "inherit",
  },
);

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});
