export const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL?.replace(/\/$/, "") ?? "https://manaloom.com";

export const routes = {
  home: "/",
  pricing: "/pricing",
  app: "/app",
  appUpgrade: "/app?upgrade=pro",
  marketplace: "/marketplace",
  blog: "/blog",
  terms: "/legal/terms",
  privacy: "/legal/privacy",
  disclaimer: "/legal/disclaimer",
  deck: (id: string) => `/decks/${id}`,
  report: (id: string) => `/reports/${id}`,
  player: (id: string) => `/players/${id}`,
  post: (slug: string) => `/blog/${slug}`
} as const;

export function absoluteUrl(path: string) {
  return `${siteUrl}${path.startsWith("/") ? path : `/${path}`}`;
}
