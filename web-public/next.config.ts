import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  devIndicators: false,
  images: {
    remotePatterns: [
      {
        protocol: "https",
        hostname: "cards.scryfall.io",
        pathname: "/**"
      },
      {
        protocol: "https",
        hostname: "api.scryfall.com",
        pathname: "/**"
      }
    ]
  },
  reactStrictMode: true
};

export default nextConfig;
