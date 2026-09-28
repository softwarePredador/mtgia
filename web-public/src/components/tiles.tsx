import Link from "next/link";
import type { ReactNode } from "react";

// Pieces of the life counter's visual language
// (docs/design/life-counter-prototype, docs/design/ui-kit/kit.css): neutral
// tiles are dark glass with an ivory hairline, the one main action is brass,
// state is a short word in the corner and a numeral is the object itself.

export type TileState = {
  word: string;
  spoken?: string;
  off?: boolean;
};

export function StateWord({ word, spoken, off = false }: TileState) {
  const style = off
    ? "text-[10.5px] font-bold uppercase leading-none tracking-[0.1em] text-mist-500"
    : "font-display text-[19px] font-bold leading-none text-ivory-100 [text-shadow:0_1px_3px_rgba(11,13,18,0.5)]";

  return (
    <span className={`ml-auto shrink-0 text-right ${style}`}>
      {spoken ? (
        <>
          <span aria-hidden="true">{word}</span>
          <span className="sr-only">{spoken}</span>
        </>
      ) : (
        word
      )}
    </span>
  );
}

export function TileLabel({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <span className={`block text-[11.5px] font-extrabold uppercase leading-[1.18] tracking-[0.085em] ${className}`}>
      {children}
    </span>
  );
}

export function Numeral({ value, className = "" }: { value: string; className?: string }) {
  return (
    <span
      className={`font-display font-bold leading-[0.8] tracking-[-0.02em] lining-nums tabular-nums [text-shadow:0_3px_8px_rgba(0,0,0,0.35)] ${className}`}
    >
      {value}
    </span>
  );
}

type AzulejoProps = {
  label: string;
  icon?: ReactNode;
  numeral?: string;
  state?: TileState;
  className?: string;
  numeralClassName?: string;
};

export function Azulejo({
  label,
  icon,
  numeral,
  state,
  className = "",
  numeralClassName = "text-[56px]"
}: AzulejoProps) {
  return (
    <div
      className={`relative flex min-w-0 flex-col justify-between gap-3 overflow-hidden rounded-azulejo bg-azulejo px-3.5 pb-[11px] pt-3 text-ivory-100 shadow-azulejo ${className}`}
    >
      <div className="flex min-h-[34px] items-start gap-3">
        {icon}
        {state ? <StateWord {...state} /> : null}
        {numeral && !state ? <Numeral value={numeral} className={`ml-auto ${numeralClassName}`} /> : null}
      </div>
      <div className="flex items-end justify-between gap-3">
        <TileLabel className="[text-shadow:0_1px_2px_rgba(0,0,0,0.35)]">{label}</TileLabel>
        {numeral && state ? <Numeral value={numeral} className={numeralClassName} /> : null}
      </div>
    </div>
  );
}

// A fact that holds for the whole beta, stated as a word, not a control.
export function FactTile({ label, value, children }: { label: string; value: string; children?: ReactNode }) {
  return (
    <div className="flex min-w-0 flex-col justify-between gap-6 rounded-azulejo bg-azulejo px-5 pb-5 pt-4 shadow-azulejo">
      <TileLabel className="text-mist-300">{label}</TileLabel>
      <div>
        <p className="font-display text-[30px] font-bold leading-none tracking-[-0.01em] text-ivory-100">{value}</p>
        {children ? <div className="mt-3 text-sm leading-6 text-mist-300">{children}</div> : null}
      </div>
    </div>
  );
}

type HeroTileProps = {
  href: string;
  label: string;
  title: string;
  accessibleName: string;
  className?: string;
};

// The one brass piece of a screen: its main action.
export function HeroTile({ href, label, title, accessibleName, className = "" }: HeroTileProps) {
  return (
    <Link
      href={href}
      aria-label={accessibleName}
      className={`focus-ring relative flex min-w-0 items-center gap-3 overflow-hidden rounded-azulejo bg-latao py-2.5 pl-4 pr-3.5 text-obsidian-950 shadow-latao transition active:scale-[0.97] ${className}`}
    >
      <span aria-hidden="true" className="pointer-events-none absolute inset-0 bg-brilho" />
      <span className="relative min-w-0 flex-1">
        <TileLabel>{label}</TileLabel>
        <span className="mt-2 block truncate font-display text-[28px] font-bold leading-none tracking-[-0.01em]">
          {title}
        </span>
      </span>
      <span
        aria-hidden="true"
        className="relative grid h-14 w-14 shrink-0 place-items-center rounded-full bg-obsidian-950 text-brass-400 shadow-seta"
      >
        <ArrowIcon />
      </span>
    </Link>
  );
}

export function Hub({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <span className={`relative grid shrink-0 place-items-center rounded-full bg-obsidian-900 shadow-hub ${className}`}>
      {children}
    </span>
  );
}

function Glyph({ children, className = "h-[34px] w-[34px]" }: { children: ReactNode; className?: string }) {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={1.9}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={`shrink-0 [filter:drop-shadow(0_2px_3px_rgba(0,0,0,0.35))] ${className}`}
    >
      {children}
    </svg>
  );
}

type IconProps = { className?: string };

export function DeckIcon({ className }: IconProps) {
  return (
    <Glyph className={className}>
      <rect x="4" y="6.5" width="11" height="14.5" rx="2" />
      <path d="M8.5 3.5h9A2.5 2.5 0 0 1 20 6v11" />
    </Glyph>
  );
}

export function CollectionIcon({ className }: IconProps) {
  return (
    <Glyph className={className}>
      <path d="M5 5.5A2.5 2.5 0 0 1 7.5 3H19v14.5H7.5A2.5 2.5 0 0 0 5 20z" />
      <path d="M5 20a1 1 0 0 0 1 1h13v-3.5" />
      <path d="M9 7.5h6" />
    </Glyph>
  );
}

export function CatalogIcon({ className }: IconProps) {
  return (
    <Glyph className={className}>
      <circle cx="10.5" cy="10.5" r="6.5" />
      <path d="m15.5 15.5 5 5" />
    </Glyph>
  );
}

export function LifeIcon({ className }: IconProps) {
  return (
    <Glyph className={className}>
      <path d="M12 20.5s-8-4.9-8-10.6A4.4 4.4 0 0 1 12 7.2a4.4 4.4 0 0 1 8 2.7c0 5.7-8 10.6-8 10.6z" />
    </Glyph>
  );
}

export function AnalysisIcon({ className }: IconProps) {
  return (
    <Glyph className={className}>
      <path d="M11 3.5 12.9 8.6 18 10.5l-5.1 1.9L11 17.5l-1.9-5.1L4 10.5l5.1-1.9z" />
      <path d="m18.5 15 .9 2.1 2.1.9-2.1.9-.9 2.1-.9-2.1-2.1-.9 2.1-.9z" />
    </Glyph>
  );
}

export function InviteIcon({ className }: IconProps) {
  return (
    <Glyph className={className}>
      <rect x="3" y="5.5" width="18" height="13" rx="2.5" />
      <path d="m4 7.5 8 6 8-6" />
    </Glyph>
  );
}

export function ArrowIcon({ className = "h-[27px] w-[27px]" }: IconProps) {
  return (
    <svg
      aria-hidden="true"
      viewBox="0 0 24 24"
      fill="none"
      stroke="currentColor"
      strokeWidth={2.4}
      strokeLinecap="round"
      strokeLinejoin="round"
      className={className}
    >
      <path d="M5 12h14M13 6l6 6-6 6" />
    </svg>
  );
}
