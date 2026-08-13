export const currentPublicSiteFallbackUrl =
  "https://brewtact.com";

function resolveSiteUrl(configuredValue: string | undefined) {
  const candidate = configuredValue?.trim();
  if (!candidate) return currentPublicSiteFallbackUrl;

  try {
    const parsed = new URL(candidate);
    if (
      parsed.protocol !== "https:" ||
      parsed.username ||
      parsed.password ||
      parsed.search ||
      parsed.hash ||
      (parsed.pathname !== "" && parsed.pathname !== "/")
    ) {
      return currentPublicSiteFallbackUrl;
    }
    return parsed.origin;
  } catch {
    return currentPublicSiteFallbackUrl;
  }
}

export const siteUrl = resolveSiteUrl(process.env.NEXT_PUBLIC_SITE_URL);

export const routes = {
  home: "/",
  pricing: "/pricing",
  blog: "/blog",
  terms: "/legal/terms",
  privacy: "/legal/privacy",
  disclaimer: "/legal/disclaimer",
  report: (id: string) => `/reports/${id}`,
  post: (slug: string) => `/blog/${slug}`
} as const;

export function absoluteUrl(path: string) {
  return `${siteUrl}${path.startsWith("/") ? path : `/${path}`}`;
}
