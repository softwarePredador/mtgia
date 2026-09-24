// Captures public site pages in headless Chrome through the DevTools protocol,
// without extra dependencies: Node 22+ (global WebSocket) and a local
// Chrome/Chromium binary (CHROME_BIN, or a known install path).
//
//   node scripts/capture-screens.mjs --base-url http://127.0.0.1:3100 \
//     --out ../docs/qa/execution/<date>/site-publico --prefix final \
//     --routes /,/pricing --full-page
//
// Each run writes one PNG per route, viewport and kind, and merges the entries
// into <out>/capture-manifest.json with the SHA-256, size, document status,
// page metadata, console errors and first-fold position of every capture.
// Chrome resolves no host besides localhost, so a capture never reaches a
// deployed service.
import { execFileSync, spawn } from "node:child_process";
import { createHash } from "node:crypto";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { parseArgs } from "node:util";

const VIEWPORTS = {
  desktop: { name: "desktop_1440x900", width: 1440, height: 900, deviceScaleFactor: 1, mobile: false },
  mobile: { name: "mobile_390x844", width: 390, height: 844, deviceScaleFactor: 2, mobile: true }
};

const CHROME_CANDIDATES = [
  "/opt/pw-browsers/chromium",
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
  "/Applications/Chromium.app/Contents/MacOS/Chromium",
  "/usr/bin/google-chrome",
  "/usr/bin/chromium",
  "/usr/bin/chromium-browser"
];

const NAVIGATION_TIMEOUT_MS = 30_000;
const WEB_ROOT = resolve(dirname(fileURLToPath(import.meta.url)), "..");

// Paths that feed the Next.js build; a change here means the capture does not
// represent the recorded commit.
const BUILD_INPUTS = [
  "src",
  "public",
  "package.json",
  "package-lock.json",
  "next.config.ts",
  "tailwind.config.ts",
  "postcss.config.mjs",
  "tsconfig.json"
];

function usage(message) {
  console.error(`capture-screens: ${message}`);
  console.error(
    "usage: node scripts/capture-screens.mjs --base-url <http://127.0.0.1:port> --out <dir> " +
      "[--routes /,/pricing] [--prefix name] [--viewports desktop,mobile] [--full-page] [--fold-selector #produto]"
  );
  process.exit(2);
}

function parseOptions() {
  const { values } = parseArgs({
    options: {
      "base-url": { type: "string" },
      out: { type: "string" },
      routes: { type: "string", default: "/" },
      prefix: { type: "string", default: "capture" },
      viewports: { type: "string", default: "desktop,mobile" },
      "full-page": { type: "boolean", default: false },
      "fold-selector": { type: "string", default: "#produto" }
    }
  });

  if (!values["base-url"]) usage("--base-url is required");
  if (!values.out) usage("--out is required");
  if (!/^[a-z0-9][a-z0-9-]*$/.test(values.prefix)) usage("--prefix accepts lowercase letters, digits and dashes");

  const baseUrl = new URL(values["base-url"]);
  if (!["127.0.0.1", "localhost", "[::1]"].includes(baseUrl.hostname)) {
    usage("--base-url must be a loopback address; captures never reach deployed hosts");
  }

  const viewports = values.viewports.split(",").map((key) => {
    const viewport = VIEWPORTS[key.trim()];
    if (!viewport) usage(`unknown viewport "${key}"`);
    return viewport;
  });
  const routes = values.routes.split(",").map((route) => route.trim());
  if (routes.some((route) => !route.startsWith("/"))) usage("routes must start with /");

  return {
    baseUrl: baseUrl.origin,
    outDir: resolve(values.out),
    prefix: values.prefix,
    routes,
    viewports,
    fullPage: values["full-page"],
    foldSelector: values["fold-selector"]
  };
}

function resolveChrome() {
  const candidates = [process.env.CHROME_BIN, ...CHROME_CANDIDATES].filter(Boolean);
  const found = candidates.find((candidate) => existsSync(candidate));
  if (!found) usage(`no Chrome/Chromium found; set CHROME_BIN (tried ${candidates.join(", ")})`);
  return found;
}

