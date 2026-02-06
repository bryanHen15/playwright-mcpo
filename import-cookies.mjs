import fs from "fs";
import { firefox } from "playwright";

const cookiesPath = process.env.COOKIES_PATH || "/data/cookies.json";
const userDataDir = process.env.PLAYWRIGHT_MCP_USER_DATA_DIR || "/data/profile";
const stateFlag = `${userDataDir}/.cookies-imported`;

if (!fs.existsSync(cookiesPath)) {
  console.error(`cookies file not found at ${cookiesPath}`);
  process.exit(1);
}

if (fs.existsSync(stateFlag)) {
  console.log("Cookies already imported, skipping.");
  process.exit(0);
}

const raw = fs.readFileSync(cookiesPath, "utf-8");
let parsed;
try {
  parsed = JSON.parse(raw);
} catch (e) {
  console.error("cookies.json is not valid JSON");
  process.exit(1);
}

// Support common exporter shapes:
// - Array of cookies
// - { cookies: [...] }
const cookies = Array.isArray(parsed) ? parsed : parsed.cookies;

if (!Array.isArray(cookies) || cookies.length === 0) {
  console.error("No cookies found in cookies.json");
  process.exit(1);
}

// Normalize fields for Playwright addCookies()
const normalized = cookies.map((c) => {
  const out = {
    name: c.name,
    value: c.value,
    domain: c.domain,
    path: c.path || "/",
    httpOnly: !!(c.httpOnly ?? c.http_only),
    secure: !!(c.secure ?? c.isSecure),
    sameSite: c.sameSite || c.same_site || "Lax",
  };

  // expires should be seconds since epoch (optional)
  if (typeof c.expires === "number") out.expires = c.expires;
  if (typeof c.expirationDate === "number") out.expires = c.expirationDate;

  return out;
});

console.log(`Importing ${normalized.length} cookies into persistent profile: ${userDataDir}`);

const context = await firefox.launchPersistentContext(userDataDir, {
  headless: true,
});

await context.addCookies(normalized);
await context.close();

// Mark as imported
fs.mkdirSync(userDataDir, { recursive: true });
fs.writeFileSync(stateFlag, new Date().toISOString());

console.log("Cookies imported successfully.");
