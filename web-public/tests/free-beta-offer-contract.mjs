import assert from "node:assert/strict";
import { existsSync, readFileSync, readdirSync } from "node:fs";
import { join, relative } from "node:path";

const projectRoot = process.cwd();
const sourceRoot = join(projectRoot, "src");

function sourceFiles(directory) {
  return readdirSync(directory, { withFileTypes: true }).flatMap((entry) => {
    const path = join(directory, entry.name);
    if (entry.isDirectory()) return sourceFiles(path);
    return /\.(ts|tsx)$/.test(entry.name) ? [path] : [];
  });
}

function readCorpus(paths) {
  return paths
    .map((path) => `\n/* ${relative(projectRoot, path)} */\n${readFileSync(path, "utf8")}`)
    .join("\n");
}

const corpus = readCorpus(sourceFiles(sourceRoot));

const forbiddenPublicClaims = [
  ["paid tier", /\bpro\b/i],
  ["price", /\bprice\b|preç/i],
  ["upgrade", /\bupgrade\b/i],
  ["market surface", /\bmercado\b/i],
  ["marketplace", /\bmarketplace\b/i],
  ["social surface", /\bsocial\b/i],
  ["trade surface", /\btrades?\b|\btrocas?\b/i]
];

for (const [label, pattern] of forbiddenPublicClaims) {
  assert.doesNotMatch(corpus, pattern, `web-public source reintroduced ${label}`);
}

// D-46: the beta ships neither explainable AI nor shareable reports, so the
// site title, description and landing cannot claim them. The shared report
// page keeps its own label, which server/test/product_retention_report_contract_test.dart locks.
const sharedReportPage = join(sourceRoot, "app", "reports", "[id]", "page.tsx");
const landingCorpus = readCorpus(sourceFiles(sourceRoot).filter((path) => path !== sharedReportPage));
const siteMetadata = readFileSync(join(sourceRoot, "app/layout.tsx"), "utf8");
assert.doesNotMatch(siteMetadata, /IA\s+explic[aá]vel/i, "D-46: site metadata must not claim explainable AI");
assert.doesNotMatch(siteMetadata, /compartilh[aá]ve/i, "D-46: site metadata must not claim shareable reports");
assert.doesNotMatch(corpus, /IA\s+explic[aá]vel/i, "D-46: public source must not claim explainable AI");
assert.doesNotMatch(
  landingCorpus,
  /relat[oó]rios?\s+compartilh[aá]ve(?:l|is)/i,
  "D-46: landing and offer must not promise shareable reports"
);

assert.doesNotMatch(corpus, /routes\.app\b/, "public source must not consume a legacy /app route");
assert.doesNotMatch(
  corpus,
  /href\s*=\s*(?:["'`]\/app(?:[/?#"'`]|\s)|\{\s*(?:routes\.app|["'`]\/app(?:[/?#"'`]|\s))\s*\})/i,
  "public source must not render a link to /app"
);
assert.doesNotMatch(corpus, /Abrir\s+(?:app|BrewTact)/i, "public source must not offer an actionable app CTA");
assert.match(corpus, /Acesso ainda não liberado/, "public source must explain the fail-closed access state");

for (const path of [
  "components/site-shell.tsx",
  "app/page.tsx",
  "app/pricing/page.tsx",
  "app/reports/[id]/page.tsx"
]) {
  assert.match(
    readFileSync(join(sourceRoot, path), "utf8"),
    /<AccessPending\b/,
    `${path} must render the non-interactive access status`
  );
}

assert.ok(existsSync(join(sourceRoot, "app/pricing/page.tsx")), "/pricing must remain informative");
assert.ok(existsSync(join(sourceRoot, "app/reports/[id]/page.tsx")), "explicitly shared reports must remain available");
assert.ok(!existsSync(join(sourceRoot, "app/marketplace/page.tsx")), "marketplace route must stay absent");
assert.ok(!existsSync(join(sourceRoot, "app/decks/[id]/page.tsx")), "public deck route must stay absent");
assert.ok(!existsSync(join(sourceRoot, "app/players/[id]/page.tsx")), "public player route must stay absent");

const offerSource = readFileSync(join(sourceRoot, "lib/product-data.ts"), "utf8");
assert.match(offerSource, /id:\s*"free-beta"/);
assert.match(offerSource, /name:\s*"Beta gratuita"/);
assert.match(offerSource, /sem cobrança/i);

const serverSource = readFileSync(join(sourceRoot, "lib/public-server.ts"), "utf8");
assert.equal((serverSource.match(/\bfetch\s*\(/g) ?? []).length, 1, "only the shared-report fetch helper is allowed");
assert.match(serverSource, /`\/reports\/\$\{encodeURIComponent\(id\)\}`/);
assert.doesNotMatch(serverSource, /\/community\/|\/market\//);

console.log("free beta public offer contract: PASS");
