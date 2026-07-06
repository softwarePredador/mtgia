const DEFAULT_MANALOOM_API_BASE_URL = "https://evolution-cartinhas.2ta7qx.easypanel.host";
const SERVER_REVALIDATE_SECONDS = 300;

export type PublicHealth = {
  status?: string;
  service?: string;
  environment?: string;
  version?: string;
  git_sha?: string | null;
};

export type MarketplaceListing = {
  id: string;
  cardId?: string;
  cardName: string;
  imageUrl?: string;
  setCode?: string;
  manaCost?: string;
  typeLine?: string;
  rarity?: string;
  quantity: number;
  condition?: string;
  isFoil?: boolean;
  forTrade: boolean;
  forSale: boolean;
  price?: number;
  currency?: string;
  referencePriceUsd?: number;
  latestPriceUsd?: number;
  latestPriceDate?: string;
  trendStatus?: string;
  trendDirection?: string;
  trendChangePct?: number;
  comparisonStatus?: string;
  ownerLabel?: string;
  notes?: string;
};

export type MarketplaceCardSummary = {
  key: string;
  cardName: string;
  imageUrl?: string;
  setCode?: string;
  manaCost?: string;
  typeLine?: string;
  rarity?: string;
  listingCount: number;
  totalQuantity: number;
  conditions: string[];
  forTrade: boolean;
  forSale: boolean;
  minPrice?: number;
  maxPrice?: number;
  currency?: string;
  referencePriceUsd?: number;
  latestPriceUsd?: number;
  latestPriceDate?: string;
  trendStatus?: string;
  trendDirection?: string;
  trendChangePct?: number;
  comparisonStatus?: string;
};

export type PublicDeckSummary = {
  id: string;
  name: string;
  format?: string;
  cardCount?: number;
  commanderName?: string | null;
  commanderImageUrl?: string | null;
  createdAt?: string;
};

export type PublicDeckDetail = {
  id: string;
  name: string;
  format?: string;
  description?: string | null;
  createdAt?: string;
  ownerUsername?: string;
  stats?: {
    total_cards?: number;
    unique_cards?: number;
    mana_curve?: Record<string, number>;
    color_distribution?: Record<string, number>;
  };
  commander?: PublicDeckCard[];
  allCards?: PublicDeckCard[];
};

export type PublicDeckCard = {
  id: string;
  name: string;
  quantity: number;
  isCommander?: boolean;
  manaCost?: string;
  typeLine?: string;
  oracleText?: string;
  imageUrl?: string;
  setCode?: string;
  rarity?: string;
};

export type PublicUserProfile = {
  id: string;
  username?: string;
  displayName?: string | null;
  avatarUrl?: string | null;
  followerCount?: number;
  followingCount?: number;
  publicDeckCount?: number;
  publicDecks: PublicDeckSummary[];
};

export type MarketMoversSummary = {
  date?: string | null;
  previousDate?: string | null;
  totalTracked?: number;
  hasMovers: boolean;
};

export type MarketplaceFeed = {
  listings: MarketplaceListing[];
  cards: MarketplaceCardSummary[];
  total: number;
  rawReturned: number;
  hiddenInternalCount: number;
  duplicateListingCount: number;
  page: number;
  limit: number;
  sourceSummary: string;
  serverBaseUrl: string;
  movers: MarketMoversSummary;
};

export type PublicSiteFeed = {
  health: PublicHealth | null;
  marketplace: MarketplaceFeed;
  publicDecks: {
    items: PublicDeckSummary[];
    total: number;
    rawTotal: number;
  };
};

type HealthResponse = PublicHealth;

type CommunityMarketplaceItem = {
  id?: string;
  card?: {
    id?: string;
    name?: string;
    image_url?: string | null;
    set_code?: string | null;
    mana_cost?: string | null;
    rarity?: string | null;
    type_line?: string | null;
  };
  quantity?: number;
  condition?: string | null;
  is_foil?: boolean | null;
  for_trade?: boolean | null;
  for_sale?: boolean | null;
  price?: number | string | null;
  currency?: string | null;
  notes?: string | null;
  price_insight?: {
    reference_price?: number | string | null;
    trend?: {
      status?: string | null;
      direction?: string | null;
      latest_price?: number | string | null;
      latest_date?: string | null;
      change_pct?: number | string | null;
    };
    comparison?: {
      status?: string | null;
    };
  };
  owner?: {
    username?: string | null;
    display_name?: string | null;
  };
};

