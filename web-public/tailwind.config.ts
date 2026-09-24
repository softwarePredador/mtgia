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
      // Life counter tokens (docs/design/ui-kit/kit.css). Gradients carry meaning
      // only: dark glass on neutral pieces, brass on the main action.
      backgroundImage: {
        azulejo: "linear-gradient(160deg, rgba(41, 48, 65, 0.88), rgba(21, 24, 33, 0.95))",
        peca: "linear-gradient(160deg, rgba(41, 48, 65, 0.84), rgba(21, 24, 33, 0.94))",
        latao: "linear-gradient(158deg, #F4CB6C 0%, #E0A93B 40%, #C58B2A 100%)",
        brilho:
          "linear-gradient(115deg, rgba(255, 255, 255, 0.13) 0 34%, transparent 34.2%), linear-gradient(200deg, transparent 0 72%, rgba(0, 0, 0, 0.1) 72.2%)"
      },
      boxShadow: {
        brass: "0 18px 70px rgba(224, 169, 59, 0.13)",
        panel: "0 24px 90px rgba(0, 0, 0, 0.32)",
        azulejo:
          "inset 0 0 0 1.5px rgba(243, 239, 227, 0.1), inset 0 1.5px 0 rgba(255, 255, 255, 0.1), 0 8px 18px rgba(0, 0, 0, 0.45)",
        latao: "inset 0 1.5px 0 rgba(255, 255, 255, 0.45), 0 10px 22px rgba(0, 0, 0, 0.5), 0 0 0 3px rgba(11, 13, 18, 0.85)",
        seta: "0 6px 14px rgba(0, 0, 0, 0.4), inset 0 0 0 2px rgba(224, 169, 59, 0.55)",
        hub: "inset 0 0 0 1.5px #C58B2A, 0 0 0 4px #0B0D12"
      },
      borderRadius: {
        azulejo: "22px",
        dica: "16px"
      }
    }
  },
  plugins: []
};

export default config;
