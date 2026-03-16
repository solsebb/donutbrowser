import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

export function loadEnvFiles(repoRoot) {
  const merged = {};

  for (const name of [".env", ".env.local"]) {
    const filePath = join(repoRoot, name);
    if (!existsSync(filePath)) {
      continue;
    }

    const content = readFileSync(filePath, "utf8");
    for (const rawLine of content.split(/\r?\n/)) {
      const line = rawLine.trim();
      if (!line || line.startsWith("#")) {
        continue;
      }

      const separatorIndex = line.indexOf("=");
      if (separatorIndex <= 0) {
        continue;
      }

      const key = line.slice(0, separatorIndex).trim();
      let value = line.slice(separatorIndex + 1).trim();
      if (
        (value.startsWith("\"") && value.endsWith("\"")) ||
        (value.startsWith("'") && value.endsWith("'"))
      ) {
        value = value.slice(1, -1);
      }

      merged[key] = value;
    }
  }

  return merged;
}
