# CS2 Discord Bot — Match Results via REST API (no scraping)

Minimal **Discord.js** bot that posts recent **Counter-Strike 2** match scores using the **[GGScore CS2 Match Data API](https://ggscore.net)** (`GET /api/v2/matches` + `X-API-Key`).

Use this if you want a **CS2 Discord bot** for `/results` without maintaining HTML scrapers or fragile selectors.

[![GGScore](https://img.shields.io/badge/API-ggscore.net-orange)](https://ggscore.net)
[![Docs](https://img.shields.io/badge/docs-quickstart-blue)](https://ggscore.net/docs)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

## Features

- Slash command **`/results`** — latest played CS2 matches (teams + series score)
- Auth via **`CS2_MATCH_API_KEY`** (same key as the GGScore cabinet)
- **120s response cache** — respects Free-tier rate limits
- Configurable **`CS2_MATCH_API_BASE`** (default `https://api.ggscore.net`)

## Related

| Resource | Link |
|----------|------|
| Get Free API key | https://ggscore.net |
| API docs | https://ggscore.net/docs |
| Full Discord guide | https://ggscore.net/blog/cs2-discord-bot-api-guide |
| CS2 API overview | https://ggscore.net/guides/cs2-match-data-api |
| Telegram twin | [telegram-cs2-bot](https://github.com/ggscore-org/telegram-cs2-bot) |
| Org | [ggscore-org](https://github.com/ggscore-org) |

## Setup

```bash
git clone https://github.com/ggscore-org/discord-cs2-bot.git
cd discord-cs2-bot
cp .env.example .env
# DISCORD_TOKEN + CS2_MATCH_API_KEY (+ optional DISCORD_APP_ID)
npm install
npm start
# or: npm run register   # register /results globally
```

Invite the bot with the `applications.commands` scope. In a guild, run `/results`.

## Environment

| Variable | Required | Default |
|----------|----------|---------|
| `DISCORD_TOKEN` | yes | — |
| `DISCORD_APP_ID` | for `npm run register` | — |
| `CS2_MATCH_API_KEY` | yes | cabinet `X-API-Key` |
| `CS2_MATCH_API_BASE` | no | `https://api.ggscore.net` |

## API used

```http
GET https://api.ggscore.net/api/v2/matches?page=1&limit=5
X-API-Key: <your key>
```

Response shape: `{ "data": [ { "team_won", "team_lose", "score_won", "score_lose", "event", "played_at", ... } ], "meta": { ... } }`.

## Rate limits

Free plans are limited (prototype quotas). This bot caches for **120 seconds**. Do not poll in a tight loop without upgrading and a longer TTL.

## License

MIT — see [LICENSE](LICENSE).
