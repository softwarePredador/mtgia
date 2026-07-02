import Image from "next/image";
import type { ReactNode } from "react";

import { Surface } from "./ui";

type BrandPageIntroProps = {
  eyebrow: string;
  title: string;
  children: ReactNode;
};

export function BrandPageIntro({ eyebrow, title, children }: BrandPageIntroProps) {
  return (
    <Surface className="relative w-full max-w-[calc(100vw-2.5rem)] overflow-hidden p-0 sm:max-w-none">
      <div className="relative min-h-[280px]">
        <Image
          src="/branding/home_hero_banner.png"
          alt=""
          fill
          sizes="(min-width: 1024px) 1152px, 100vw"
          className="object-cover object-center opacity-[0.46]"
        />
        <div className="absolute inset-0 bg-[linear-gradient(90deg,rgba(11,13,18,0.98)_0%,rgba(11,13,18,0.9)_48%,rgba(11,13,18,0.62)_100%)]" />
        <div className="relative flex min-h-[280px] items-end p-6 sm:p-8">
          <div className="w-full max-w-[calc(100vw-5rem)] sm:max-w-3xl">
            <div className="mb-5 flex items-center gap-3">
              <span className="relative h-12 w-12 overflow-hidden rounded-xl border border-brass-400/28 bg-obsidian-950">
                <Image src="/branding/app_logo.png" alt="" fill sizes="48px" className="object-cover" />
              </span>
              <p className="text-xs font-bold uppercase tracking-[0.18em] text-brass-400">{eyebrow}</p>
            </div>
            <h1 className="break-words font-display text-3xl font-semibold leading-tight text-ivory-100 sm:text-5xl">
              {title}
            </h1>
            <div className="mt-4 text-base leading-7 text-mist-300">{children}</div>
          </div>
        </div>
      </div>
    </Surface>
  );
}
