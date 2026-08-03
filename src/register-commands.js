import "dotenv/config";
import { REST, Routes, SlashCommandBuilder } from "discord.js";

const token = process.env.DISCORD_TOKEN;
const appId = process.env.DISCORD_APP_ID;
if (!token || !appId) {
  console.error("DISCORD_TOKEN and DISCORD_APP_ID required");
  process.exit(1);
}

const body = [
  new SlashCommandBuilder()
    .setName("results")
    .setDescription("Recent CS2 match results (GGScore API)")
    .toJSON(),
];

const rest = new REST({ version: "10" }).setToken(token);
await rest.put(Routes.applicationCommands(appId), { body });
console.log("Registered global /results");
