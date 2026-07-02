import Image from "next/image";

import type { BreakdownItem, ManaColor, ManaCurvePoint, SwapRecommendation } from "@/lib/types";

const manaLabels: Record<ManaColor, string> = {
  W: "mana branca",
  U: "mana azul",
  B: "mana preta",
  R: "mana vermelha",
  G: "mana verde",
  C: "mana incolor"
};

export function ManaPips({ colors }: { colors: ManaColor[] }) {
  return (
    <div className="flex flex-wrap gap-1.5">
      {colors.map((color) => (
        <span
          key={color}
          aria-label={manaLabels[color]}
          className="grid h-7 w-7 place-items-center rounded-full bg-obsidian-950/70 shadow-[0_2px_10px_rgba(0,0,0,0.34)] ring-1 ring-ivory-100/18"
          data-mana-symbol={color}
          title={manaLabels[color]}
        >
          <Image
            src={`/symbols/${color}.svg`}
            alt=""
            width={28}
            height={28}
            unoptimized
            className="rounded-full"
          />
          <span className="sr-only">{color}</span>
        </span>
      ))}
    </div>
  );
}

export function ManaCost({ cost }: { cost?: string }) {
  if (!cost) {
    return null;
  }

  const symbols = Array.from(cost.matchAll(/\{([^}]+)\}/g)).map((match) => match[1]);

  if (symbols.length === 0) {
    return <span className="text-xs font-semibold text-mist-500">{cost}</span>;
  }

  return (
    <div className="flex flex-wrap gap-1.5" aria-label={`Custo de mana ${cost}`}>
      {symbols.map((symbol, index) => {
        const upper = symbol.toUpperCase();
        const simpleSymbol = upper.length === 1 && upper in manaLabels ? (upper as ManaColor) : null;

        return (
          <span
            key={`${symbol}-${index}`}
            className="grid h-7 min-w-7 place-items-center rounded-full bg-ivory-100 text-xs font-black text-obsidian-950 shadow-[0_2px_10px_rgba(0,0,0,0.34)] ring-1 ring-ivory-100/18"
            title={symbol}
          >
            {simpleSymbol ? (
              <Image
                src={`/symbols/${simpleSymbol}.svg`}
                alt=""
                width={28}
                height={28}
                unoptimized
                className="rounded-full"
              />
            ) : (
              <span className="px-1">{symbol}</span>
            )}
          </span>
        );
      })}
    </div>
  );
}

export function ManaCurve({ points }: { points: ManaCurvePoint[] }) {
  const max = Math.max(...points.map((point) => point.value), 1);

  return (
    <div className="grid grid-cols-6 items-end gap-2">
      {points.map((point) => (
        <div key={point.label} className="grid gap-2 text-center">
          <div className="flex h-32 items-end rounded-md bg-obsidian-950/80 p-1">
            <div
              className="w-full rounded bg-gradient-to-t from-brass-700 to-brass-300"
              style={{ height: `${Math.max((point.value / max) * 100, 8)}%` }}
            />
          </div>
          <div className="text-xs font-bold text-ivory-100">{point.label}</div>
          <div className="text-[11px] text-mist-500">{point.value}</div>
        </div>
      ))}
    </div>
  );
}

export function BreakdownBars({ items }: { items: BreakdownItem[] }) {
  const total = Math.max(items.reduce((sum, item) => sum + item.value, 0), 1);

  return (
    <div className="grid gap-3">
      {items.map((item) => (
        <div key={item.label} className="grid gap-1.5">
          <div className="flex items-center justify-between gap-4 text-sm">
            <span className="text-mist-300">{item.label}</span>
            <span className="font-semibold text-ivory-100">{item.value}</span>
          </div>
          <div className="h-2 rounded-full bg-obsidian-950">
            <div
              className="h-full rounded-full bg-frost-400"
              style={{ width: `${(item.value / total) * 100}%` }}
            />
          </div>
        </div>
      ))}
    </div>
  );
}

export function Confidence({ value }: { value: number }) {
  return (
    <div className="grid gap-1">
      <div className="flex justify-between text-xs text-mist-500">
        <span>Confianca</span>
        <span>{value}%</span>
      </div>
      <div className="h-2 rounded-full bg-obsidian-950">
        <div className="h-full rounded-full bg-brass-400" style={{ width: `${value}%` }} />
      </div>
    </div>
  );
}

export function SwapRisk({ risk }: { risk: SwapRecommendation["risk"] }) {
  const labels = {
    low: "Baixo",
    medium: "Medio",
    high: "Alto"
  };

  return (
    <span className="rounded-full border border-mist-700 px-2.5 py-1 text-xs font-semibold text-mist-300">
      Risco {labels[risk]}
    </span>
  );
}
