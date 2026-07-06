import type { Metadata } from "next";
import { notFound } from "next/navigation";

import { ButtonLink, Container, Pill, Stat, Surface } from "@/components/ui";
import { loadPublicReport } from "@/lib/public-server";
import { absoluteUrl, routes } from "@/lib/routes";

type PageProps = {
  params: Promise<{ id: string }>;
};

export const revalidate = 300;

export function generateStaticParams() {
  return [];
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const report = await loadPublicReport(id);
  if (!report) return {};

  return {
    title: report.title,
    description: report.description ?? "Relatorio compartilhavel ManaLoom.",
    openGraph: {
      type: "article",
      title: report.title,
      description: report.description ?? "Relatorio compartilhavel ManaLoom.",
      url: absoluteUrl(routes.report(report.id))
    }
  };
}

function asRecord(value: unknown): Record<string, unknown> {
  return value && typeof value === "object" && !Array.isArray(value) ? (value as Record<string, unknown>) : {};
}

function asRecordList(value: unknown): Array<Record<string, unknown>> {
  return Array.isArray(value) ? value.map(asRecord).filter((item) => Object.keys(item).length > 0) : [];
}

function text(value: unknown, fallback = "-") {
  const resolved = value === null || value === undefined ? "" : String(value).trim();
  return resolved.length > 0 ? resolved : fallback;
}

function numberText(value: unknown, fallback = "-") {
  if (typeof value === "number" && Number.isFinite(value)) return String(value);
  if (typeof value === "string" && value.trim().length > 0) return value;
  return fallback;
}

function firstMetric(record: Record<string, unknown>, keys: string[]) {
  for (const key of keys) {
    const value = record[key];
    if (value !== null && value !== undefined && String(value).trim().length > 0) {
      return String(value);
    }
  }
  return "-";
}

function cardName(item: Record<string, unknown>) {
  return text(item.name ?? item.card_name ?? item.addCard ?? item.removeCard);
}

