// functions/auth/discord.js
import { createSessionCookie } from "../_utils.js";

export async function onRequest(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  const clientId = env?.DISCORD_CLIENT_ID;

  // Jika env DISCORD_CLIENT_ID belum diset di Cloudflare,
  // langsung otomatis login sebagai Owner/VIP (Quick Demo Mode)
  if (!clientId) {
    const defaultUser = {
      logged_in: true,
      id: "100000000000000001",
      name: "Owner / Roblox Developer",
      avatar: null,
      vip: true,
      vip_days: null,
      limit: 999999,
      used: 0,
      owner: true,
      target_type: "user",
      target_id: "",
      api_key: "",
    };

    return new Response(null, {
      status: 302,
      headers: {
        Location: "/#home",
        "Set-Cookie": createSessionCookie(defaultUser),
      },
    });
  }

  // Jika DISCORD_CLIENT_ID sudah diset, gunakan Discord OAuth2 resmi
  const redirectUri = `${url.origin}/auth/callback`;
  const discordUrl = `https://discord.com/oauth2/authorize?client_id=${clientId}&response_type=code&redirect_uri=${encodeURIComponent(
    redirectUri
  )}&scope=identify`;

  return Response.redirect(discordUrl, 302);
}
