import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { Container, SectionHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Disclaimer",
  description: "Avisos sobre IA, preços, Commander Brackets e propriedade intelectual."
};

export default function DisclaimerPage() {
  return (
    <main className="py-16">
      <Container className="max-w-3xl">
        <BrandPageIntro eyebrow="IA e dados" title="Disclaimer">
          <p>Recomendações públicas ajudam na decisão, mas não substituem revisão de mesa, orçamento e disponibilidade.</p>
        </BrandPageIntro>
        <div className="mt-10">
          <SectionHeader eyebrow="Leitura responsável" title="IA, preços e propriedade intelectual." />
        </div>
        <div className="mt-10 grid gap-6 text-base leading-7 text-mist-300">
          <p>A IA pode sugerir trocas com base em dados, objetivo informado, orçamento e campos públicos. O usuário deve revisar contexto de mesa, regras atuais, disponibilidade e preço real antes de aplicar qualquer mudança.</p>
          <p>Preços exibidos são estimativas e podem variar por região, idioma, condição, edição e disponibilidade. Negociações devem ser confirmadas entre usuários antes de qualquer fechamento.</p>
          <p>Commander Brackets, formatos e nomes de cartas pertencem aos respectivos titulares quando aplicável. ManaLoom não é afiliado, endossado ou patrocinado por editoras ou marcas de terceiros.</p>
        </div>
      </Container>
    </main>
  );
}
