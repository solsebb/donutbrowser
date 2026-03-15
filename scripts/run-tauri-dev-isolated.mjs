import { spawn } from "node:child_process";
import { homedir } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));

function defaultPaths() {
  if (process.platform === "darwin") {
    return {
      data: join(homedir(), "Library", "Application Support", "DonutBrowserLocalDev"),
      cache: join(homedir(), "Library", "Caches", "DonutBrowserLocalDev"),
    };
  }

  if (process.platform === "win32") {
    const base = process.env.LOCALAPPDATA ?? join(homedir(), "AppData", "Local");
    return {
      data: join(base, "DonutBrowserLocalDev", "data"),
      cache: join(base, "DonutBrowserLocalDev", "cache"),
    };
  }

  const dataHome =
    process.env.XDG_DATA_HOME ?? join(homedir(), ".local", "share");
  const cacheHome = process.env.XDG_CACHE_HOME ?? join(homedir(), ".cache");
  return {
    data: join(dataHome, "DonutBrowserLocalDev"),
    cache: join(cacheHome, "DonutBrowserLocalDev"),
  };
}

const defaults = defaultPaths();
const env = {
  ...process.env,
  DONUTBROWSER_DEV_ISOLATED: process.env.DONUTBROWSER_DEV_ISOLATED ?? "1",
  DONUTBROWSER_DATA_DIR: process.env.DONUTBROWSER_DATA_DIR ?? defaults.data,
  DONUTBROWSER_CACHE_DIR: process.env.DONUTBROWSER_CACHE_DIR ?? defaults.cache,
};

console.log(`Isolated data dir: ${env.DONUTBROWSER_DATA_DIR}`);
console.log(`Isolated cache dir: ${env.DONUTBROWSER_CACHE_DIR}`);

const child = spawn(process.platform === "win32" ? "pnpm.cmd" : "pnpm", ["tauri", "dev"], {
  cwd: repoRoot,
  env,
  stdio: "inherit",
});

child.on("exit", (code, signal) => {
  if (signal) {
    process.kill(process.pid, signal);
    return;
  }

  process.exit(code ?? 1);
});
