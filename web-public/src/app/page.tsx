import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";

import { ManaCost } from "@/components/data-visuals";
import { ButtonLink, Container, RouteLink, SectionHeader, Stat } from "@/components/ui";
import { productCapabilities } from "@/lib/product-data";
import { loadPublicSiteFeed, type MarketplaceCardSummary } from "@/lib/public-server";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  title: "ManaLoom",
  description: "Commander, coleção, mercado e IA em uma experiência ManaLoom."
};

export const revalidate = 300;

function formatNumber(value: number | undefined) {
  return value === undefined ? "0" : new Intl.NumberFormat("pt-BR").format(value);
}

function formatMoney(value: number, currency?: string) {
  return new Intl.NumberFormat("pt-BR", {
    style: "currency",
    currency: currency || "BRL"
  }).format(value);
}

function formatPriceRange(item: MarketplaceCardSummary) {
  if (item.minPrice === undefined) {
    return "sem preço anunciado";
  }

  if (item.maxPrice !== undefined && item.maxPrice !== item.minPrice) {
    return `${formatMoney(item.minPrice, item.currency)} - ${formatMoney(item.maxPrice, item.currency)}`;
  }

  return formatMoney(item.minPrice, item.currency);
}

function formatCountLabel(count: number, singular: string, plural: string) {
  return `${count} ${count === 1 ? singular : plural}`;
}

function bypassImageOptimizer(imageUrl: string) {
  try {
    return new URL(imageUrl).hostname === "api.scryfall.com";
  } catch {
    return false;
  }
}

