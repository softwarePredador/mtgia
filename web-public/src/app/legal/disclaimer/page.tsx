import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { Container, SectionHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Disclaimer",
  description: "Avisos sobre IA, regras de Commander e propriedade intelectual."
};

export default function DisclaimerPage() {
  return (
    <main className="py-16">
      <Container className="max-w-3xl">
        <BrandPageIntro eyebrow="IA e dados" title="Disclaimer">
          <p>Recomendações ajudam na decisão, mas não substituem a revisão do usuário e o acordo da mesa.</p>
        </BrandPageIntro>
        <div className="mt-10">
          <SectionHeader eyebrow="Leitura responsável" title="IA, regras e propriedade intelectual." />
        </div>
        <div className="mt-10 grid gap-6 text-base leading-7 text-mist-300">
          <p>A IA pode sugerir alterações com base nos dados da lista e no objetivo informado. O usuário deve revisar o contexto da mesa, as regras atuais e a disponibilidade das cartas antes de aplicar qualquer mudança.</p>
          <p>Resultados gerados podem conter imprecisões. O BrewTact apresenta a recomendação para revisão e não aplica mudanças sem uma ação do usuário.</p>
          <p>Commander Brackets, formatos e nomes de cartas pertencem aos respectivos titulares quando aplicável. BrewTact não é afiliado, endossado ou patrocinado por editoras ou marcas de terceiros.</p>
        </div>
      </Container>
    </main>
  );
}
