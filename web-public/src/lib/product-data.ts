import { routes } from "./routes";

export type ProductCapability = {
  title: string;
  description: string;
  surface: string;
  href: string;
};

export type ProductPlan = {
  id: "free" | "pro";
  name: string;
  priceLabel: string;
  monthlyAiLimit: number;
  description: string;
  features: string[];
  limits: string[];
  ctaLabel: string;
  ctaHref: string;
};

export const productCapabilities: ProductCapability[] = [
  {
    title: "Monte listas Commander",
    description: "Importe cartas, confira as 100 posições, ajuste curva de mana e acompanhe o plano do deck.",
    surface: "Deck builder",
    href: routes.app
  },
  {
    title: "Revise com IA",
    description: "Peça sugestões, compare antes de aplicar e mantenha controle sobre cada troca da lista.",
    surface: "Otimização",
    href: routes.disclaimer
  },
  {
    title: "Organize sua coleção",
    description: "Separe coleção, fichário público e cartas disponíveis para encontrar oportunidades de troca.",
    surface: "Coleção e fichário",
    href: routes.marketplace
  },
  {
    title: "Acompanhe preços",
    description: "Consulte imagens, edições e referência de mercado para decidir compra, venda ou upgrade.",
    surface: "Mercado",
    href: routes.marketplace
  }
];

export const productPlans: ProductPlan[] = [
  {
    id: "free",
    name: "Free",
    priceLabel: "R$ 0",
    monthlyAiLimit: 5,
    description:
      "Para começar uma coleção, montar primeiras listas e testar a IA sem compromisso.",
    features: [
      "5 ações de IA por mês",
      "Gerador de decks revisável",
      "Otimização com preview antes de aplicar",
      "Coleção, fichário e trocas básicos"
    ],
    limits: [
      "Sem excedente de IA depois do limite mensal",
      "Relatórios e recomendações avançadas limitados",
      "Upgrade necessário para uso frequente"
    ],
    ctaLabel: "Abrir app",
    ctaHref: routes.app
  },
  {
    id: "pro",
    name: "Pro",
    priceLabel: "Pro",
    monthlyAiLimit: 200,
    description:
      "Para quem mantém decks vivos, compara upgrades e volta depois de cada partida.",
    features: [
      "200 ações de IA por mês",
      "Otimização por coleção e orçamento",
      "Relatório antes/depois compartilhável",
      "Histórico pós-jogo e alertas de evolução",
      "Camada social, fichário público e trade matching"
    ],
    limits: [
      "Uso sujeito a política de fair use",
      "Disponibilidade depende da sua conta no app"
    ],
    ctaLabel: "Ver upgrade",
    ctaHref: routes.appUpgrade
  }
];
