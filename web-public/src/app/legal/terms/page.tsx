import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { Container, SectionHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Termos de uso",
  description: "Termos públicos de uso do BrewTact."
};

export default function TermsPage() {
  return (
    <main className="py-16">
      <Container className="max-w-3xl">
        <BrandPageIntro eyebrow="Legal BrewTact" title="Termos de uso">
          <p>Regras básicas para usar o BrewTact e os recursos liberados durante a beta.</p>
        </BrandPageIntro>
        <div className="mt-10">
          <SectionHeader eyebrow="Uso do produto" title="Responsabilidades e limites." />
        </div>
        <div className="mt-10 grid gap-6 text-base leading-7 text-mist-300">
          <p>O BrewTact oferece ferramentas para criar, organizar, compartilhar relatórios autorizados e analisar decks. O usuário é responsável pelo conteúdo que registra e pelas decisões tomadas a partir das recomendações exibidas.</p>
          <p>A beta é gratuita e tem acesso controlado. A disponibilidade de recursos e os limites operacionais podem depender da conta e das políticas vigentes no app.</p>
          <p>Decks e coleções permanecem privados. Um relatório só pode ser acessado fora do ambiente autenticado quando o usuário solicitar seu compartilhamento.</p>
        </div>
      </Container>
    </main>
  );
}
