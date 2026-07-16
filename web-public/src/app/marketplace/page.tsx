import type { Metadata } from "next";
import Image from "next/image";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { ManaCost } from "@/components/data-visuals";
import { ButtonLink, Container, Pill, Surface } from "@/components/ui";
import { loadMarketplaceFeed, type MarketplaceCardSummary } from "@/lib/public-server";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Marketplace",
  description:
    "Cartas disponíveis para compra e troca no ManaLoom."
};

export const revalidate = 300;

function formatMoney(value: number, currency?: string) {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: currency || "BRL"
  }).format(value);
}

function formatPriceRange(item: MarketplaceCardSummary) {
  if (item.minPrice === undefined) {
    return "Sem preço anunciado";
  }

  if (item.maxPrice !== undefined && item.maxPrice !== item.minPrice) {
    return `${formatMoney(item.minPrice, item.currency)} - ${formatMoney(item.maxPrice, item.currency)}`;
  }

  return formatMoney(item.minPrice, item.currency);
}

function formatUsd(value: number | undefined) {
  if (value === undefined) {
    return null;
  }

  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: "USD"
  }).format(value);
}

function formatDate(value: string | undefined) {
  if (!value) {
    return null;
  }

  const datePart = value.split("T")[0];
  const pieces = datePart.split("-");
  if (pieces.length === 3) {
    return `${pieces[2]}/${pieces[1]}/${pieces[0]}`;
  }

  return value;
}

function formatCountLabel(count: number, singular: string, plural: string) {
  return `${count} ${count === 1 ? singular : plural}`;
}

function trendLabel(item: MarketplaceCardSummary) {
  if (item.trendStatus !== "available") {
    return null;
  }

  const directionLabels: Record<string, string> = {
    up: "em alta",
    down: "em queda",
    flat: "estável"
  };
  const direction = item.trendDirection ? directionLabels[item.trendDirection] ?? item.trendDirection : "estável";
  const change =
    item.trendChangePct === undefined
      ? ""
      : ` ${new Intl.NumberFormat("pt-BR", { maximumFractionDigits: 1 }).format(item.trendChangePct)}%`;

  return `Histórico ${direction}${change}`;
}

function comparisonLabel(status: string | undefined) {
  switch (status) {
    case "alert_high":
      return "Preço acima da referência";
    case "alert_low":
      return "Preço abaixo da referência";
    case "within_range":
      return "Preço próximo da referência";
    default:
      return null;
  }
}

function CardSummaryMeta({ item }: { item: MarketplaceCardSummary }) {
  const extraConditions = Math.max(item.conditions.length - 2, 0);

  return (
    <div className="mt-3 flex flex-wrap gap-2">
      {item.setCode ? <Pill>{item.setCode}</Pill> : null}
      <Pill>{formatCountLabel(item.totalQuantity, "cópia", "cópias")}</Pill>
      <Pill>{formatCountLabel(item.listingCount, "anúncio", "anúncios")}</Pill>
      {item.conditions.slice(0, 2).map((condition) => (
        <Pill key={condition}>{condition}</Pill>
      ))}
      {extraConditions > 0 ? <Pill>+{extraConditions} condições</Pill> : null}
      {item.forTrade ? <Pill>troca</Pill> : null}
      {item.forSale ? <Pill>venda</Pill> : null}
    </div>
  );
}

