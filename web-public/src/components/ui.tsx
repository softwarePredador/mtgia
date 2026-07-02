import Link from "next/link";
import type { ReactNode } from "react";

type ButtonLinkProps = {
  href: string;
  children: ReactNode;
  variant?: "primary" | "secondary" | "quiet";
};

export function ButtonLink({ href, children, variant = "primary" }: ButtonLinkProps) {
  const styles = {
    primary:
      "bg-brass-400 text-obsidian-950 hover:bg-brass-300 border-brass-400",
    secondary:
      "border-mist-700 bg-obsidian-850/72 text-ivory-100 hover:border-brass-400 hover:text-brass-300",
    quiet:
      "border-transparent bg-transparent text-mist-300 hover:text-brass-300"
  };

  return (
    <Link
      href={href}
      className={`focus-ring inline-flex min-h-11 items-center justify-center rounded-lg border px-4 py-2 text-sm font-bold transition ${styles[variant]}`}
    >
      {children}
    </Link>
  );
}

export function Container({ children, className = "" }: { children: ReactNode; className?: string }) {
  return <div className={`mx-auto w-full min-w-0 max-w-6xl px-5 sm:px-6 lg:px-8 ${className}`}>{children}</div>;
}

export function SectionHeader({
  eyebrow,
  title,
  children
}: {
  eyebrow?: string;
  title: string;
  children?: ReactNode;
}) {
  return (
    <div className="max-w-3xl">
      {eyebrow ? (
        <p className="mb-3 text-xs font-bold uppercase tracking-[0.18em] text-brass-400">
          {eyebrow}
        </p>
      ) : null}
      <h2 className="font-display text-3xl font-semibold leading-tight text-ivory-100 sm:text-4xl">
        {title}
      </h2>
      {children ? <div className="mt-4 text-base leading-7 text-mist-300">{children}</div> : null}
    </div>
  );
}

export function Stat({ label, value }: { label: string; value: string }) {
  return (
    <div className="border-l border-mist-700 pl-4">
      <div className="break-words text-2xl font-bold leading-tight text-ivory-100">{value}</div>
      <div className="mt-1 text-xs uppercase tracking-[0.14em] text-mist-500">{label}</div>
    </div>
  );
}

export function Pill({ children }: { children: ReactNode }) {
  return (
    <span className="inline-flex items-center rounded-full border border-mist-700 bg-obsidian-850/80 px-3 py-1 text-xs font-semibold text-mist-300">
      {children}
    </span>
  );
}

export function Surface({ children, className = "" }: { children: ReactNode; className?: string }) {
  return (
    <div className={`rounded-xl border border-mist-700 bg-obsidian-900/88 shadow-panel ${className}`}>
      {children}
    </div>
  );
}
