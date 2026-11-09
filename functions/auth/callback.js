// functions/auth/callback.js
import { createSessionCookie } from "../_utils.js";

export async function onRequest(context) {
  const { request, env } = context;
  const url = new URL(request.url);
  const code = url.searchParams.get("code");

  if (!code) {
    return Response.redirect(`${url.origin}/#home`, 302);
  }

  const clientId = env?.DISCORD_CLIENT_ID;
  const clientSecret = env?.DISCORD_CLIENT_SECRET;
  const redirectUri = `${url.origin}/auth/callback`;

  try {
    // 1. Tukar auth code dengan access token
    const tokenResp = await fetch("https://discord.com/api/oauth2/token", {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: new URLSearchParams({
        client_id: clientId,
        client_secret: clientSecret,
        grant_type: "authorization_code",
        code,
        redirect_uri: redirectUri,
      }),
    });

    const tokenData = await tokenResp.json();
    if (!tokenData.access_token) {
      return new Response("Login Discord gagal: " + JSON.stringify(tokenData), {
        status: 400,
      });
    }

    // 2. Ambil data profil Discord
    const userResp = await fetch("https://discord.com/api/users/@me", {
      headers: {
        Authorization: `Bearer ${tokenData.access_token}`,
      },
    });

    const userData = await userResp.json();

    let avatarUrl = null;
    if (userData.avatar) {
      avatarUrl = `https://cdn.discordapp.com/avatars/${userData.id}/${userData.avatar}.png`;
    }

    const sessionData = {
      logged_in: true,
      id: userData.id,
      name: userData.global_name || userData.username,
      avatar: avatarUrl,
      vip: true, // VIP diaktifkan
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
        "Set-Cookie": createSessionCookie(sessionData),
      },
    });
  } catch (err) {
    return new Response("Error autentikasi Discord: " + err.message, {
      status: 500,
    });
  }
}
