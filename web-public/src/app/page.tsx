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
        <Container className="relative flex min-h-[calc(100svh-11rem)] flex-col justify-center gap-7 py-8 sm:gap-10 sm:py-10">
          <div className="max-w-4xl">
            <div className="flex items-center gap-3">
              <Hub className="h-11 w-11">
                <Image
                  src="/branding/brewtact_mark.svg"
                  alt=""
                  width={26}
                  height={26}
                  priority
                  fetchPriority="high"
                  className="h-6 w-6"
                />
              </Hub>
              <p className="text-[11.5px] font-extrabold uppercase tracking-[0.085em] text-mist-300">
                Beta gratuita · acesso por convite
              </p>
            </div>
            <h1 className="mt-5 font-display text-[4rem] font-semibold leading-[0.9] tracking-[-0.02em] text-ivory-100 sm:text-[6.5rem] lg:text-[8rem]">
              BrewTact
            </h1>
            <p className="mt-3 font-display text-2xl font-semibold text-mist-300 sm:text-3xl">Monte melhor. Jogue melhor.</p>
            <p className="mt-4 max-w-2xl text-base leading-7 text-mist-300 sm:text-lg sm:leading-8">
              Deck builder de Commander, coleção privada, catálogo de cartas e contador de vida. A primeira onda entra por convite e sem cobrança; a análise com IA chega na segunda.
            </p>
            <div className="mt-5 flex flex-wrap gap-3 sm:mt-7">
              <AccessPending />
              <ButtonLink href={routes.pricing}>Conhecer a beta</ButtonLink>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2 sm:grid-cols-5">
            <Azulejo label="Decks" icon={<DeckIcon />} numeral="100" className="min-h-[96px] sm:min-h-[112px]" numeralClassName="text-[36px] sm:text-[44px]" />
            <Azulejo label="Coleção" icon={<CollectionIcon />} className="hidden min-h-[112px] sm:flex" />
            <Azulejo label="Catálogo" icon={<CatalogIcon />} className="hidden min-h-[112px] sm:flex" />
            <Azulejo
              label="Contador de vida"
              icon={<LifeIcon />}
              numeral="40"
              className="min-h-[96px] sm:min-h-[112px]"
              numeralClassName="text-[36px] sm:text-[44px]"
            />
            <Azulejo
              label="Análise com IA"
              icon={<AnalysisIcon className="h-[34px] w-[34px] text-mist-500" />}
              state={{ word: "Segunda onda", off: true }}
              className="col-span-2 min-h-[80px] sm:col-span-1 sm:min-h-[112px]"
            />
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
