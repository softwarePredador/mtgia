import type { Metadata } from "next";
import Image from "next/image";

import { AccessPending, ButtonLink, Container, SectionHeader } from "@/components/ui";
import { freeBetaOffer, productCapabilities, waveLabels } from "@/lib/product-data";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  description: "Deck builder de Commander, coleção privada, catálogo e contador de vida. Beta gratuita, por convite."
};

const workflow = [
  {
    step: "01",
    title: "Monte a base",
    description: "Crie ou importe seu deck Commander e confira as 100 posições."
  },
  {
    step: "02",
    title: "Organize a coleção",
    description: "Registre as cartas que você já tem e consulte o catálogo quando precisar."
  },
  {
    step: "03",
    title: "Leve para a mesa",
    description: "Na partida, acompanhe a vida de cada jogador com o contador."
  }
] as const;

const firstWave = productCapabilities.filter((capability) => capability.wave === "primeira-onda");

export default function HomePage() {
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
              <Image
                src="/branding/app_logo.png"
                alt="BrewTact"
                fill
                sizes="(min-width: 640px) 96px, 64px"
                className="object-cover"
              />
            </div>
            <p className="text-xs font-bold uppercase tracking-[0.24em] text-brass-400 sm:text-sm">
              Beta gratuita · acesso por convite
            </p>
            <h1 className="mt-3 max-w-4xl break-words font-display text-[3.2rem] font-semibold leading-[0.98] text-ivory-100 sm:mt-4 sm:text-7xl sm:leading-[0.95]">
              BrewTact
            </h1>
            <p className="mt-4 max-w-2xl text-base leading-7 text-mist-300 sm:mt-5 sm:text-lg sm:leading-8">
              Deck builder de Commander, coleção privada, catálogo de cartas e contador de vida no mesmo lugar. A primeira onda entra por convite e sem cobrança; a análise com IA chega na segunda onda.
            </p>
            <div className="mt-6 flex flex-wrap gap-3 sm:mt-8">
              <AccessPending />
              <ButtonLink href={routes.pricing} variant="secondary">
                Conhecer a beta
              </ButtonLink>
            </div>
          </div>
        </Container>
      </section>

      <section id="produto" className="pb-20 pt-12 sm:py-20">
        <Container className="grid gap-12 lg:grid-cols-[0.68fr_1.32fr]">
          <SectionHeader eyebrow="Produto" title="O que entra na primeira onda.">
            <p>
              Decks, coleção e catálogo chegam junto com o contador de vida. A análise com IA fica para a segunda onda.
            </p>
          </SectionHeader>
          <div className="grid gap-x-8 md:grid-cols-2">
            {productCapabilities.map((capability) => (
              <article key={capability.title} className="border-t border-mist-700 py-6">
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">
                  {capability.surface} · {waveLabels[capability.wave]}
                </p>
                <h2 className="mt-3 font-display text-2xl font-semibold">{capability.title}</h2>
                <p className="mt-3 text-sm leading-6 text-mist-300">{capability.description}</p>
              </article>
            ))}
          </div>
        </Container>
      </section>

      <section className="border-y border-mist-700 bg-obsidian-900/72 py-20">
        <Container>
          <SectionHeader eyebrow="Como funciona" title="Do deck à mesa, no mesmo lugar.">
            <p>Quando a análise com IA chegar, na segunda onda, cada sugestão passa pela sua revisão antes de mudar o deck.</p>
          </SectionHeader>
          <ol className="mt-10 grid gap-x-8 lg:grid-cols-3">
            {workflow.map((item) => (
              <li key={item.step} className="border-t border-mist-700 py-6">
                <span className="text-xs font-bold tracking-[0.2em] text-brass-400">{item.step}</span>
                <h2 className="mt-4 font-display text-3xl font-semibold">{item.title}</h2>
                <p className="mt-3 text-sm leading-6 text-mist-300">{item.description}</p>
              </li>
            ))}
          </ol>
        </Container>
      </section>

      <section className="py-20">
        <Container className="grid gap-10 lg:grid-cols-[0.85fr_1.15fr] lg:items-start">
          <SectionHeader eyebrow={freeBetaOffer.status} title={freeBetaOffer.name}>
            <p>{freeBetaOffer.description}</p>
          </SectionHeader>
          <div className="border-l border-mist-700 pl-6 sm:pl-8">
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">
              O que entra na primeira onda
            </p>
            <ul className="mt-5 grid gap-3 text-sm leading-6 text-mist-300 sm:grid-cols-2 sm:gap-x-8">
              {firstWave.map((capability) => (
                <li key={capability.surface} className="border-t border-mist-700 pt-3">
                  {capability.surface}
                </li>
              ))}
            </ul>
            <p className="mt-6 max-w-2xl text-sm leading-6 text-mist-400">
              Os convites saem em lotes pequenos. A disponibilidade de cada recurso aparece no ambiente autenticado.
            </p>
            <div className="mt-7 flex flex-wrap gap-3">
              <AccessPending />
              <ButtonLink href={routes.pricing} variant="secondary">
                Ver detalhes da beta
              </ButtonLink>
            </div>
          </div>
        </Container>
      </section>
    </main>
  );
}
