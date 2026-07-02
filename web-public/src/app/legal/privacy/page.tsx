import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { Container, SectionHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Privacidade",
  description: "Política pública de privacidade do ManaLoom."
};

export default function PrivacyPage() {
  return (
    <main className="py-16">
      <Container className="max-w-3xl">
        <BrandPageIntro eyebrow="Privacidade ManaLoom" title="Política de privacidade">
          <p>Como ManaLoom trata decks, perfis, relatórios e sinais de troca compartilhados pelo usuário.</p>
        </BrandPageIntro>
        <div className="mt-10">
          <SectionHeader eyebrow="Dados públicos" title="Compartilhamento com opt-in." />
        </div>
        <div className="mt-10 grid gap-6 text-base leading-7 text-mist-300">
          <p>Decks, relatórios, perfis e sinais de trade só devem aparecer publicamente quando marcados como públicos ou autorizados pelo usuário.</p>
          <p>Coleção, histórico de partidas, preferências de IA e informações de conta pertencem ao ambiente autenticado.</p>
          <p>Dados públicos e dados privados devem permanecer separados, com permissões aplicadas antes de qualquer compartilhamento.</p>
        </div>
      </Container>
    </main>
  );
}
