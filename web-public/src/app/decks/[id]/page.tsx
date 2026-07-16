import type { Metadata } from "next";
import Image from "next/image";
import { notFound } from "next/navigation";

import { ManaCost, ManaCurve, ManaPips } from "@/components/data-visuals";
import { ButtonLink, Container, Pill, Surface } from "@/components/ui";
import { loadPublicDeckDetail } from "@/lib/public-server";
import { absoluteUrl, routes } from "@/lib/routes";
import type { ManaColor, ManaCurvePoint } from "@/lib/types";

type PageProps = {
  params: Promise<{ id: string }>;
};

export const revalidate = 300;

export function generateStaticParams() {
  return [];
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const deck = await loadPublicDeckDetail(id);
  if (!deck) return {};

  return {
    title: `${deck.name} - deck público`,
    description: deck.description ?? `Deck público ${deck.name} no ManaLoom.`,
    openGraph: {
      type: "article",
      title: deck.name,
      description: deck.description ?? `Deck público ${deck.name} no ManaLoom.`,
      url: absoluteUrl(routes.deck(deck.id))
    }
  };
}

function curvePoints(curve?: Record<string, number>): ManaCurvePoint[] {
  const order = ["0", "1", "2", "3", "4", "5", "6", "7+"];
  return order.map((label) => ({ label, value: curve?.[label] ?? 0 }));
}

function deckColors(distribution?: Record<string, number>): ManaColor[] {
  const colors: ManaColor[] = ["W", "U", "B", "R", "G", "C"];
  return colors.filter((color) => (distribution?.[color] ?? 0) > 0);
}

export default async function PublicDeckPage({ params }: PageProps) {
  const { id } = await params;
  const deck = await loadPublicDeckDetail(id);
  if (!deck) notFound();

  const commander = deck.commander?.[0];
  const visibleCards = deck.allCards?.slice(0, 24) ?? [];

  return (
    <main className="py-16">
      <Container>
        <Surface className="relative mb-10 overflow-hidden p-0">
          <div className="relative min-h-[360px]">
            {commander?.imageUrl ? (
              <Image
                src={commander.imageUrl}
                alt=""
                fill
                priority
                fetchPriority="high"
                sizes="(min-width: 1024px) 1152px, 100vw"
                className="object-cover object-center opacity-45"
              />
            ) : (
              <Image
                src="/branding/home_hero_banner.png"
                alt=""
                fill
                priority
                sizes="(min-width: 1024px) 1152px, 100vw"
                className="object-cover object-center opacity-60"
              />
            )}
            <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(11,13,18,0.98)_0%,rgba(11,13,18,0.9)_48%,rgba(11,13,18,0.58)_100%)]" />
            <div className="relative flex min-h-[360px] items-end p-5 sm:p-8">
              <div className="max-w-3xl">
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">Deck da comunidade</p>
                <h1 className="mt-4 break-words font-display text-4xl font-semibold leading-tight text-ivory-100 sm:text-5xl">
                  {deck.name}
                </h1>
                {commander ? <p className="mt-3 text-lg text-mist-300">Comandante: {commander.name}</p> : null}
                {deck.description ? <p className="mt-4 max-w-2xl text-base leading-7 text-mist-300">{deck.description}</p> : null}
                <div className="mt-6 flex flex-wrap gap-2">
                  {deck.format ? <Pill>{deck.format}</Pill> : null}
                  {deck.ownerUsername ? <Pill>{deck.ownerUsername}</Pill> : null}
                  {deck.stats?.total_cards !== undefined ? <Pill>{deck.stats.total_cards} cartas</Pill> : null}
                  <ManaPips colors={deckColors(deck.stats?.color_distribution)} />
                </div>
              </div>
            </div>
          </div>
        </Surface>

        <div className="grid gap-10 lg:grid-cols-[0.72fr_1.28fr]">
          <div className="lg:sticky lg:top-8 lg:self-start">
            <div className="border-l-2 border-brass-500 pl-5">
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">Resumo</p>
              <h2 className="mt-2 font-display text-3xl font-semibold">Lista pronta para mesa</h2>
              <p className="mt-3 text-sm leading-6 text-mist-300">
                Veja comandante, curva de mana e as primeiras cartas da lista antes de abrir o deck no app.
              </p>
              <div className="mt-7">
                <ButtonLink href={routes.app}>Abrir no app</ButtonLink>
              </div>
            </div>
          </div>

          <div className="grid gap-5">
            <Surface className="p-5">
              <h2 className="mb-4 text-lg font-bold">Curva de mana</h2>
              <ManaCurve points={curvePoints(deck.stats?.mana_curve)} />
            </Surface>

            <Surface className="overflow-hidden">
              <div className="border-b border-mist-700 p-5">
                <h2 className="text-lg font-bold">Cartas do deck</h2>
              </div>
              <div className="divide-y divide-mist-700">
                {visibleCards.map((card) => (
                  <article key={`${card.id}-${card.isCommander ? "commander" : "main"}`} className="grid gap-3 p-5 md:grid-cols-[1fr_auto]">
                    <div>
                      <div className="font-semibold text-ivory-100">
                        {card.quantity}x {card.name}
                      </div>
                      {card.typeLine ? <div className="mt-1 text-sm text-mist-300">{card.typeLine}</div> : null}
                    </div>
                    <div className="flex items-start gap-2 md:justify-end">
                      <ManaCost cost={card.manaCost} />
                    </div>
                  </article>
                ))}
              </div>
            </Surface>
          </div>
        </div>
      </Container>
    </main>
  );
}
