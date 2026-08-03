import "dotenv/config";

const API_BASE = (process.env.CS2_MATCH_API_BASE || "https://api.ggscore.net").replace(
  /\/$/,
  "",
);
const API_KEY = process.env.CS2_MATCH_API_KEY;

const cache = { at: 0, payload: null };
const CACHE_MS = 120_000;

function teamTitle(team) {
  if (!team) return "?";
  if (typeof team === "string") return team;
  return team.title || team.name || "?";
}

/**
 * @returns {Promise<{ data: object[], meta?: object }>}
 */
export async function fetchPlayedMatches(limit = 5) {
  if (!API_KEY) {
    throw new Error("CS2_MATCH_API_KEY is not set");
  }
  const now = Date.now();
  if (cache.payload && now - cache.at < CACHE_MS) {
    return cache.payload;
  }
  const url = `${API_BASE}/api/v2/matches?page=1&limit=${limit}`;
  const res = await fetch(url, {
    headers: { "X-API-Key": API_KEY },
  });
  if (res.status === 401) {
    throw new Error("API 401 — check CS2_MATCH_API_KEY");
  }
  if (res.status === 429) {
    throw new Error("API 429 — rate limited; wait or upgrade plan / cache longer");
  }
  if (!res.ok) {
    throw new Error(`API ${res.status}`);
  }
  const body = await res.json();
  cache.at = now;
  cache.payload = body;
  return body;
}

export function formatPlayedLines(body) {
  const rows = Array.isArray(body?.data) ? body.data : [];
  if (!rows.length) return ["No matches returned."];
  return rows.slice(0, 5).map((m) => {
    const won = teamTitle(m.team_won);
    const lose = teamTitle(m.team_lose);
    const sw = m.score_won ?? "?";
    const sl = m.score_lose ?? "?";
    const event = m.event?.title || "";
    const when = m.played_at ? m.played_at.slice(0, 10) : "";
    const tail = [event, when].filter(Boolean).join(" · ");
    return `**${won}** ${sw}:${sl} **${lose}**${tail ? ` — ${tail}` : ""}`;
  });
}