function gitIdentity() {
  try {
    const sha = execFileSync("git", ["rev-parse", "HEAD"], { cwd: WEB_ROOT, encoding: "utf8" }).trim();
    const changes = execFileSync("git", ["status", "--porcelain", "--", ...BUILD_INPUTS], {
      cwd: WEB_ROOT,
      encoding: "utf8"
    });
    return { git_sha: sha, build_inputs_dirty: changes.trim().length > 0 };
  } catch {
    return { git_sha: null, build_inputs_dirty: null };
  }
}

async function launchChrome(chromePath) {
  const profileDir = mkdtempSync(join(tmpdir(), "brewtact-capture-"));
  const args = [
    "--headless=new",
    "--remote-debugging-port=0",
    `--user-data-dir=${profileDir}`,
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-extensions",
    "--disable-background-networking",
    "--disable-component-update",
    "--disable-sync",
    "--hide-scrollbars",
    "--mute-audio",
    "--force-color-profile=srgb",
    // No proxy and no name resolution besides loopback: Chrome's own
    // background requests fail locally instead of leaving the machine.
    "--no-proxy-server",
    "--host-resolver-rules=MAP * ~NOTFOUND , EXCLUDE localhost , EXCLUDE 127.0.0.1 , EXCLUDE [::1]"
  ];
  if (process.platform === "linux") {
    args.push("--disable-dev-shm-usage");
    if (process.getuid?.() === 0) args.push("--no-sandbox");
  }
  args.push("about:blank");

  const child = spawn(chromePath, args, { stdio: ["ignore", "ignore", "pipe"] });
  let stderr = "";
  child.stderr.on("data", (chunk) => {
    stderr += chunk;
  });

  const portFile = join(profileDir, "DevToolsActivePort");
  const deadline = Date.now() + 20_000;
  while (!existsSync(portFile) || readFileSync(portFile, "utf8").split("\n").length < 2) {
    if (child.exitCode !== null) throw new Error(`Chrome exited early (${child.exitCode}): ${stderr}`);
    if (Date.now() > deadline) throw new Error(`Chrome did not expose DevTools in time: ${stderr}`);
    await new Promise((settle) => setTimeout(settle, 100));
  }
  const [port, path] = readFileSync(portFile, "utf8").split("\n");

  return {
    endpoint: `ws://127.0.0.1:${port.trim()}${path.trim()}`,
    async close() {
      child.kill("SIGTERM");
      await new Promise((settle) => {
        if (child.exitCode !== null) settle();
        else child.once("exit", settle);
      });
      try {
        rmSync(profileDir, { recursive: true, force: true, maxRetries: 10, retryDelay: 200 });
      } catch (error) {
        console.warn(`capture-screens: could not remove ${profileDir}: ${error.message}`);
      }
    }
  };
}

class DevToolsConnection {
  constructor(endpoint) {
    this.socket = new WebSocket(endpoint);
    this.nextId = 1;
    this.pending = new Map();
    this.listeners = new Set();
  }

  open() {
    return new Promise((settle, fail) => {
      this.socket.addEventListener("open", () => settle(), { once: true });
      this.socket.addEventListener("error", () => fail(new Error("DevTools socket error")), { once: true });
      this.socket.addEventListener("message", (event) => this.receive(JSON.parse(event.data)));
    });
  }

  receive(message) {
    if (message.id !== undefined) {
      const request = this.pending.get(message.id);
      if (!request) return;
      this.pending.delete(message.id);
      if (message.error) request.fail(new Error(`${request.method}: ${message.error.message}`));
      else request.settle(message.result);
      return;
    }
    for (const listener of this.listeners) listener(message);
  }

  send(method, params = {}, sessionId) {
    const id = this.nextId++;
    this.socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
    return new Promise((settle, fail) => this.pending.set(id, { method, settle, fail }));
  }

  waitFor(predicate, timeoutMs, label) {
    return new Promise((settle, fail) => {
      const timer = setTimeout(() => {
        this.listeners.delete(listener);
        fail(new Error(`timed out waiting for ${label}`));
      }, timeoutMs);
      const listener = (message) => {
        if (!predicate(message)) return;
        clearTimeout(timer);
        this.listeners.delete(listener);
        settle(message);
      };
      this.listeners.add(listener);
    });
  }

  close() {
    this.socket.close();
  }
}

