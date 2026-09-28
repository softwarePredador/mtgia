import { productCapabilities, waveLabels, type ProductCapability } from "@/lib/product-data";
import {
  AnalysisIcon,
  Azulejo,
  CatalogIcon,
  CollectionIcon,
  DeckIcon,
  LifeIcon,
  Numeral,
  StateWord,
  TileLabel
} from "./tiles";

export function CapabilityIcon({ id, className }: { id: ProductCapability["id"]; className?: string }) {
  const icons = {
    decks: DeckIcon,
    colecao: CollectionIcon,
    catalogo: CatalogIcon,
    contador: LifeIcon,
    analise: AnalysisIcon
  };
  const Icon = icons[id];
  return <Icon className={className} />;
}

function CapabilityCard({ capability }: { capability: ProductCapability }) {
  const later = capability.wave === "segunda-onda";

  return (
    <article
      className={`flex min-w-0 flex-col gap-5 rounded-azulejo bg-azulejo px-5 pb-5 pt-4 shadow-azulejo ${later ? "sm:col-span-2" : ""}`}
    >
      <div className="flex min-h-[34px] items-start gap-3">
        <CapabilityIcon id={capability.id} className={`h-[30px] w-[30px] ${later ? "text-mist-500" : "text-ivory-100"}`} />
        {later ? <StateWord word={waveLabels[capability.wave]} off /> : null}
      </div>
      <div className="flex items-end justify-between gap-3">
        <div className="min-w-0">
          <TileLabel className="text-mist-300">{capability.surface}</TileLabel>
          <h3 className="mt-2 font-display text-2xl font-semibold leading-tight text-ivory-100">{capability.title}</h3>
        </div>
        {capability.numeral ? <Numeral value={capability.numeral} className="text-[52px] text-ivory-100" /> : null}
      </div>
      <p className="max-w-xl text-sm leading-6 text-mist-300">{capability.description}</p>
    </article>
  );
}

// The beta scope: the first cohort's core plus the life counter, then AI
// analysis in the second wave (D-07). Only the later piece carries a state.
export function CapabilityWaves({ compact = false }: { compact?: boolean }) {
  return (
    <div className="grid gap-2 sm:grid-cols-2">
      {productCapabilities.map((capability) => {
        const later = capability.wave === "segunda-onda";

        return compact ? (
          <Azulejo
            key={capability.id}
            label={capability.surface}
            icon={<CapabilityIcon id={capability.id} className={`h-[34px] w-[34px] ${later ? "text-mist-500" : ""}`} />}
            numeral={capability.numeral}
            state={later ? { word: waveLabels[capability.wave], off: true } : undefined}
            className={`min-h-[118px] ${later ? "sm:col-span-2" : ""}`}
          />
        ) : (
          <CapabilityCard key={capability.id} capability={capability} />
        );
      })}
    </div>
  );
}
