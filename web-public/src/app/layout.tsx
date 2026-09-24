import type { Metadata } from "next";

import { SiteShell } from "@/components/site-shell";
import { absoluteUrl } from "@/lib/routes";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(absoluteUrl("/")),
  title: {
    default: "BrewTact - Decks, coleção e contador de vida para Commander",
    template: "%s | BrewTact"
  },
  description:
    "Beta gratuita e por convite: monte decks de Commander, organize sua coleção privada e acompanhe a mesa com o contador de vida.",
  icons: {
    icon: "/branding/app_logo.png",
    apple: "/branding/app_logo.png"
  },
  openGraph: {
    type: "website",
    siteName: "BrewTact",
    title: "BrewTact - Decks, coleção e contador de vida para Commander",
    description:
      "Deck builder, coleção privada e contador de vida para Commander. Beta gratuita, por convite.",
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