const settlePage = (foldSelector) => `(async () => {
  const pending = (img) =>
    img.complete
      ? null
      : new Promise((done) => {
          img.addEventListener("load", done, { once: true });
          img.addEventListener("error", done, { once: true });
        });
  await document.fonts.ready;
  await Promise.all(Array.from(document.images).map(pending));
  await new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done)));
  const meta = (selector) => document.querySelector(selector)?.getAttribute("content") ?? null;
  const fold = document.querySelector(${JSON.stringify(foldSelector)});
  return {
    title: document.title,
    description: meta('meta[name="description"]'),
    og_title: meta('meta[property="og:title"]'),
    og_description: meta('meta[property="og:description"]'),
    fonts_loaded: Array.from(document.fonts)
      .filter((font) => font.status === "loaded")
      .map((font) => font.family.replaceAll('"', "") + " " + font.weight),
    inner_height: window.innerHeight,
    fold_top: fold ? Math.round(fold.getBoundingClientRect().top + window.scrollY) : null
  };
})()`;

// Before a full-page capture: load lazy images and pin viewport-relative
// heights, so a taller capture area cannot stretch svh/vh sections.
const PREPARE_FULL_PAGE = `(async () => {
  const viewportSized = document.querySelectorAll('[class*="vh"], .min-h-screen, .h-screen');
  viewportSized.forEach((element) => {
    const style = getComputedStyle(element);
    element.style.minHeight = style.minHeight;
    if (element.classList.contains("h-screen")) element.style.height = style.height;
  });
  const lazy = Array.from(document.querySelectorAll('img[loading="lazy"]'));
  lazy.forEach((img) => { img.loading = "eager"; });
  await Promise.all(lazy.map((img) => img.complete ? null : new Promise((done) => {
    img.addEventListener("load", done, { once: true });
    img.addEventListener("error", done, { once: true });
  })));
  await new Promise((done) => requestAnimationFrame(() => requestAnimationFrame(done)));
  return lazy.length;
})()`;

function pngSize(buffer) {
  const signature = "89504e470d0a1a0a";
  if (buffer.subarray(0, 8).toString("hex") !== signature || buffer.subarray(12, 16).toString("latin1") !== "IHDR") {
    throw new Error("capture is not a valid PNG");
  }
  return { width: buffer.readUInt32BE(16), height: buffer.readUInt32BE(20) };
}

function routeSlug(route) {
  return route.replace(/^\/+|\/+$/g, "").replace(/[^a-z0-9]+/gi, "-").toLowerCase() || "home";
}