type CommunityMarketplaceResponse = {
  data?: CommunityMarketplaceItem[];
  page?: number;
  limit?: number;
  total?: number;
};

type MarketMoversResponse = {
  date?: string | null;
  previous_date?: string | null;
  gainers?: unknown[];
  losers?: unknown[];
  total_tracked?: number;
};

type PublicDeckSummaryResponse = {
  id?: string;
  name?: string;
  format?: string | null;
  card_count?: number | null;
  commander_name?: string | null;
  commander_image_url?: string | null;
  created_at?: string | null;
};

type PublicDecksResponse = {
  data?: PublicDeckSummaryResponse[];
  total?: number;
};

type PublicDeckDetailResponse = {
  id?: string;
  name?: string;
  format?: string | null;
  description?: string | null;
  created_at?: string | null;
  owner_username?: string | null;
  stats?: PublicDeckDetail["stats"];
  commander?: PublicDeckCardResponse[];
  all_cards_flat?: PublicDeckCardResponse[];
};

type PublicDeckCardResponse = {
  id?: string;
  name?: string;
  quantity?: number;
  is_commander?: boolean;
  mana_cost?: string | null;
  type_line?: string | null;
  oracle_text?: string | null;
  image_url?: string | null;
  set_code?: string | null;
  rarity?: string | null;
};

type PublicUserProfileResponse = {
  user?: {
    id?: string;
    username?: string | null;
    display_name?: string | null;
    avatar_url?: string | null;
    follower_count?: number;
    following_count?: number;
    public_deck_count?: number;
  };
  public_decks?: PublicDeckSummaryResponse[];
};

export function getServerBaseUrl() {
  const configured = process.env.NEXT_PUBLIC_MANALOOM_API_BASE_URL?.trim();
  return (configured && configured.length > 0 ? configured : DEFAULT_MANALOOM_API_BASE_URL).replace(/\/+$/, "");
}

async function fetchJson<T>(baseUrl: string, path: string): Promise<T | null> {
  try {
    const response = await fetch(`${baseUrl}${path}`, {
      next: { revalidate: SERVER_REVALIDATE_SECONDS }
    });

    if (!response.ok) {
      return null;
    }

    return (await response.json()) as T;
  } catch {
    return null;
  }
}

function toNumber(value: number | string | null | undefined) {
  if (typeof value === "number") {
    return Number.isFinite(value) ? value : undefined;
  }

  if (typeof value === "string" && value.trim().length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }

  return undefined;
}

function mapMarketplaceItem(item: CommunityMarketplaceItem): MarketplaceListing | null {
  const cardName = item.card?.name?.trim();
  const id = item.id?.trim();

  if (!id || !cardName) {
    return null;
  }

  return {
    id,
    cardId: item.card?.id,
    cardName,
    imageUrl: item.card?.image_url ?? undefined,
    setCode: item.card?.set_code ?? undefined,
    manaCost: item.card?.mana_cost ?? undefined,
    typeLine: item.card?.type_line ?? undefined,
    rarity: item.card?.rarity ?? undefined,
    quantity: item.quantity ?? 1,
    condition: item.condition ?? undefined,
    isFoil: item.is_foil ?? undefined,
    forTrade: item.for_trade === true,
    forSale: item.for_sale === true,
    price: toNumber(item.price),
    currency: item.currency ?? undefined,
    referencePriceUsd: toNumber(item.price_insight?.reference_price),
    latestPriceUsd: toNumber(item.price_insight?.trend?.latest_price),
    latestPriceDate: item.price_insight?.trend?.latest_date ?? undefined,
    trendStatus: item.price_insight?.trend?.status ?? undefined,
    trendDirection: item.price_insight?.trend?.direction ?? undefined,
    trendChangePct: toNumber(item.price_insight?.trend?.change_pct),
    comparisonStatus: item.price_insight?.comparison?.status ?? undefined,
    ownerLabel: item.owner?.display_name?.trim() || item.owner?.username?.trim() || undefined,
    notes: item.notes?.trim() || undefined
  };
}

function isInternalMarketplaceListing(item: MarketplaceListing) {
  const text = `${item.ownerLabel ?? ""} ${item.notes ?? ""}`.toLowerCase();
  return /\bqa[_-]|_qa_|profile_community|runtime proof|visible binder item|marketplace sale item|realtime sale item|social_live|respond_seller|\btest\b/.test(text);
}

function marketplaceCardKey(item: MarketplaceListing) {
  return item.cardId ?? `${item.cardName.toLowerCase()}|${item.setCode?.toLowerCase() ?? ""}`;
}

