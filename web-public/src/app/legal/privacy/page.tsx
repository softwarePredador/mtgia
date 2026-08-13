import type { Metadata } from "next";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { Container, SectionHeader } from "@/components/ui";

export const metadata: Metadata = {
  title: "Privacidade",
  description: "Política pública de privacidade do BrewTact."
};

export default function PrivacyPage() {
  return (
    <main className="py-16">
      <Container className="max-w-3xl">
        <BrandPageIntro eyebrow="Privacidade BrewTact" title="Política de privacidade">
          <p>Como o BrewTact trata decks, coleções, relatórios e informações de conta.</p>
        </BrandPageIntro>
        <div className="mt-10">
          <SectionHeader eyebrow="Dados do usuário" title="Privado por padrão." />
        </div>
        <div className="mt-10 grid gap-6 text-base leading-7 text-mist-300">
          <p>Decks, coleções e informações de conta pertencem ao ambiente autenticado e não são publicados como diretório aberto.</p>
          <p>Um relatório pode receber um link de compartilhamento somente quando o usuário solicitar essa ação. O link deve expor apenas os dados necessários para exibir o relatório.</p>
          <p>Coleção, histórico de partidas, preferências de IA e informações de conta pertencem ao ambiente autenticado.</p>
          <p>Dados compartilhados e dados privados devem permanecer separados, com permissões aplicadas antes de qualquer acesso externo.</p>
        </div>
      </Container>
    </main>
  );
}
