// functions/api/setup.js
import { getSession, createSessionCookie, jsonResponse } from "../_utils.js";

export async function onRequestPost(context) {
  const { request } = context;
  const session = getSession(request);

  if (!session) {
    return jsonResponse({ error: "Silakan sign in dengan Discord terlebih dahulu." }, 401);
  }

  let body = {};
  try {
    body = await request.json();
  } catch (err) {
    return jsonResponse({ error: "Payload JSON tidak valid." }, 400);
  }

  const { api_key, target_type, target_id } = body;

  session.api_key = (api_key || "").trim();
  session.target_type = (target_type || "user").toLowerCase();
  session.target_id = (target_id || "").trim();

  return jsonResponse(
    { ok: true, message: "Konfigurasi Roblox berhasil disimpan!" },
    200,
    { "Set-Cookie": createSessionCookie(session) }
  );
}
