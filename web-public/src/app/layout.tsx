import type { Metadata } from "next";

import { SiteShell } from "@/components/site-shell";
import { absoluteUrl } from "@/lib/routes";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(absoluteUrl("/")),
  title: {
    default: "BrewTact - Commander com IA explicável",
    template: "%s | BrewTact"
  },
  description:
    "Construa, organize e revise decks de Commander com IA explicável e relatórios compartilháveis.",
  icons: {
    icon: "/branding/app_logo.png",
    apple: "/branding/app_logo.png"
  },
  openGraph: {
    type: "website",
    siteName: "BrewTact",
    title: "BrewTact - Commander com IA explicável",
    description:
      "Deck builder, coleção privada e sugestões revisáveis para Commander.",
    url: absoluteUrl("/")
  }
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="pt-BR">
      <body>
        <SiteShell>{children}</SiteShell>
      </body>
    </html>
  );
}
