export type Wave = "primeira-onda" | "segunda-onda";

export type ProductCapability = {
  title: string;
  description: string;
  surface: string;
  wave: Wave;
};

export type FreeBetaOffer = {
  id: "free-beta";
  name: string;
  status: string;
  description: string;
  availability: string[];
};

export const waveLabels: Record<Wave, string> = {
  "primeira-onda": "Primeira onda",
  "segunda-onda": "Segunda onda"
};

// The first invited cohort gets the core plus the life counter; AI analysis
// comes in a second wave, after it (D-07). Public copy calls them waves.
export const productCapabilities: ProductCapability[] = [
  {
    title: "Monte listas Commander",
    description: "Crie ou importe listas e confira as 100 posições do deck em um espaço privado.",
    surface: "Deck builder",
    wave: "primeira-onda"
  },
  {
    title: "Organize sua coleção",
    description: "Registre cartas e quantidades para consultar sua coleção no ambiente autenticado.",
    surface: "Coleção privada",
    wave: "primeira-onda"
  },
  {
    title: "Consulte as cartas",
    description: "Use o catálogo de cartas como referência para montar e revisar suas listas.",
    surface: "Catálogo",
    wave: "primeira-onda"
  },
  {
    title: "Leve o deck para a mesa",
    description: "Acompanhe a vida de cada jogador durante a partida.",
    surface: "Contador de vida",
    wave: "primeira-onda"
  },
  {
    title: "Revise sugestões",
    description:
      "Chega na segunda onda, depois da primeira. Quando a IA estiver habilitada, cada sugestão passa pela sua revisão antes de mudar o deck.",
    surface: "Análise com IA",
    wave: "segunda-onda"
  }
];

export const freeBetaOffer: FreeBetaOffer = {
  id: "free-beta",
  name: "Beta gratuita",
  status: "Acesso por convite",
  description:
    "Uma única experiência BrewTact, sem cobrança, para validar o núcleo e o contador de vida com um grupo pequeno de convidados.",
  availability: [
    "A entrada é por convite, em lotes pequenos. O cadastro não está aberto nesta fase.",
    "A análise com IA chega na segunda onda, depois da primeira, e depende da capacidade habilitada para a conta.",
    "Os limites operacionais vigentes aparecem no ambiente autenticado."
  ]
};
