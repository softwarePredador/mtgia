import Link from "next/link";
import Image from "next/image";
import type { ReactNode } from "react";

import { routes } from "@/lib/routes";
import { Container, RouteLink } from "./ui";

const navItems = [
  { href: `${routes.home}#produto`, label: "Produto" },
  { href: routes.marketplace, label: "Mercado" },
  { href: routes.pricing, label: "Planos" },
  { href: routes.disclaimer, label: "IA e dados" }
];

export function SiteShell({ children }: { children: ReactNode }) {
  return (
    <div className="min-h-screen overflow-x-hidden bg-obsidian-950 text-ivory-100">
      <header className="relative z-20 border-b border-brass-700/25 bg-obsidian-950/92 backdrop-blur">
        <Container className="flex h-16 min-w-0 items-center gap-3">
          <Link href={routes.home} className="focus-ring mr-auto flex min-w-0 items-center gap-3 rounded-lg">
            <span className="relative h-10 w-10 shrink-0 overflow-hidden rounded-xl border border-brass-400/35 bg-obsidian-900 shadow-brass">
              <Image src="/branding/app_logo.png" alt="" fill sizes="40px" className="object-cover" />
            </span>
            <span className="min-w-0">
              <span className="block truncate font-display text-lg font-semibold leading-none text-ivory-100 sm:text-xl">
                ManaLoom
              </span>
              <span className="hidden text-[10px] font-semibold uppercase tracking-[0.18em] text-brass-400 sm:block">
                Tecendo estratégias
              </span>
            </span>
          </Link>
          <nav className="hidden items-center gap-6 text-sm text-mist-300 md:flex">
            {navItems.map((item) => (
              <Link key={item.href} href={item.href} className="focus-ring rounded-md transition hover:text-brass-300">
                {item.label}
              </Link>
            ))}
          </nav>
          <RouteLink
            href={routes.app}
            className="focus-ring inline-flex h-11 shrink-0 items-center justify-center rounded-lg border border-brass-400 bg-brass-400 px-3 text-sm font-bold text-obsidian-950 transition hover:bg-brass-300 sm:px-4"
          >
            <span className="sm:hidden">App</span>
            <span className="hidden sm:inline">Abrir app</span>
          </RouteLink>
        </Container>
      </header>
      {children}
      <footer className="border-t border-mist-700 bg-obsidian-950">
        <Container className="grid gap-8 py-10 md:grid-cols-[1.5fr_1fr_1fr]">
          <div>
            <div className="flex items-center gap-3">
              <span className="relative h-10 w-10 overflow-hidden rounded-xl border border-brass-400/25">
                <Image src="/branding/app_logo.png" alt="" fill sizes="40px" className="object-cover" />
              </span>
              <div className="font-display text-xl font-semibold">ManaLoom</div>
            </div>
            <p className="mt-3 max-w-md text-sm leading-6 text-mist-300">
              Sua próxima jogada começa no app: decks, coleção, preços e trocas no mesmo lugar.
            </p>
          </div>
          <div className="grid gap-2 text-sm text-mist-300">
            <Link href={`${routes.home}#produto`} className="hover:text-brass-300">
              Produto
            </Link>
            <Link href={routes.marketplace} className="hover:text-brass-300">
              Mercado
            </Link>
            <Link href={routes.pricing} className="hover:text-brass-300">
              Planos
            </Link>
          </div>
          <div className="grid gap-2 text-sm text-mist-300">
            <Link href={routes.terms} className="hover:text-brass-300">
              Termos
            </Link>
            <Link href={routes.privacy} className="hover:text-brass-300">
              Privacidade
            </Link>
            <Link href={routes.disclaimer} className="hover:text-brass-300">
              Disclaimer
            </Link>
          </div>
        </Container>
      </footer>
    </div>
  );
}
