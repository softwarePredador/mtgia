import type { Metadata } from "next";
import Image from "next/image";
import Link from "next/link";
import { notFound } from "next/navigation";

import { BrandPageIntro } from "@/components/brand-page-intro";
import { ButtonLink, Container, Pill, Surface } from "@/components/ui";
import { loadPublicUserProfile } from "@/lib/public-server";
import { routes } from "@/lib/routes";

type PageProps = {
  params: Promise<{ id: string }>;
};

export const revalidate = 300;

export function generateStaticParams() {
  return [];
}

export async function generateMetadata({ params }: PageProps): Promise<Metadata> {
  const { id } = await params;
  const profile = await loadPublicUserProfile(id);
  if (!profile) return {};

  const label = profile.displayName || profile.username || "Perfil público";
  return {
    title: `${label} - perfil público`,
    description: `Perfil público ManaLoom com ${profile.publicDeckCount ?? profile.publicDecks.length} decks públicos.`
  };
}

export default async function PublicPlayerPage({ params }: PageProps) {
  const { id } = await params;
  const profile = await loadPublicUserProfile(id);
  if (!profile) notFound();

  const label = profile.displayName || profile.username || "Perfil ManaLoom";

  return (
    <main className="py-16">
      <Container>
        <div className="mb-10">
          <BrandPageIntro eyebrow="Perfil público" title={label}>
            <p>Dados reais retornados por `/community/users/:id`, sem e-mail ou senha expostos.</p>
          </BrandPageIntro>
        </div>
        <div className="grid gap-10 lg:grid-cols-[0.72fr_1.28fr]">
          <div>
            <div className="flex items-center gap-4">
              <div className="relative h-16 w-16 overflow-hidden rounded-2xl border border-mist-700 bg-obsidian-900">
                {profile.avatarUrl ? (
                  <Image src={profile.avatarUrl} alt="" fill sizes="64px" unoptimized className="object-cover" />
                ) : (
                  <Image src="/branding/app_logo.png" alt="" fill sizes="64px" className="object-cover opacity-70" />
                )}
              </div>
              <div>
                <p className="font-bold text-ivory-100">{profile.username}</p>
                <p className="text-sm text-mist-500">ID público: {profile.id}</p>
              </div>
            </div>
            <div className="mt-6 flex flex-wrap gap-2">
              <Pill>{profile.followerCount ?? 0} seguidores</Pill>
              <Pill>{profile.followingCount ?? 0} seguindo</Pill>
              <Pill>{profile.publicDeckCount ?? profile.publicDecks.length} decks públicos</Pill>
            </div>
            <div className="mt-8">
              <ButtonLink href={routes.app}>Abrir app</ButtonLink>
            </div>
          </div>

          <Surface className="p-5">
            <h2 className="text-lg font-bold">Decks públicos</h2>
            {profile.publicDecks.length > 0 ? (
              <div className="mt-5 grid gap-4">
                {profile.publicDecks.map((deck) => (
                  <Link
                    key={deck.id}
                    href={routes.deck(deck.id)}
                    className="focus-ring rounded-lg border border-mist-700 bg-obsidian-950/58 p-4 transition hover:border-brass-400"
                  >
                    <h3 className="font-bold text-ivory-100">{deck.name}</h3>
                    <p className="mt-1 text-sm text-mist-300">
                      {deck.commanderName ?? deck.format ?? "Deck público"}
                    </p>
                  </Link>
                ))}
              </div>
            ) : (
              <p className="mt-5 text-sm leading-6 text-mist-300">Nenhum deck público retornado para este perfil.</p>
            )}
          </Surface>
        </div>
      </Container>
    </main>
  );
}
