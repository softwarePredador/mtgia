import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { Container, SectionHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Termos de uso",
  description: "Termos públicos de uso do ManaLoom."
};

export default function TermsPage() {
  return (
    <main className="py-16">
      <Container className="max-w-3xl">
        <BrandPageIntro eyebrow="Legal ManaLoom" title="Termos de uso">
          <p>Regras básicas para usar ManaLoom, publicar conteúdo e contratar recursos do app.</p>
        </BrandPageIntro>
        <div className="mt-10">
          <SectionHeader eyebrow="Uso do produto" title="Responsabilidades e limites." />
        </div>
        <div className="mt-10 grid gap-6 text-base leading-7 text-mist-300">
          <p>O ManaLoom oferece ferramentas para criar, organizar, compartilhar e analisar decks. O usuário é responsável pelo conteúdo que publica e pelas decisões tomadas a partir das recomendações exibidas.</p>
          <p>O acesso a recursos Free ou Pro pode depender de conta, plano ativo, limites de uso e políticas vigentes no app.</p>
          <p>Conteúdo público pode ser indexado por mecanismos de busca quando o usuário habilitar compartilhamento. Dados privados não devem ser publicados sem autorização explícita.</p>
        </div>
      </Container>
    </main>
  );
}