function uniqueValues(values: Array<string | undefined>) {
  return Array.from(new Set(values.filter((value): value is string => Boolean(value)))).sort();
}

function isPublicDeckShowcase(deck: PublicDeckSummary) {
  const name = deck.name.toLowerCase();
  const blockedName = /\bqa[_-]|_qa_|profile community runtime|runtime proof|social_live|respond_seller|\btest\b|updated deck|deck a \d+/.test(name);

  return (
    !blockedName &&
    deck.format?.toLowerCase() === "commander" &&
    Boolean(deck.commanderName) &&
    (deck.cardCount ?? 0) >= 60
  );
}

function summarizeMarketplaceCards(listings: MarketplaceListing[]) {
  const grouped = new Map<string, MarketplaceListing[]>();

  for (const item of listings) {
    const key = marketplaceCardKey(item);
    grouped.set(key, [...(grouped.get(key) ?? []), item]);
  }

  const cards = Array.from(grouped.entries()).map(([key, items]) => {
    const display = items.find((item) => item.imageUrl) ?? items[0];
    const prices = items
      .map((item) => item.price)
      .filter((price): price is number => typeof price === "number" && Number.isFinite(price));
    const minPrice = prices.length > 0 ? Math.min(...prices) : undefined;
    const maxPrice = prices.length > 0 ? Math.max(...prices) : undefined;
    const priceOwner = minPrice === undefined ? display : items.find((item) => item.price === minPrice) ?? display;

    return {
      key,
      cardName: display.cardName,
      imageUrl: display.imageUrl,
      setCode: display.setCode,
      manaCost: display.manaCost,
      typeLine: display.typeLine,
      rarity: display.rarity,
      listingCount: items.length,
      totalQuantity: items.reduce((sum, item) => sum + item.quantity, 0),
      conditions: uniqueValues(items.map((item) => item.condition)),
      forTrade: items.some((item) => item.forTrade),
      forSale: items.some((item) => item.forSale),
      minPrice,
      maxPrice,
      currency: priceOwner.currency,
      referencePriceUsd: display.referencePriceUsd,
      latestPriceUsd: display.latestPriceUsd,
      latestPriceDate: display.latestPriceDate,
      trendStatus: display.trendStatus,
      trendDirection: display.trendDirection,
      trendChangePct: display.trendChangePct,
      comparisonStatus: display.comparisonStatus
    } satisfies MarketplaceCardSummary;
  });

  return cards.sort((a, b) => {
    const aHasPrice = a.minPrice === undefined ? 0 : 1;
    const bHasPrice = b.minPrice === undefined ? 0 : 1;
    if (aHasPrice !== bHasPrice) return bHasPrice - aHasPrice;
    return b.listingCount - a.listingCount || a.cardName.localeCompare(b.cardName);
  });
}

function mapDeckSummary(deck: PublicDeckSummaryResponse): PublicDeckSummary | null {
  if (!deck.id || !deck.name) {
    return null;
  }

  return {
    id: deck.id,
    name: deck.name,
    format: deck.format ?? undefined,
    cardCount: deck.card_count ?? undefined,
    commanderName: deck.commander_name ?? undefined,
    commanderImageUrl: deck.commander_image_url ?? undefined,
    createdAt: deck.created_at ?? undefined
  };
}

function mapDeckCard(card: PublicDeckCardResponse): PublicDeckCard | null {
  if (!card.id || !card.name) {
    return null;
  }

  return {
    id: card.id,
    name: card.name,
    quantity: card.quantity ?? 1,
    isCommander: card.is_commander,
    manaCost: card.mana_cost ?? undefined,
    typeLine: card.type_line ?? undefined,
    oracleText: card.oracle_text ?? undefined,
    imageUrl: card.image_url ?? undefined,
    setCode: card.set_code ?? undefined,
    rarity: card.rarity ?? undefined
  };
}

async function loadMarketMoversSummary(baseUrl: string): Promise<MarketMoversSummary> {
  const payload = await fetchJson<MarketMoversResponse>(baseUrl, "/market/movers?limit=6&min_price=0");
  return {
    date: payload?.date ?? null,
    previousDate: payload?.previous_date ?? null,
    totalTracked: payload?.total_tracked,
    hasMovers: Boolean((payload?.gainers?.length ?? 0) + (payload?.losers?.length ?? 0))
  };
}