async function capturePage(connection, options, route, viewport) {
  const { targetId } = await connection.send("Target.createTarget", { url: "about:blank" });
  const { sessionId } = await connection.send("Target.attachToTarget", { targetId, flatten: true });
  const events = [];
  const collect = (message) => {
    if (message.sessionId === sessionId) events.push(message);
  };
  connection.listeners.add(collect);

  try {
    for (const domain of ["Page", "Runtime", "Network", "Log"]) {
      await connection.send(`${domain}.enable`, {}, sessionId);
    }
    await connection.send(
      "Emulation.setDeviceMetricsOverride",
      {
        width: viewport.width,
        height: viewport.height,
        deviceScaleFactor: viewport.deviceScaleFactor,
        mobile: viewport.mobile
      },
      sessionId
    );
    if (viewport.mobile) {
      await connection.send("Emulation.setTouchEmulationEnabled", { enabled: true, maxTouchPoints: 5 }, sessionId);
    }

    const url = `${options.baseUrl}${route}`;
    const loaded = connection.waitFor(
      (message) => message.sessionId === sessionId && message.method === "Page.loadEventFired",
      NAVIGATION_TIMEOUT_MS,
      `load of ${url}`
    );
    const navigation = await connection.send("Page.navigate", { url }, sessionId);
    if (navigation.errorText) throw new Error(`navigation to ${url} failed: ${navigation.errorText}`);
    await loaded;

    const settled = await connection.send(
      "Runtime.evaluate",
      { expression: settlePage(options.foldSelector), awaitPromise: true, returnByValue: true },
      sessionId
    );
    const page = settled.result.value;

    const documentResponse = events.find(
      (message) =>
        message.method === "Network.responseReceived" &&
        message.params.type === "Document" &&
        message.params.loaderId === navigation.loaderId
    );
    const documentStatus = documentResponse?.params.response.status ?? null;
    const consoleErrors = events.flatMap((message) => {
      if (message.method === "Runtime.exceptionThrown") return [message.params.exceptionDetails.text];
      if (message.method === "Runtime.consoleAPICalled" && message.params.type === "error") {
        return [message.params.args.map((arg) => arg.value ?? arg.description ?? "").join(" ")];
      }
      if (message.method === "Log.entryAdded" && message.params.entry.level === "error") {
        return [message.params.entry.text];
      }
      return [];
    });

    const shots = [{ kind: "viewport", params: { format: "png" } }];
    if (options.fullPage) {
      await connection.send(
        "Runtime.evaluate",
        { expression: PREPARE_FULL_PAGE, awaitPromise: true, returnByValue: true },
        sessionId
      );
      const metrics = await connection.send("Page.getLayoutMetrics", {}, sessionId);
      shots.push({
        kind: "full",
        params: {
          format: "png",
          captureBeyondViewport: true,
          clip: { x: 0, y: 0, width: viewport.width, height: Math.ceil(metrics.cssContentSize.height), scale: 1 }
        }
      });
    }

    const entries = [];
    for (const shot of shots) {
      const { data } = await connection.send("Page.captureScreenshot", shot.params, sessionId);
      const buffer = Buffer.from(data, "base64");
      const suffix = shot.kind === "full" ? "_full" : "";
      const file = `${options.prefix}_${routeSlug(route)}_${viewport.name}${suffix}.png`;
      writeFileSync(join(options.outDir, file), buffer);
      entries.push({
        path: file,
        route,
        viewport: viewport.name,
        device_scale_factor: viewport.deviceScaleFactor,
        kind: shot.kind,
        sha256: createHash("sha256").update(buffer).digest("hex"),
        bytes: buffer.length,
        ...pngSize(buffer),
        document_status: documentStatus,
        ...page,
        console_errors: consoleErrors
      });
    }
    return entries;
  } finally {
    connection.listeners.delete(collect);
    await connection.send("Target.closeTarget", { targetId }).catch(() => undefined);
  }
}

async function main() {
  const options = parseOptions();
  mkdirSync(options.outDir, { recursive: true });
  const chrome = await launchChrome(resolveChrome());
  const connection = new DevToolsConnection(chrome.endpoint);
  const failures = [];
  let entries = [];
  let browser = null;

  try {
    await connection.open();
    browser = (await connection.send("Browser.getVersion")).product;
    for (const route of options.routes) {
      for (const viewport of options.viewports) {
        const captured = await capturePage(connection, options, route, viewport);
        for (const entry of captured) {
          if (entry.document_status !== 200) failures.push(`${entry.path}: HTTP ${entry.document_status}`);
          if (entry.console_errors.length > 0) failures.push(`${entry.path}: ${entry.console_errors.join(" | ")}`);
          console.log(`${entry.path} ${entry.width}x${entry.height} ${entry.sha256}`);
        }
        entries = entries.concat(captured);
      }
    }
  } finally {
    connection.close();
    await chrome.close();
  }

  const manifestPath = join(options.outDir, "capture-manifest.json");
  const previous = existsSync(manifestPath) ? JSON.parse(readFileSync(manifestPath, "utf8")).screenshots : [];
  const written = new Set(entries.map((entry) => entry.path));
  const capturedAt = new Date().toISOString();
  const identity = gitIdentity();
  const screenshots = previous
    .filter((entry) => !written.has(entry.path))
    .concat(entries.map((entry) => ({ ...entry, captured_at: capturedAt, browser, base_url: options.baseUrl, ...identity })))
    .sort((left, right) => left.path.localeCompare(right.path));
  writeFileSync(
    manifestPath,
    `${JSON.stringify({ schema: "brewtact_public_web_capture_v1", screenshots }, null, 2)}\n`
  );

  if (failures.length > 0) {
    console.error(`capture-screens: ${failures.length} capture(s) failed:\n${failures.join("\n")}`);
    process.exit(1);
  }
}

main().catch((error) => {
  console.error(`capture-screens: ${error.message}`);
  process.exit(1);
});