export default async function PublicReportPage({ params }: PageProps) {
  const { id } = await params;
  const report = await loadPublicReport(id);
  if (!report) notFound();

  const payload = report.payload;
  const deck = asRecord(payload.deck);
  const stats = asRecord(payload.stats);
  const commander = asRecord(payload.commander);
  const before = asRecord(payload.before);
  const after = asRecord(payload.after);
  const removals = asRecordList(payload.removals);
  const additions = asRecordList(payload.additions);
  const cards = asRecordList(payload.cards).slice(0, 30);
  const isOptimization = payload.type === "optimization_preview";

  return (
    <main className="py-16">
      <Container>
        <div className="mb-10 max-w-4xl">
          <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">Relatorio compartilhavel</p>
          <h1 className="mt-4 break-words font-display text-4xl font-semibold leading-tight text-ivory-100 sm:text-5xl">
            {report.title}
          </h1>
          {report.description ? <p className="mt-4 max-w-3xl text-base leading-7 text-mist-300">{report.description}</p> : null}
          <div className="mt-6 flex flex-wrap gap-2">
            {isOptimization ? <Pill>Antes/depois</Pill> : <Pill>Snapshot de deck</Pill>}
            {report.deckId ? <Pill>Deck {report.deckId.slice(0, 8)}</Pill> : null}
            {report.updatedAt ? <Pill>Atualizado {new Date(report.updatedAt).toLocaleDateString("pt-BR")}</Pill> : null}
          </div>
        </div>

        <div className="grid gap-10 lg:grid-cols-[0.76fr_1.24fr]">
          <aside className="lg:sticky lg:top-8 lg:self-start">
            <div className="border-l-2 border-brass-500 pl-5">
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">Resumo</p>
              <h2 className="mt-2 font-display text-3xl font-semibold">
                {text(payload.deck_name ?? deck.name, "Deck ManaLoom")}
              </h2>
              <p className="mt-3 text-sm leading-6 text-mist-300">
                {isOptimization
                  ? "Relatorio gerado no preview de otimizacao para revisar motivo, risco e impacto antes de aplicar."
                  : "Snapshot publico gerado a partir dos dados reais do deck."}
              </p>
              <div className="mt-7">
                <ButtonLink href={routes.app}>Abrir ManaLoom</ButtonLink>
              </div>
            </div>
          </aside>

          <section className="grid gap-5">
            <Surface className="p-5">
              <div className="grid gap-5 sm:grid-cols-3">
                <Stat label="Plano" value={text(payload.plan_label ?? payload.archetype ?? deck.archetype, "Deck")} />
                <Stat label="Mudancas" value={numberText(payload.selected_change_count ?? stats.unique_cards)} />
                <Stat label="Cartas" value={numberText(stats.total_cards ?? stats.unique_cards)} />
              </div>
            </Surface>

            {isOptimization ? (
              <Surface className="p-5">
                <h2 className="text-lg font-bold">Antes/depois</h2>
                <div className="mt-5 grid gap-4 md:grid-cols-2">
                  <div className="rounded-lg border border-mist-700 bg-obsidian-950/58 p-4">
                    <p className="text-xs font-bold uppercase tracking-[0.14em] text-mist-500">Antes</p>
                    <dl className="mt-3 grid gap-2 text-sm text-mist-300">
                      <div className="flex justify-between gap-4"><dt>CMC medio</dt><dd className="font-bold text-ivory-100">{firstMetric(before, ["average_cmc", "avg_cmc"])}</dd></div>
                      <div className="flex justify-between gap-4"><dt>Cartas</dt><dd className="font-bold text-ivory-100">{firstMetric(before, ["total_cards", "card_count"])}</dd></div>
                      <div className="flex justify-between gap-4"><dt>Terrenos</dt><dd className="font-bold text-ivory-100">{firstMetric(before, ["lands", "land_count"])}</dd></div>
                    </dl>
                  </div>
                  <div className="rounded-lg border border-brass-500/60 bg-brass-400/10 p-4">
                    <p className="text-xs font-bold uppercase tracking-[0.14em] text-brass-400">Depois</p>
                    <dl className="mt-3 grid gap-2 text-sm text-mist-300">
                      <div className="flex justify-between gap-4"><dt>CMC medio</dt><dd className="font-bold text-ivory-100">{firstMetric(after, ["average_cmc", "avg_cmc"])}</dd></div>
                      <div className="flex justify-between gap-4"><dt>Cartas</dt><dd className="font-bold text-ivory-100">{firstMetric(after, ["total_cards", "card_count"])}</dd></div>
                      <div className="flex justify-between gap-4"><dt>Terrenos</dt><dd className="font-bold text-ivory-100">{firstMetric(after, ["lands", "land_count"])}</dd></div>
                    </dl>
                  </div>
                </div>
                {payload.reasoning ? <p className="mt-5 text-sm leading-6 text-mist-300">{text(payload.reasoning)}</p> : null}
              </Surface>
            ) : null}

            {removals.length + additions.length > 0 ? (
              <Surface className="overflow-hidden">
                <div className="border-b border-mist-700 p-5">
                  <h2 className="text-lg font-bold">Trocas sugeridas</h2>
                </div>
                <div className="grid gap-0 divide-y divide-mist-700 md:grid-cols-2 md:divide-x md:divide-y-0">
                  <div className="divide-y divide-mist-700">
                    <div className="p-4 text-sm font-bold text-mist-300">Remover</div>
                    {removals.slice(0, 20).map((item, index) => (
                      <div key={`remove-${index}`} className="p-4 text-sm text-ivory-100">{cardName(item)}</div>
                    ))}
                  </div>
                  <div className="divide-y divide-mist-700">
                    <div className="p-4 text-sm font-bold text-mist-300">Adicionar</div>
                    {additions.slice(0, 20).map((item, index) => (
                      <div key={`add-${index}`} className="p-4 text-sm text-ivory-100">{cardName(item)}</div>
                    ))}
                  </div>
                </div>
              </Surface>
            ) : null}

            {cards.length > 0 ? (
              <Surface className="overflow-hidden">
                <div className="border-b border-mist-700 p-5">
                  <h2 className="text-lg font-bold">Cartas no snapshot</h2>
                  {commander.name ? <p className="mt-1 text-sm text-mist-300">Comandante: {text(commander.name)}</p> : null}
                </div>
                <div className="divide-y divide-mist-700">
                  {cards.map((card, index) => (
                    <article key={`${text(card.id, String(index))}-${index}`} className="grid gap-2 p-5 md:grid-cols-[1fr_auto]">
                      <div>
                        <div className="font-semibold text-ivory-100">
                          {numberText(card.quantity, "1")}x {cardName(card)}
                        </div>
                        {card.type_line ? <div className="mt-1 text-sm text-mist-300">{text(card.type_line)}</div> : null}
                      </div>
                      {card.mana_cost ? <div className="text-sm font-semibold text-mist-300">{text(card.mana_cost)}</div> : null}
                    </article>
                  ))}
                </div>
              </Surface>
            ) : null}
          </section>
        </div>
      </Container>
    </main>
  );
}
