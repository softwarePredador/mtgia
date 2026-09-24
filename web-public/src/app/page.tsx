import type { Metadata } from "next";
import Image from "next/image";

import { CapabilityWaves } from "@/components/product-waves";
import {
  AnalysisIcon,
  Azulejo,
  CatalogIcon,
  CollectionIcon,
  DeckIcon,
  FactTile,
  HeroTile,
  Hub,
  LifeIcon,
  Numeral
} from "@/components/tiles";
import { AccessPending, ButtonLink, Container, SectionHeader } from "@/components/ui";
import { freeBetaOffer } from "@/lib/product-data";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  description: "Deck builder de Commander, coleção privada, catálogo e contador de vida. Beta gratuita, por convite."
};

const workflow = [
  {
    step: "1",
    title: "Monte a base",
    description: "Crie ou importe seu deck Commander e confira as 100 posições."
  },
  {
    step: "2",
    title: "Organize a coleção",
    description: "Registre as cartas que você já tem e consulte o catálogo quando precisar."
  },
  {
    step: "3",
    title: "Leve para a mesa",
    description: "Na partida, acompanhe a vida de cada jogador com o contador."
  }
] as const;

export default function HomePage() {
  return (
    <main>
      <section className="relative min-h-[calc(100svh-11rem)] overflow-hidden border-b border-ivory-100/10">
        <Container className="relative flex min-h-[calc(100svh-11rem)] items-center py-8 sm:py-10">
          <div className="grid w-full items-center gap-6 lg:grid-cols-[minmax(0,0.85fr)_minmax(0,1.15fr)] lg:gap-12">
            <div className="min-w-0">
              <p className="text-[11.5px] font-extrabold uppercase tracking-[0.085em] text-mist-300">
                Beta gratuita · acesso por convite
              </p>
              <h1 className="mt-4 text-balance font-display text-[2.6rem] font-semibold leading-[0.98] text-ivory-100 sm:text-6xl lg:text-[3.6rem] xl:text-[3.75rem]">
                Monte melhor. Jogue melhor.
              </h1>
              <p className="mt-5 max-w-xl text-base leading-7 text-mist-300 sm:text-lg sm:leading-8">
                Deck builder de Commander, coleção privada, catálogo de cartas e contador de vida. A primeira onda entra por convite e sem cobrança; a análise com IA chega na segunda.
              </p>
              <div className="mt-5 flex flex-wrap gap-3 sm:mt-8">
                <AccessPending />
              </div>
            </div>

            <div className="grid w-full min-w-0 gap-2 lg:max-w-[660px] lg:justify-self-end">
              <div className="hidden gap-2 sm:grid sm:grid-cols-3">
                <Azulejo label="Decks" icon={<DeckIcon />} numeral="100" className="min-h-[124px]" />
                <Azulejo label="Coleção" icon={<CollectionIcon />} className="min-h-[124px]" />
                <Azulejo label="Catálogo" icon={<CatalogIcon />} className="min-h-[124px]" />
              </div>
              <div className="grid grid-cols-[minmax(0,1fr)_64px_minmax(0,1fr)] sm:grid-cols-[minmax(0,1.3fr)_80px_minmax(0,1fr)]">
                <Azulejo
                  label="Decks"
                  icon={<DeckIcon />}
                  numeral="100"
                  className="min-h-[100px] sm:hidden"
                  numeralClassName="text-[40px]"
                />
                <HeroTile
                  href={routes.pricing}
                  label="Beta gratuita"
                  title="Por convite"
                  accessibleName="Beta gratuita por convite: conhecer a beta"
                  className="hidden min-h-[136px] sm:flex"
                />
                <div className="grid place-items-center">
                  <Hub className="h-12 w-12 sm:h-14 sm:w-14">
                    <Image
                      src="/branding/brewtact_mark.svg"
                      alt="BrewTact"
                      width={30}
                      height={30}
                      priority
                      fetchPriority="high"
                      className="h-7 w-7 sm:h-8 sm:w-8"
                    />
                  </Hub>
                </div>
                <Azulejo
                  label="Contador de vida"
                  icon={<LifeIcon />}
                  numeral="40"
                  className="min-h-[100px] sm:min-h-[136px]"
                  numeralClassName="text-[40px] sm:text-[56px]"
                />
              </div>
              <HeroTile
                href={routes.pricing}
                label="Beta gratuita"
                title="Por convite"
                accessibleName="Beta gratuita por convite: conhecer a beta"
                className="min-h-[76px] sm:hidden"
              />
              <Azulejo
                label="Análise com IA"
                icon={<AnalysisIcon className="h-[34px] w-[34px] text-mist-500" />}
                state={{ word: "Segunda onda", off: true }}
                className="min-h-[72px] sm:min-h-[104px]"
              />
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
          <CapabilityWaves />
        </Container>
      </section>

      <section className="border-y border-ivory-100/10 bg-obsidian-900/60 py-20">
        <Container>
          <SectionHeader eyebrow="Como funciona" title="Do deck à mesa, no mesmo lugar.">
            <p>Quando a análise com IA chegar, na segunda onda, cada sugestão passa pela sua revisão antes de mudar o deck.</p>
          </SectionHeader>
          <ol className="mt-10 grid gap-2 lg:grid-cols-3">
            {workflow.map((item) => (
              <li key={item.step} className="flex min-w-0 items-start gap-5 rounded-azulejo bg-azulejo p-5 shadow-azulejo">
                <Numeral value={item.step} className="w-11 shrink-0 text-center text-[64px] text-ivory-100" />
                <div className="min-w-0 pt-1">
                  <h3 className="font-display text-2xl font-semibold leading-tight text-ivory-100">{item.title}</h3>
                  <p className="mt-2 text-sm leading-6 text-mist-300">{item.description}</p>
                </div>
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
          <div>
            <div className="grid gap-2 sm:grid-cols-2">
              <FactTile label="Beta" value="Gratuita">
                Sem cobrança durante a beta.
              </FactTile>
              <FactTile label="Acesso" value="Por convite">
                Os convites saem em lotes pequenos. A disponibilidade de cada recurso aparece no ambiente autenticado.
              </FactTile>
            </div>
            <div className="mt-6 flex flex-wrap gap-3">
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
