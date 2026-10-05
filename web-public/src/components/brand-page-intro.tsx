import Image from "next/image";
import type { ReactNode } from "react";

type BrandPageIntroProps = {
  eyebrow: string;
  title: string;
  children: ReactNode;
};

// Page opening as a dark glass tile, the neutral piece of the life counter.
export function BrandPageIntro({ eyebrow, title, children }: BrandPageIntroProps) {
  return (
    <div className="relative w-full max-w-[calc(100vw-2.5rem)] overflow-hidden rounded-azulejo bg-azulejo p-6 shadow-azulejo sm:max-w-none sm:p-8">
      <div className="flex items-center gap-3">
        <span className="relative h-12 w-12 shrink-0 overflow-hidden rounded-[14px] bg-obsidian-950 shadow-azulejo">
          <Image src="/branding/app_logo.png" alt="" fill sizes="48px" className="object-cover" />
        </span>
        <p className="text-[11.5px] font-extrabold uppercase tracking-[0.085em] text-mist-300">{eyebrow}</p>
      </div>
      <h1 className="mt-10 max-w-3xl text-balance break-words font-display text-4xl font-semibold leading-tight text-ivory-100 sm:mt-14 sm:text-5xl">
        {title}
      </h1>
      <div className="mt-4 max-w-3xl text-base leading-7 text-mist-300">{children}</div>
    </div>
  );
}
