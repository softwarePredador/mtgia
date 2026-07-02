import type { Config } from "tailwindcss";

const config: Config = {
  content: ["./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        obsidian: {
          950: "#0B0D12",
          900: "#151821",
          850: "#1D222C",
          800: "#252B37"
        },
        brass: {
          700: "#8E641B",
          500: "#C58B2A",
          400: "#E0A93B",
          300: "#F0C66E"
        },
        frost: {
          600: "#3E5F8A",
          400: "#6FA8DC"
        },
        ivory: {
          100: "#F3EFE3",
          200: "#DDD6C6"
        },
        mist: {
          300: "#B8C0CC",
          500: "#8A93A3",
          700: "#293041"
        }
      },
      fontFamily: {
        sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
        display: ["Fraunces", "Georgia", "serif"]
      },
      boxShadow: {
        brass: "0 18px 70px rgba(224, 169, 59, 0.13)",
        panel: "0 24px 90px rgba(0, 0, 0, 0.32)"
      }
    }
  },
  plugins: []
};

export default config;
