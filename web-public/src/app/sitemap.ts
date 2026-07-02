import type { MetadataRoute } from "next";

import { absoluteUrl, routes } from "@/lib/routes";

export default function sitemap(): MetadataRoute.Sitemap {
  const staticRoutes = [
    routes.home,
    routes.pricing,
    routes.marketplace,
    routes.blog,
    routes.terms,
    routes.privacy,
    routes.disclaimer
  ];

  return staticRoutes.map((route) => ({
    url: absoluteUrl(route),
    lastModified: new Date("2026-07-01"),
    changeFrequency: "weekly",
    priority: route === routes.home ? 1 : 0.7
  }));
}
