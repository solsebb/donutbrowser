import { spawnSync } from "node:child_process";
import { existsSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const repoRoot = dirname(dirname(fileURLToPath(import.meta.url)));
const installRoot = join(repoRoot, ".cache", "typos");
const binaryName = process.platform === "win32" ? "typos.exe" : "typos";
const localBinary = join(installRoot, "bin", binaryName);
const typosVersion = "1.42.3";
const args = process.argv.slice(2);

function run(command, commandArgs) {
  const result = spawnSync(command, commandArgs, {
    cwd: repoRoot,
    stdio: "inherit",
  });

  if (result.error) {
    throw result.error;
  }

  if (result.status !== 0) {
    process.exit(result.status ?? 1);
  }
}

function hasGlobalTypos() {
  const result = spawnSync(binaryName, ["--version"], {
    cwd: repoRoot,
    stdio: "ignore",
  });

  return result.status === 0;
}

if (!existsSync(localBinary) && !hasGlobalTypos()) {
  run("cargo", [
    "install",
    "typos-cli",
    "--version",
    typosVersion,
    "--locked",
    "--root",
    installRoot,
  ]);
}

run(existsSync(localBinary) ? localBinary : binaryName, args.length > 0 ? args : ["."]);
