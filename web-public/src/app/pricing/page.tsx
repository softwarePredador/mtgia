import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { ButtonLink, Container } from "@/components/ui";
import { productPlans } from "@/lib/product-data";

export const metadata: Metadata = {
  title: "Planos",
  description: "Planos Free e Pro do ManaLoom para IA, decks e coleção."
};

function formatPlanValue(plan: (typeof productPlans)[number]) {
  return plan.id === "pro" ? new Intl.NumberFormat("pt-BR").format(plan.monthlyAiLimit) : plan.priceLabel;
}

function formatPlanCaption(plan: (typeof productPlans)[number]) {
  return plan.id === "pro" ? "ações de IA por mês" : `${plan.monthlyAiLimit} ações de IA por mês`;
}

export default function PricingPage() {
  return (
    <main className="py-16">
      <Container>
        <BrandPageIntro eyebrow="Planos" title="Comece grátis. Evolua quando a mesa pedir mais.">
          <p>
            Use o Free para testar a criação de decks e o Pro para revisar listas com mais frequência.
          </p>
        </BrandPageIntro>
        <div className="mt-12 grid gap-5 lg:grid-cols-2">
          {productPlans.map((plan) => (
            <section
              key={plan.id}
              className={`rounded-xl border p-6 ${plan.id === "pro" ? "border-brass-400 bg-brass-400/10 shadow-brass" : "border-mist-700 bg-obsidian-900/88"}`}
            >
              <div className="grid gap-4 sm:flex sm:items-start sm:justify-between">
                <div>
                  <h2 className="font-display text-3xl font-semibold">{plan.name}</h2>
                  <p className="mt-2 text-sm text-mist-300">{plan.description}</p>
                </div>
                <div className="sm:text-right">
                  <div className="text-3xl font-black leading-none text-ivory-100">{formatPlanValue(plan)}</div>
                  <div className="mt-1 max-w-28 text-xs text-mist-500 sm:ml-auto">{formatPlanCaption(plan)}</div>
                </div>
              </div>
              <ul className="mt-6 grid gap-3 text-sm text-mist-300">
                {plan.features.map((feature) => (
                  <li key={feature} className="flex gap-3">
                    <span className="mt-1 h-2 w-2 rounded-full bg-brass-400" />
                    <span>{feature}</span>
                  </li>
                ))}
              </ul>
              <div className="mt-6 border-t border-mist-700 pt-5">
                <p className="text-xs font-bold uppercase tracking-[0.18em] text-mist-500">Observações</p>
                <ul className="mt-3 grid gap-2 text-sm text-mist-400">
                  {plan.limits.map((limit) => (
                    <li key={limit}>{limit}</li>
                  ))}
                </ul>
              </div>
              <div className="mt-8">
                <ButtonLink href={plan.ctaHref} variant={plan.id === "pro" ? "primary" : "secondary"}>
                  {plan.ctaLabel}
                </ButtonLink>
              </div>
            </section>
          ))}
        </div>
      </Container>
    </main>
  );
}
