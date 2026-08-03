# Discord CS2 match bot (GGScore API)

Minimal [discord.js](https://discord.js.org/) bot that posts recent **played** CS2 matches via the GGScore REST API — no HTML scraping.

- Docs: https://ggscore.net/docs  
- Guide: https://ggscore.net/blog/cs2-discord-bot-api-guide  
- Get a key: https://ggscore.net (Free = prototype quotas; cache aggressively)

## Setup

```bash
cp .env.example .env
# set DISCORD_TOKEN + CS2_MATCH_API_KEY
npm install
npm start
```

Invite the bot with `applications.commands` scope. In a guild, run `/results`.

## Env

| Variable | Required | Default |
|----------|----------|---------|
| `DISCORD_TOKEN` | yes | — |
| `CS2_MATCH_API_KEY` | yes | — (cabinet `X-API-Key`) |
| `CS2_MATCH_API_BASE` | no | `https://api.ggscore.net` |

## Rate limits

Free plans are tight (e.g. a few requests/day). This bot caches the last matches response for **120s**. Do not add a polling loop without upgrading and a longer TTL.

## License

MIT
