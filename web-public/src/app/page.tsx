import type { Metadata } from "next";
import Image from "next/image";

import { AccessPending, ButtonLink, Container, SectionHeader } from "@/components/ui";
import { freeBetaOffer, productCapabilities } from "@/lib/product-data";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  title: "BrewTact",
  description: "Decks, coleção e sugestões revisáveis em uma experiência BrewTact."
};

const workflow = [
  {
    step: "01",
    title: "Monte a base",
    description: "Crie ou importe seu deck e organize as cartas que já fazem parte da sua coleção."
  },
  {
    step: "02",
    title: "Leia o plano",
    description: "Confira a composição da lista e use o contexto do deck para orientar a análise."
  },
  {
    step: "03",
    title: "Decida antes de aplicar",
    description: "Revise cada sugestão da IA e mantenha o controle sobre a versão final do deck."
  }
] as const;

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
              Beta gratuita em preparação
            </p>
            <h1 className="mt-3 max-w-4xl break-words font-display text-[3.2rem] font-semibold leading-[0.98] text-ivory-100 sm:mt-4 sm:text-7xl sm:leading-[0.95]">
              BrewTact
            </h1>
            <p className="mt-4 max-w-2xl text-base leading-7 text-mist-300 sm:mt-5 sm:text-lg sm:leading-8">
              Monte decks, organize sua coleção e, quando o recurso estiver habilitado, revise sugestões de IA antes de decidir.
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
          <SectionHeader eyebrow="Produto" title="Um fluxo claro para cuidar do seu deck.">
            <p>
              O BrewTact reúne o núcleo da experiência Commander em um ambiente autenticado e privado.
            </p>
          </SectionHeader>
          <div className="grid gap-x-8 md:grid-cols-2">
            {productCapabilities.map((capability) => (
              <article key={capability.title} className="border-t border-mist-700 py-6">
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">
                  {capability.surface}
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
          <SectionHeader eyebrow="Como funciona" title="Da lista à decisão, sem pular a revisão.">
            <p>Com a análise habilitada, a tecnologia ajuda a organizar o raciocínio; a escolha continua sendo sua.</p>
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
              O que está no núcleo
            </p>
            <ul className="mt-5 grid gap-3 text-sm leading-6 text-mist-300 sm:grid-cols-2 sm:gap-x-8">
              {freeBetaOffer.features.slice(0, 3).map((feature) => (
                <li key={feature} className="border-t border-mist-700 pt-3">
                  {feature}
                </li>
              ))}
            </ul>
            <p className="mt-6 max-w-2xl text-sm leading-6 text-mist-400">
              A liberação acontece em etapas. A disponibilidade de cada recurso aparece no ambiente autenticado.
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
