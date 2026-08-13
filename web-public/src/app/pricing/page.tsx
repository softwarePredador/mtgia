import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { AccessPending, ButtonLink, Container } from "@/components/ui";
import { freeBetaOffer } from "@/lib/product-data";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Beta gratuita",
  description: "Informações sobre a Beta gratuita e controlada do BrewTact."
};

export default function PricingPage() {
  return (
    <main className="py-16">
      <Container>
        <BrandPageIntro eyebrow={freeBetaOffer.status} title={freeBetaOffer.name}>
          <p>{freeBetaOffer.description}</p>
        </BrandPageIntro>

        <section className="mt-12 grid gap-10 border-y border-mist-700 py-10 lg:grid-cols-[0.75fr_1.25fr]">
          <div>
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">
              Uma única oferta
            </p>
            <h2 className="mt-3 font-display text-3xl font-semibold text-ivory-100">
              Sem cobrança durante a beta.
            </h2>
            <p className="mt-4 max-w-lg text-sm leading-6 text-mist-300">
              O acesso pode ser liberado em etapas para validar estabilidade, clareza e utilidade com segurança.
            </p>
          </div>

          <div>
            <p className="text-xs font-bold uppercase tracking-[0.18em] text-mist-500">
              Experiência principal
            </p>
            <ul className="mt-4 grid gap-x-8 text-sm leading-6 text-mist-300 sm:grid-cols-2">
              {freeBetaOffer.features.map((feature) => (
                <li key={feature} className="border-t border-mist-700 py-3">
                  {feature}
                </li>
              ))}
            </ul>
          </div>
        </section>

        <section className="mt-10 grid gap-8 lg:grid-cols-[0.75fr_1.25fr]">
          <h2 className="font-display text-2xl font-semibold text-ivory-100">Disponibilidade</h2>
          <div>
            <ul className="grid gap-3 text-sm leading-6 text-mist-400">
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
