import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { ButtonLink, Container, Surface } from "@/components/ui";
import { routes } from "@/lib/routes";

export const metadata: Metadata = {
  title: "Publicações",
  description: "Atualizações e guias públicos do ManaLoom."
};

export default function BlogPage() {
  return (
    <main className="py-16">
      <Container>
        <BrandPageIntro eyebrow="Publicações" title="Guias e novidades chegam em breve.">
          <p>
            Enquanto a área editorial não abre, continue pelo app para montar decks, revisar listas e acompanhar sua coleção.
          </p>
        </BrandPageIntro>
        <Surface className="mt-12 p-6">
          <p className="text-sm leading-6 text-mist-300">
            Os próximos conteúdos devem cobrir upgrades de Commander, leitura de curva de mana e uso responsável da IA.
          </p>
          <div className="mt-6 flex flex-wrap gap-3">
            <ButtonLink href={routes.home}>Voltar ao início</ButtonLink>
            <ButtonLink href={routes.marketplace} variant="secondary">
              Ver mercado
            </ButtonLink>
          </div>
        </Surface>
      </Container>
    </main>
  );
}
