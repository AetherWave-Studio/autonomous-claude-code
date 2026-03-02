#!/usr/bin/env node
/**
 * Discord Bridge for Claude Code
 * Listens to a Discord channel and writes incoming messages to a local inbox file.
 * Claude Code's PostToolUse hook reads this file to surface Discord messages.
 *
 * Single-instance: writes a heartbeat file every 10 seconds.
 * start.sh checks heartbeat age to prevent spawning duplicate bridges.
 *
 * Setup:
 *   1. npm install discord.js (in this directory)
 *   2. Set environment variables (or create .env):
 *      - DISCORD_BOT_TOKEN: Your Discord bot token
 *      - DISCORD_CHANNEL_ID: Channel to listen on (#claude-code-chat)
 *      - DISCORD_USER_ID: Your Discord user ID (messages from others are ignored)
 *   3. Run: node bridge.js
 *   4. Or let start.sh manage it via the PreToolUse hook
 */

const { Client, GatewayIntentBits, Partials } = require('discord.js');
const fs = require('fs');
const path = require('path');

const HOME = process.env.HOME || process.env.USERPROFILE;

const CONFIG = {
  token: process.env.DISCORD_BOT_TOKEN,
  channelId: process.env.DISCORD_CHANNEL_ID,
  allowedUserId: process.env.DISCORD_USER_ID,
  inboxPath: path.join(HOME, '.claude', 'discord-inbox.jsonl'),
  pidPath: path.join(__dirname, 'bridge.pid'),
  heartbeatPath: path.join(__dirname, 'bridge.heartbeat'),
};

// Validate required config
if (!CONFIG.token || !CONFIG.channelId || !CONFIG.allowedUserId) {
  console.error('[bridge] Missing required environment variables:');
  if (!CONFIG.token) console.error('  - DISCORD_BOT_TOKEN');
  if (!CONFIG.channelId) console.error('  - DISCORD_CHANNEL_ID');
  if (!CONFIG.allowedUserId) console.error('  - DISCORD_USER_ID');
  console.error('[bridge] Set these in your environment or .env file');
  process.exit(1);
}

// Write PID file
fs.writeFileSync(CONFIG.pidPath, String(process.pid));

// Write heartbeat every 10 seconds so start.sh can detect a live bridge
function writeHeartbeat() {
  fs.writeFileSync(CONFIG.heartbeatPath, String(Math.floor(Date.now() / 1000)));
}
writeHeartbeat();
const heartbeatInterval = setInterval(writeHeartbeat, 10000);

const client = new Client({
  intents: [
    GatewayIntentBits.Guilds,
    GatewayIntentBits.GuildMessages,
    GatewayIntentBits.MessageContent,
  ],
  partials: [Partials.Message],
});

// Track recent message IDs to prevent duplicates
const recentMessageIds = new Set();
const MAX_TRACKED = 100;

client.once('clientReady', () => {
  console.log(`[bridge] Connected as ${client.user.tag}`);
  console.log(`[bridge] Listening on channel ${CONFIG.channelId}`);
  console.log(`[bridge] Inbox: ${CONFIG.inboxPath}`);
});

client.on('messageCreate', (message) => {
  if (message.channel.id !== CONFIG.channelId) return;
  if (message.author.bot) return;
  if (message.author.id !== CONFIG.allowedUserId) return;

  // Deduplicate — skip if we've already seen this message ID
  if (recentMessageIds.has(message.id)) return;
  recentMessageIds.add(message.id);
  if (recentMessageIds.size > MAX_TRACKED) {
    const first = recentMessageIds.values().next().value;
    recentMessageIds.delete(first);
  }

  const entry = {
    id: message.id,
    author: message.author.username,
    content: message.content.substring(0, 2000),
    timestamp: message.createdAt.toISOString(),
    attachments: message.attachments.map(a => a.url),
  };

  fs.appendFileSync(CONFIG.inboxPath, JSON.stringify(entry) + '\n');
  console.log(`[bridge] Queued: ${entry.content.substring(0, 80)}`);
});

function shutdown(signal) {
  console.log(`[bridge] ${signal}, shutting down...`);
  clearInterval(heartbeatInterval);
  client.destroy();
  try { fs.unlinkSync(CONFIG.pidPath); } catch (e) { /* ignore */ }
  try { fs.unlinkSync(CONFIG.heartbeatPath); } catch (e) { /* ignore */ }
  process.exit(0);
}

process.on('SIGINT', shutdown.bind(null, 'SIGINT'));
process.on('SIGTERM', shutdown.bind(null, 'SIGTERM'));

client.login(CONFIG.token).catch((err) => {
  console.error(`[bridge] Login failed:`, err.message);
  process.exit(1);
});
