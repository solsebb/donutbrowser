import { mkdirSync, writeFileSync } from "node:fs";
import { homedir } from "node:os";
import { join, resolve } from "node:path";
import { generateKeyPairSync } from "node:crypto";

const timestamp = new Date().toISOString().replaceAll(":", "-");
const defaultOutputDir = join(
  homedir(),
  ".twitterbrowser",
  "hosted-sync-keys",
  timestamp,
);

const argOutputDir = process.argv[2];
const outputDir = resolve(argOutputDir ?? defaultOutputDir);

mkdirSync(outputDir, { recursive: true });

const { privateKey, publicKey } = generateKeyPairSync("rsa", {
  modulusLength: 4096,
  publicKeyEncoding: {
    type: "spki",
    format: "pem",
  },
  privateKeyEncoding: {
    type: "pkcs8",
    format: "pem",
  },
});

writeFileSync(join(outputDir, "sync-jwt-private.pem"), privateKey);
writeFileSync(join(outputDir, "sync-jwt-public.pem"), publicKey);
writeFileSync(
  join(outputDir, "README.txt"),
  [
    "TwitterBrowser hosted sync JWT keypair",
    "",
    `Created: ${new Date().toISOString()}`,
    "",
    "Use sync-jwt-private.pem for the Supabase Edge Function secret:",
    "  SYNC_JWT_PRIVATE_KEY",
    "",
    "Use sync-jwt-public.pem for donut-sync runtime env:",
    "  SYNC_JWT_PUBLIC_KEY",
    "",
    "Do not commit these files.",
  ].join("\n"),
);

console.log(`Generated hosted sync JWT keypair in ${outputDir}`);
