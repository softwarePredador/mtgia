const DEFAULT_MANALOOM_API_BASE_URL = "https://evolution-cartinhas.2ta7qx.easypanel.host";
const SERVER_REVALIDATE_SECONDS = 300;

export type PublicSharedReport = {
  id: string;
  deckId?: string;
  title: string;
  description?: string;
  payload: Record<string, unknown>;
  createdAt?: string;
  updatedAt?: string;
  expiresAt?: string | null;
};

type PublicSharedReportResponse = {
  id?: string;
  deck_id?: string | null;
  title?: string;
  description?: string | null;
  payload?: Record<string, unknown> | null;
  created_at?: string | null;
  updated_at?: string | null;
  expires_at?: string | null;
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

export async function loadPublicReport(id: string): Promise<PublicSharedReport | null> {
  const baseUrl = getServerBaseUrl();
  const payload = await fetchJson<PublicSharedReportResponse>(baseUrl, `/reports/${encodeURIComponent(id)}`);

  if (!payload?.id || !payload.title || !payload.payload) {
    return null;
  }

  return {
    id: payload.id,
    deckId: payload.deck_id ?? undefined,
    title: payload.title,
    description: payload.description ?? undefined,
    payload: payload.payload,
    createdAt: payload.created_at ?? undefined,
    updatedAt: payload.updated_at ?? undefined,
    expiresAt: payload.expires_at ?? undefined
  };
}
