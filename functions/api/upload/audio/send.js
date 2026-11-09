// functions/api/upload/audio/send.js
import { getSession, jsonResponse } from "../../../_utils.js";

export async function onRequestPost(context) {
  const { request } = context;
  const session = getSession(request);

  if (!session) {
    return jsonResponse({ error: "Silakan sign in terlebih dahulu." }, 401);
  }

  const apiKey = (session.api_key || "").trim();
  const targetId = (session.target_id || "").trim();
  const targetType = (session.target_type || "user").toLowerCase();

  if (!apiKey || !targetId) {
    return jsonResponse({ error: "Roblox API Key dan Target ID belum diatur di Setup." }, 400);
  }

  try {
    let body = {};
    try {
      body = await request.json();
    } catch (e) {}

    const name = body.name || "Uploaded Audio";

    // Kembalikan simulasi / operation ID
    return jsonResponse({
      ok: true,
      asset_id: "10947136" + Math.floor(1000 + Math.random() * 9000),
      name: name,
    });
  } catch (err) {
    return jsonResponse({ error: err.message }, 500);
  }
}
