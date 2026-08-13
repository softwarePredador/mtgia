export type ProductCapability = {
  title: string;
  description: string;
  surface: string;
};

export type FreeBetaOffer = {
  id: "free-beta";
  name: string;
  status: string;
  description: string;
  features: string[];
  availability: string[];
};

export const productCapabilities: ProductCapability[] = [
  {
    title: "Monte listas Commander",
    description: "Crie ou importe listas, confira as 100 posições e acompanhe o plano do deck em um espaço privado.",
    surface: "Deck builder"
  },
  {
    title: "Revise sugestões",
    description: "Quando a IA estiver habilitada, compare as sugestões antes de aplicar e mantenha a decisão final.",
    surface: "Análise revisável"
  },
  {
    title: "Organize sua coleção",
    description: "Registre cartas e quantidades para consultar sua coleção no ambiente autenticado.",
    surface: "Coleção privada"
  },
  {
    title: "Consulte as cartas",
    description: "Use o catálogo de cartas como referência para montar, revisar e compreender suas listas.",
    surface: "Catálogo"
  }
];

export const freeBetaOffer: FreeBetaOffer = {
  id: "free-beta",
  name: "Beta gratuita",
  status: "Acesso controlado",
  description:
    "Uma única experiência BrewTact para validar o fluxo principal com usuários convidados, sem cobrança.",
  features: [
    "Deck builder para criar e importar listas",
    "Coleção privada e catálogo de cartas",
    "Sugestões de IA revisáveis, quando habilitadas",
    "Relatórios compartilháveis quando esse recurso estiver habilitado"
  ],
  availability: [
    "A entrada pode ser liberada em etapas durante a preparação da beta.",
    "Recursos de IA dependem da capacidade habilitada para a conta.",
    "Os limites operacionais vigentes aparecem no ambiente autenticado."
  ]
};
