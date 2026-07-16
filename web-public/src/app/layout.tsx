import type { Metadata } from "next";

import { SiteShell } from "@/components/site-shell";
import { absoluteUrl } from "@/lib/routes";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(absoluteUrl("/")),
  title: {
    default: "ManaLoom - Commander com IA explicável",
    template: "%s | ManaLoom"
  },
  description:
    "Construa, otimize e acompanhe decks de Commander com IA, relatórios compartilháveis e mercado de cartas.",
  icons: {
    icon: "/branding/app_logo.png",
    apple: "/branding/app_logo.png"
  },
  openGraph: {
    type: "website",
    siteName: "ManaLoom",
    title: "ManaLoom - Commander com IA explicável",
    description:
      "Deck builder, relatórios de otimização, coleção e mercado para Commander.",
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
