import type { MetadataRoute } from "next";

import { absoluteUrl } from "@/lib/routes";

export default function robots(): MetadataRoute.Robots {
  return {
    rules: {
      userAgent: "*",
      allow: "/",
      disallow: ["/app/private", "/api/private"]
    },
    sitemap: absoluteUrl("/sitemap.xml")
  };
}
