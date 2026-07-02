export type ManaColor = "W" | "U" | "B" | "R" | "G" | "C";

export type PlanId = "free" | "pro";

export type PublicPlan = {
  id: PlanId;
  name: string;
  priceLabel: string;
  aiLimitLabel: string;
  highlight: string;
  ctaLabel: string;
  ctaHref: string;
  features: string[];
  bestFor: string;
};

export type OwnerSummary = {
  id: string;
  displayName: string;
  handle: string;
};

export type ManaCurvePoint = {
  label: string;
  value: number;
};

export type BreakdownItem = {
  label: string;
  value: number;
};

export type PublicDeckCard = {
  name: string;
  quantity: number;
  category: string;
  role: string;
  priceEstimateBrl: number;
};

export type PublicDeck = {
  id: string;
  slug: string;
  name: string;
  commander: string;
  colors: ManaColor[];
  owner: OwnerSummary;
  format: string;
  bracket: string;
  powerLevel: number;
  visibility: "public";
  strategySummary: string;
  manaCurve: ManaCurvePoint[];
  typeBreakdown: BreakdownItem[];
  keyCards: PublicDeckCard[];
  updatedAt: string;
};

export type ReportIntent = "casual" | "upgraded" | "optimized" | "cEDH";

export type ReportSnapshot = {
  curve: ManaCurvePoint[];
  bracket: string;
  estimatedPriceBrl: number;
  issueSummary?: string;
  expectedImpact?: string;
};

export type SwapRecommendation = {
  removeCard: string;
  addCard: string;
  reason: string;
  function: string;
  risk: "low" | "medium" | "high";
  curveImpact: string;
  priceBrl: number;
  bracketImpact: string;
  confidence: number;
};

export type PublicReport = {
  id: string;
  deckId: string;
  deckName: string;
  commander: string;
  intent: ReportIntent;
  budgetLimitBrl: number;
  preferCollection: boolean;
  before: ReportSnapshot;
  after: ReportSnapshot;
  swaps: SwapRecommendation[];
  shareTitle: string;
  shareDescription: string;
  updatedAt: string;
};

export type TradeSummary = {
  optIn: boolean;
  wishlistCount: number;
  forTradeCount: number;
  missingCardsCount: number;
};

export type PublicPlayer = {
  id: string;
  displayName: string;
  handle: string;
  avatarUrl?: string;
  playStyle: string;
  favoriteFormats: string[];
  tableLevel: string;
  publicDecks: PublicDeck[];
  tradeSummary: TradeSummary;
};

export type MarketplaceCard = {
  id: string;
  name: string;
  colors: ManaColor[];
  imageUrl: string;
  detailUrl: string;
  setCode?: string;
  typeLine?: string;
  priceEstimateBrl: number;
  priceUsd?: string;
  priceChangePct?: number;
  priceChangeUsd?: number;
  priceSourceLabel: string;
  priceUpdatedAt: string;
  dataSourceLabel: string;
  demandSignal: string;
};

export type TradeOpportunity = {
  cardName: string;
  wantedByCount: number;
  offeredByCount: number;
  regionLabel: string;
};

export type MarketplaceData = {
  cards: MarketplaceCard[];
  tradeOpportunities: TradeOpportunity[];
  featuredDecks: PublicDeck[];
};

export type BlogPost = {
  slug: string;
  title: string;
  description: string;
  publishedAt: string;
  readingTime: string;
  category: string;
  body: string[];
};