export default async function HomePage() {
  const siteFeed = await loadPublicSiteFeed();
  const marketplaceItems = siteFeed.marketplace.cards.slice(0, 3);
  const featuredDecks = siteFeed.publicDecks.items.slice(0, 2);

  return (
    <main>
      <section className="relative min-h-[calc(100svh-11rem)] overflow-hidden border-b border-mist-700">
        <Image
          src="/branding/home_hero_banner.png"
          alt=""
          fill
          priority
          fetchPriority="high"
          sizes="100vw"
          className="object-cover object-center opacity-90"
        />
        <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(11,13,18,0.99)_0%,rgba(11,13,18,0.9)_42%,rgba(11,13,18,0.52)_72%,rgba(11,13,18,0.88)_100%)]" />
        <div className="absolute inset-x-0 bottom-0 h-40 bg-gradient-to-t from-obsidian-950 to-transparent" />
        <Container className="relative flex min-h-[calc(100svh-11rem)] items-center py-8 sm:py-10">
          <div className="w-full max-w-[calc(100vw-2.5rem)] sm:max-w-3xl">
            <div className="relative mb-4 h-16 w-16 overflow-hidden rounded-[18px] border border-brass-400/28 bg-obsidian-950 shadow-brass sm:mb-6 sm:h-24 sm:w-24 sm:rounded-[26px]">
              <Image src="/branding/app_logo.png" alt="ManaLoom" fill sizes="(min-width: 640px) 96px, 80px" className="object-cover" />
            </div>
            <p className="text-xs font-bold uppercase tracking-[0.24em] text-brass-400 sm:text-sm">Commander, coleção e mercado</p>
            <h1 className="mt-3 max-w-4xl break-words font-display text-[3.2rem] font-semibold leading-[0.98] text-ivory-100 sm:mt-4 sm:text-7xl sm:leading-[0.95]">
              ManaLoom
            </h1>
            <p className="mt-4 max-w-2xl text-base leading-7 text-mist-300 sm:mt-5 sm:text-lg sm:leading-8">
              Construa decks, acompanhe sua coleção e encontre oportunidades de troca com cartas e preços reais.
            </p>
            <div className="mt-6 flex flex-wrap gap-3 sm:mt-8">
              <ButtonLink href={routes.app}>Abrir app</ButtonLink>
              <ButtonLink href={routes.marketplace} variant="secondary">
                Ver mercado
              </ButtonLink>
            </div>
            <div className="mt-7 grid max-w-3xl grid-cols-3 gap-2 sm:mt-10 sm:gap-4">
              <Stat label="Ofertas ativas" value={formatNumber(siteFeed.marketplace.cards.length)} />
              <Stat label="Decks completos" value={formatNumber(siteFeed.publicDecks.total)} />
              <Stat label="Preços monitorados" value={formatNumber(siteFeed.marketplace.movers.totalTracked)} />
            </div>
          </div>
        </Container>
      </section>

      <section id="produto" className="pb-20 pt-12 sm:py-20">
        <Container className="grid gap-12 lg:grid-cols-[0.68fr_1.32fr]">
          <SectionHeader eyebrow="Produto" title="Da primeira lista ao upgrade da mesa.">
            <p>
              ManaLoom organiza deck, coleção e mercado em um fluxo só para Commander.
            </p>
          </SectionHeader>
          <div className="grid gap-4 md:grid-cols-2">
            {productCapabilities.map((capability) => (
              <RouteLink
                key={capability.title}
                href={capability.href}
                className="focus-ring border-t border-mist-700 py-5 transition hover:border-brass-400"
              >
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">{capability.surface}</p>
                <h2 className="mt-3 font-display text-2xl font-semibold">{capability.title}</h2>
                <p className="mt-3 text-sm leading-6 text-mist-300">{capability.description}</p>
              </RouteLink>
            ))}
          </div>
        </Container>
      </section>

      <section className="border-y border-mist-700 bg-obsidian-900/72 py-20">
        <Container>
          <div className="flex flex-col justify-between gap-6 md:flex-row md:items-end">
            <SectionHeader eyebrow="Decks da comunidade" title="Listas completas para explorar.">
              <p>Decks publicados aparecem com comandante, formato e tamanho de lista.</p>
            </SectionHeader>
            <ButtonLink href={routes.app} variant="secondary">
              Criar meu deck
            </ButtonLink>
          </div>

          {featuredDecks.length > 0 ? (
            <div className="mt-10 grid gap-6 md:grid-cols-2">
              {featuredDecks.map((deck) => (
                <Link
                  key={deck.id}
                  href={routes.deck(deck.id)}
                  className="focus-ring group grid gap-5 border-t border-mist-700 pt-5 transition hover:border-brass-400 sm:grid-cols-[136px_1fr]"
                >
                  {deck.commanderImageUrl ? (
                    <div className="relative aspect-[5/7] w-32 overflow-hidden rounded-lg border border-mist-700 bg-obsidian-950 shadow-panel">
                      <Image
                        src={deck.commanderImageUrl}
                        alt={deck.commanderName ?? deck.name}
                        fill
                        sizes="128px"
                        loading="lazy"
                        unoptimized={bypassImageOptimizer(deck.commanderImageUrl)}
                        className="object-cover"
                      />
                    </div>
                  ) : null}
                  <div className="min-w-0">
                    <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">{deck.format ?? "Commander"}</p>
                    <h3 className="mt-2 font-display text-3xl font-semibold leading-tight group-hover:text-brass-300">
                      {deck.name}
                    </h3>
                    {deck.commanderName ? (
                      <p className="mt-3 text-sm leading-6 text-mist-300">Comandante: {deck.commanderName}</p>
                    ) : null}
                    <p className="mt-4 text-sm font-bold text-ivory-100">{formatCountLabel(deck.cardCount ?? 0, "carta", "cartas")}</p>
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <div className="mt-10 border-t border-mist-700 py-8 text-sm text-mist-300">
              Nenhum deck completo em destaque no momento.
            </div>
          )}
        </Container>
      </section>

      <section className="border-y border-mist-700 bg-obsidian-900/72 py-20">
        <Container>
          <div className="flex flex-col justify-between gap-6 md:flex-row md:items-end">
            <SectionHeader eyebrow="Mercado" title="Ofertas abertas quando a comunidade publica cartas.">
              <p>
                {siteFeed.marketplace.cards.length > 0
                  ? `${siteFeed.marketplace.cards.length} cartas com oferta ativa agora.`
                  : "Nenhuma oferta ativa agora. Os preços seguem monitorados para consulta no app."}
              </p>
            </SectionHeader>
            <ButtonLink href={routes.marketplace} variant="secondary">
              Abrir marketplace
            </ButtonLink>
          </div>

          {marketplaceItems.length > 0 ? (
            <div className="mt-10 grid gap-5 lg:grid-cols-3">
              {marketplaceItems.map((item) => (
                <Link
                  key={item.key}
                  href={routes.marketplace}
                  className="focus-ring group grid gap-4 border-t border-mist-700 pt-5 transition hover:border-brass-400"
                >
                  {item.imageUrl ? (
                    <div className="relative aspect-[5/7] w-28 overflow-hidden rounded-lg border border-mist-700 bg-obsidian-950 shadow-panel">
                      <Image
                        src={item.imageUrl}
                        alt={item.cardName}
                        fill
                        sizes="112px"
                        loading="lazy"
                        unoptimized={bypassImageOptimizer(item.imageUrl)}
                        className="object-cover"
                      />
                    </div>
                  ) : null}
                  <div>
                    <p className="text-xs font-bold uppercase tracking-[0.18em] text-mist-500">{item.setCode ?? "sem set"}</p>
                    <h3 className="mt-2 font-display text-2xl font-semibold group-hover:text-brass-300">{item.cardName}</h3>
                    <p className="mt-2 text-sm text-mist-300">{item.typeLine}</p>
                    <div className="mt-3">
                      <ManaCost cost={item.manaCost} />
                    </div>
                    <div className="mt-4 flex flex-wrap gap-2 text-xs font-semibold text-mist-300">
                      <span>{formatCountLabel(item.totalQuantity, "cópia", "cópias")}</span>
                      <span>{formatCountLabel(item.listingCount, "anúncio", "anúncios")}</span>
                      {item.forTrade ? <span>troca</span> : null}
                      {item.forSale ? <span>venda</span> : null}
                    </div>
                    <p className="mt-3 text-sm font-bold text-brass-300">{formatPriceRange(item)}</p>
                  </div>
                </Link>
              ))}
            </div>
          ) : (
            <div className="mt-10 border-t border-mist-700 py-8 text-sm text-mist-300">
              Volte mais tarde para ver cartas anunciadas por usuários ou abra o app para organizar seu fichário.
            </div>
          )}
        </Container>
      </section>

      <section className="py-20">
        <Container className="grid gap-10 lg:grid-cols-[1fr_0.8fr]">
          <SectionHeader title="Leve sua coleção para o app.">
            <p>
              Salve listas, use IA com revisão e acompanhe oportunidades com o contexto da sua coleção.
            </p>
          </SectionHeader>
          <div className="border-l border-mist-700 pl-5">
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-mist-500">Status</p>
            <p className="mt-2 text-lg font-bold text-ivory-100">{siteFeed.health?.status === "healthy" ? "App online" : "Verificar disponibilidade"}</p>
            <p className="mt-1 text-sm text-mist-300">
              Decks, coleção e mercado ficam no ambiente autenticado.
            </p>
            <div className="mt-6">
              <ButtonLink href={routes.app}>Abrir app</ButtonLink>
            </div>
          </div>
        </Container>
      </section>
    </main>
  );
}