export async function loadMarketplaceFeed(limit = 6): Promise<MarketplaceFeed> {
  const baseUrl = getServerBaseUrl();
  const [marketplacePayload, movers] = await Promise.all([
    fetchJson<CommunityMarketplaceResponse>(baseUrl, `/community/marketplace?limit=${limit}`),
    loadMarketMoversSummary(baseUrl)
  ]);

  const listings = (marketplacePayload?.data ?? [])
    .map(mapMarketplaceItem)
    .filter((item): item is MarketplaceListing => item !== null);
  const publicListings = listings.filter((item) => !isInternalMarketplaceListing(item));
  const cards = summarizeMarketplaceCards(publicListings);
  const duplicateListingCount = publicListings.length - cards.length;
  const hiddenInternalCount = listings.length - publicListings.length;

  const total = marketplacePayload?.total ?? 0;
  const sourceSummary =
    cards.length > 0
      ? `${cards.length} cartas com oferta ativa agora.`
      : listings.length > 0
        ? "Nenhuma oferta ativa para visitantes neste momento."
        : "Nenhuma oferta pública foi encontrada neste momento.";

  return {
    listings: publicListings,
    cards,
    total,
    rawReturned: listings.length,
    hiddenInternalCount,
    duplicateListingCount,
    page: marketplacePayload?.page ?? 1,
    limit: marketplacePayload?.limit ?? limit,
    sourceSummary,
    serverBaseUrl: baseUrl,
    movers
  };
}

export async function loadPublicDeckSummaries(limit = 3) {
  const baseUrl = getServerBaseUrl();
  const payload = await fetchJson<PublicDecksResponse>(baseUrl, `/community/decks?limit=${Math.max(limit, 100)}`);
  const publicDecks = (payload?.data ?? [])
    .map(mapDeckSummary)
    .filter((deck): deck is PublicDeckSummary => deck !== null)
    .filter(isPublicDeckShowcase);

  return {
    items: publicDecks.slice(0, limit),
    total: publicDecks.length,
    rawTotal: payload?.total ?? 0
  };
}

export async function loadPublicSiteFeed(): Promise<PublicSiteFeed> {
  const baseUrl = getServerBaseUrl();
  const [health, marketplace, publicDecks] = await Promise.all([
    fetchJson<HealthResponse>(baseUrl, "/health"),
    loadMarketplaceFeed(100),
    loadPublicDeckSummaries(3)
  ]);

  return {
    health,
    marketplace,
    publicDecks
  };
}

export async function loadPublicDeckDetail(id: string): Promise<PublicDeckDetail | null> {
  const baseUrl = getServerBaseUrl();
  const payload = await fetchJson<PublicDeckDetailResponse>(baseUrl, `/community/decks/${encodeURIComponent(id)}`);

  if (!payload?.id || !payload.name) {
    return null;
  }

  const commander = (payload.commander ?? []).map(mapDeckCard).filter((card): card is PublicDeckCard => card !== null);
  const allCards = (payload.all_cards_flat ?? []).map(mapDeckCard).filter((card): card is PublicDeckCard => card !== null);
  const cardCount = payload.stats?.total_cards ?? allCards.reduce((sum, card) => sum + card.quantity, 0);
  const showcaseSummary: PublicDeckSummary = {
    id: payload.id,
    name: payload.name,
    format: payload.format ?? undefined,
    cardCount,
    commanderName: commander[0]?.name ?? null,
    createdAt: payload.created_at ?? undefined
  };

  if (!isPublicDeckShowcase(showcaseSummary)) {
    return null;
  }

  return {
    id: payload.id,
    name: payload.name,
    format: payload.format ?? undefined,
    description: payload.description ?? undefined,
    createdAt: payload.created_at ?? undefined,
    ownerUsername: payload.owner_username ?? undefined,
    stats: payload.stats,
    commander,
    allCards
  };
}

export async function loadPublicUserProfile(id: string): Promise<PublicUserProfile | null> {
  const baseUrl = getServerBaseUrl();
  const payload = await fetchJson<PublicUserProfileResponse>(baseUrl, `/community/users/${encodeURIComponent(id)}`);
  const user = payload?.user;

  if (!user?.id) {
    return null;
  }

  return {
    id: user.id,
    username: user.username ?? undefined,
    displayName: user.display_name ?? undefined,
    avatarUrl: user.avatar_url ?? undefined,
    followerCount: user.follower_count,
    followingCount: user.following_count,
    publicDeckCount: user.public_deck_count,
    publicDecks: (payload?.public_decks ?? []).map(mapDeckSummary).filter((deck): deck is PublicDeckSummary => deck !== null)
  };
}