export default async function MarketplacePage() {
  const marketplaceFeed = await loadMarketplaceFeed(100);

  return (
    <main className="py-16">
      <Container>
        <div className="flex flex-col justify-between gap-6 md:flex-row md:items-end">
          <BrandPageIntro eyebrow="Mercado" title="Cartas para compra e troca.">
            <p>
              Consulte ofertas ativas, referência de preço e disponibilidade antes de continuar a negociação no app.
            </p>
          </BrandPageIntro>
        </div>

        <div className="mt-12 grid gap-5 lg:grid-cols-[1.15fr_0.85fr]">
          <Surface className="overflow-hidden">
            <div className="border-b border-mist-700 p-5">
              <h2 className="text-lg font-bold">Ofertas disponíveis</h2>
              <p className="mt-1 text-xs leading-5 text-mist-500">{marketplaceFeed.sourceSummary}</p>
            </div>

            {marketplaceFeed.cards.length > 0 ? (
              <div className="divide-y divide-mist-700">
                {marketplaceFeed.cards.map((item) => {
                  const referencePrice = formatUsd(item.referencePriceUsd);
                  const latestDate = formatDate(item.latestPriceDate ?? marketplaceFeed.movers.date ?? undefined);
                  const trend = trendLabel(item);
                  const comparison = comparisonLabel(item.comparisonStatus);

                  return (
                    <article key={item.key} className="grid gap-4 p-5 sm:grid-cols-[112px_1fr]">
                      {item.imageUrl ? (
                        <div className="relative aspect-[5/7] w-28 overflow-hidden rounded-lg border border-mist-700 bg-obsidian-950 shadow-panel">
                          <Image
                            src={item.imageUrl}
                            alt={item.cardName}
                            fill
                            sizes="112px"
                            className="object-cover"
                          />
                        </div>
                      ) : (
                        <div className="grid aspect-[5/7] w-28 place-items-center rounded-lg border border-mist-700 bg-obsidian-950 text-xs text-mist-500">
                          sem imagem
                        </div>
                      )}
                      <div className="min-w-0">
                        <div className="flex flex-wrap items-start justify-between gap-3">
                          <div>
                            <h3 className="font-bold text-ivory-100">{item.cardName}</h3>
                            {item.typeLine ? <p className="mt-1 text-xs leading-5 text-mist-500">{item.typeLine}</p> : null}
                            <div className="mt-2">
                              <ManaCost cost={item.manaCost} />
                            </div>
                          </div>
                          <div className="rounded-lg border border-brass-700/45 bg-brass-400/10 px-3 py-2 text-right">
                            <div className="text-sm font-bold text-brass-300">{formatPriceRange(item)}</div>
                            {referencePrice ? (
                              <div className="text-[11px] text-mist-500">ref. {referencePrice}</div>
                            ) : null}
                          </div>
                        </div>
                        <CardSummaryMeta item={item} />
                        <div className="mt-4 grid gap-2 text-xs leading-5 text-mist-400 sm:grid-cols-2">
                          {trend ? <span>{trend}</span> : null}
                          {latestDate ? <span>Atualizado: {latestDate}</span> : null}
                          {comparison ? <span>{comparison}</span> : null}
                          <span>{item.forSale ? "Disponível para compra" : "Sem venda direta anunciada"}</span>
                        </div>
                      </div>
                    </article>
                  );
                })}
              </div>
            ) : (
              <div className="p-5 text-sm leading-6 text-mist-300">
                Nenhuma oferta ativa agora. Abra o app para organizar seu fichário, marcar cartas para troca e voltar quando a comunidade publicar novas ofertas.
              </div>
            )}
          </Surface>

          <div className="grid gap-5 self-start">
            <Surface className="p-5">
              <h2 className="text-lg font-bold">Resumo</h2>
              <div className="mt-5 grid gap-4 text-sm text-mist-300">
                <div className="border-t border-mist-700 pt-4">
                  <div className="text-2xl font-black text-ivory-100">{marketplaceFeed.cards.length}</div>
                  <div className="text-xs uppercase tracking-[0.14em] text-mist-500">ofertas ativas</div>
                </div>
                <div className="border-t border-mist-700 pt-4">
                  <div className="text-2xl font-black text-ivory-100">{marketplaceFeed.movers.totalTracked ?? 0}</div>
                  <div className="text-xs uppercase tracking-[0.14em] text-mist-500">preços monitorados</div>
                </div>
                <div className="border-t border-mist-700 pt-4">
                  <div className="font-bold text-ivory-100">
                    {marketplaceFeed.movers.hasMovers ? "Com variação de preço recente" : "Sem variação de preço recente"}
                  </div>
                  <p className="mt-1 leading-6">
                    Use a referência de mercado para decidir se vale comprar, vender ou propor troca.
                  </p>
                </div>
              </div>
            </Surface>

            <Surface className="p-5">
              <h2 className="text-lg font-bold">Continuar no app</h2>
              <p className="mt-3 text-sm leading-6 text-mist-300">
                Cadastre cartas, publique seu fichário e responda propostas com seu perfil ManaLoom.
              </p>
              <div className="mt-5">
                <ButtonLink href={routes.app} variant="secondary">
                  Abrir fichário
                </ButtonLink>
              </div>
            </Surface>
          </div>
        </div>
      </Container>
    </main>
  );
}
