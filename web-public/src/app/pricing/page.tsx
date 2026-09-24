import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { CapabilityWaves } from "@/components/product-waves";
import { FactTile } from "@/components/tiles";
import { AccessPending, ButtonLink, Container, SectionHeader } from "@/components/ui";
import { freeBetaOffer } from "@/lib/product-data";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Beta gratuita",
  description: "Informações sobre a Beta gratuita do BrewTact, com acesso por convite."
};

export default function PricingPage() {
  return (
    <main className="py-16">
      <Container>
        <BrandPageIntro eyebrow={freeBetaOffer.status} title={freeBetaOffer.name}>
          <p>{freeBetaOffer.description}</p>
        </BrandPageIntro>

        <section className="mt-16 grid gap-10 lg:grid-cols-[0.75fr_1.25fr]">
          <SectionHeader eyebrow="Uma única oferta" title="Sem cobrança durante a beta.">
            <p>A entrada é por convite, em lotes pequenos, para validar estabilidade, clareza e utilidade com segurança.</p>
          </SectionHeader>
          <div className="grid gap-2 sm:grid-cols-2">
            <FactTile label="Beta" value="Gratuita">
              Nenhum recurso da beta é cobrado.
            </FactTile>
            <FactTile label="Acesso" value="Por convite">
              O cadastro não está aberto nesta fase.
            </FactTile>
          </div>
        </section>

        <section className="mt-16 grid gap-10 lg:grid-cols-[0.75fr_1.25fr]">
          <SectionHeader eyebrow="Experiência principal" title="O núcleo e o contador de vida primeiro.">
            <p>A análise com IA chega na segunda onda.</p>
          </SectionHeader>
          <CapabilityWaves compact />
        </section>

        <section className="mt-16 grid gap-10 border-t border-ivory-100/10 pt-10 lg:grid-cols-[0.75fr_1.25fr]">
          <h2 className="font-display text-2xl font-semibold text-ivory-100">Disponibilidade</h2>
          <div>
            <ul className="grid gap-3 text-sm leading-6 text-mist-300">
              {freeBetaOffer.availability.map((item) => (
                <li key={item}>{item}</li>
              ))}
            </ul>
            <div className="mt-7 flex flex-wrap gap-3">
              <AccessPending />
              <ButtonLink href={routes.home} variant="secondary">
                Voltar ao início
              </ButtonLink>
            </div>
          </div>
        </section>
      </Container>
    </main>
  );
}
