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

// Each pattern carries a sample it must match, so a broken pattern cannot pass
// by never matching anything.
const forbiddenPublicClaims = [
  ["paid tier", /\bpro\b/i, "plano Pro"],
  ["price", /\bprice\b|preç/i, "preço"],
  ["upgrade", /\bupgrade\b/i, "faça upgrade"],
  ["market surface", /\bmercado\b/i, "mercado de cartas"],
  ["marketplace", /\bmarketplace\b/i, "marketplace"],
  ["social surface", /\bsocial\b/i, "rede social"],
  ["trade surface", /\btrades?\b|\btrocas?\b/i, "trocas de cartas"],
  // Battle, Scanner, Generate/Rebuild, Learning and the social surfaces stay
  // off in the beta (docs/status/CURRENT_PRODUCT_DECISION.md).
  ["battle surface", /\bbattle\b|\bbatalhas?\b|jogar\s+contra/i, "jogar contra a IA"],
  ["scanner surface", /\bscanner\b|\bc[aâ]mera\b/i, "leia a carta com a câmera"],
  ["deck generation", /\bgenerate\b|\brebuild\b|\bgerar\s+(?:um\s+|o\s+)?decks?\b/i, "gerar um deck"],
  ["learning surface", /\blearning\b|aprendizad/i, "aprendizado com as partidas"],
  ["public social surface", /\bgaleria\b|\bseguidor(?:es)?\b|coment[aá]rios?/i, "comentários e seguidores"]
];

for (const [label, pattern, sample] of forbiddenPublicClaims) {
  assert.match(sample, pattern, `${label} pattern must match its own sample`);
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

// D-16: the first cohort enters by invitation and there is no waitlist, so the
// site says so and offers no way to queue: no form or field, no mail capture,
// no server action and no route handler besides /healthz.
assert.match(landingCorpus, /por convite/i, "D-16: the site must say that access is by invitation");
const waitlistOffers = [
  ["waitlist copy", /lista\s+de\s+espera|\bwait-?list\b/i, "entre na lista de espera"],
  ["sign-up call", /inscreva-se|cadastre-se|avise-me|me\s+avise|newsletter|quero\s+participar/i, "Inscreva-se"],
  ["invite request", /(?:pe[çc]a|solicite|garanta|reserve)\s+(?:j[aá]\s+)?(?:o\s+|seu\s+|sua\s+)?(?:convite|vaga|lugar)/i, "Peça seu convite"],
  ["form control", /<(?:form|input|textarea|select)\b/i, '<form action="/espera">'],
  ["mail capture", /\bmailto:/i, "mailto:beta@example.com"],
  ["server action", /["']use server["']/, '"use server"'],
  ["client beacon", /\bsendBeacon\b|\bXMLHttpRequest\b/, "navigator.sendBeacon(url)"]
];
for (const [label, pattern, sample] of waitlistOffers) {
  assert.match(sample, pattern, `${label} pattern must match its own sample`);
  assert.doesNotMatch(corpus, pattern, `D-16: public source must not offer a waitlist (${label})`);
}
assert.equal((corpus.match(/\bfetch\s*\(/g) ?? []).length, 1, "D-16: the shared-report read is the only request the site makes");
const routeHandlers = sourceFiles(join(sourceRoot, "app"))
  .filter((path) => /[/\\]route\.tsx?$/.test(path))
  .map((path) => relative(sourceRoot, path).split("\\").join("/"));
assert.deepEqual(routeHandlers, ["app/healthz/route.ts"], "D-16: only /healthz may handle requests; no sign-up endpoint");

// D-07: the first cohort gets the core plus the life counter; AI analysis is a
// second wave and never shows up in the first one. Public copy calls the
// first cohort's scope the first wave.
const capabilityBlocks = offerSource.match(/\{[^{}]*\bwave:\s*"[^"]+"[^{}]*\}/g) ?? [];
const firstWaveBlocks = capabilityBlocks.filter((block) => /wave:\s*"primeira-onda"/.test(block));
const secondWaveBlocks = capabilityBlocks.filter((block) => /wave:\s*"segunda-onda"/.test(block));
assert.ok(
  firstWaveBlocks.some((block) => /"Contador de vida"/.test(block)),
  "D-07: the life counter belongs to the first cohort"
);
assert.ok(
  firstWaveBlocks.every((block) => !/\bIA\b|sugest|otimiz/i.test(block)),
  "D-07: AI analysis must not be offered as part of the first cohort"
);
assert.ok(
  secondWaveBlocks.some((block) => /\bIA\b/.test(block)),
  "D-07: AI analysis must be presented as a second wave"
);
assert.match(landingCorpus, /segunda onda/i, "D-07: the site must say that AI comes in a second wave");

const serverSource = readFileSync(join(sourceRoot, "lib/public-server.ts"), "utf8");
assert.equal((serverSource.match(/\bfetch\s*\(/g) ?? []).length, 1, "only the shared-report fetch helper is allowed");
assert.match(serverSource, /`\/reports\/\$\{encodeURIComponent\(id\)\}`/);
assert.doesNotMatch(serverSource, /\/community\/|\/market\//);

console.log("free beta public offer contract: PASS");
