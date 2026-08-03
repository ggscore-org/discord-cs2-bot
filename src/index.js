import "dotenv/config";
import {
  Client,
  GatewayIntentBits,
  REST,
  Routes,
  SlashCommandBuilder,
} from "discord.js";
import { fetchPlayedMatches, formatPlayedLines } from "./ggscore.js";

const token = process.env.DISCORD_TOKEN;
if (!token) {
  console.error("DISCORD_TOKEN is required");
  process.exit(1);
}

const resultsCommand = new SlashCommandBuilder()
  .setName("results")
  .setDescription("Recent CS2 match results (GGScore API)");

const client = new Client({ intents: [GatewayIntentBits.Guilds] });

client.once("ready", () => {
  console.log(`Logged in as ${client.user.tag}`);
});

client.on("interactionCreate", async (interaction) => {
  if (!interaction.isChatInputCommand()) return;
  if (interaction.commandName !== "results") return;

  await interaction.deferReply();
  try {
    const body = await fetchPlayedMatches(5);
    const lines = formatPlayedLines(body);
    await interaction.editReply({ content: lines.join("\n") });
  } catch (err) {
    const msg = err instanceof Error ? err.message : String(err);
    await interaction.editReply({ content: `Could not fetch matches: ${msg}` });
  }
});

async function registerCommands() {
  const appId = process.env.DISCORD_APP_ID || client.user?.id;
  if (!appId) {
    console.warn("Skip command register: set DISCORD_APP_ID or wait for ready");
    return;
  }
  const rest = new REST({ version: "10" }).setToken(token);
  await rest.put(Routes.applicationCommands(appId), {
    body: [resultsCommand.toJSON()],
  });
  console.log("Registered /results");
}

client.login(token).then(async () => {
  try {
    await registerCommands();
  } catch (e) {
    console.warn("Command registration failed:", e.message || e);
    console.warn("Run: DISCORD_APP_ID=... npm run register");
  }
});
