// functions/api/logout.js
import { clearSessionCookie, jsonResponse } from "../_utils.js";

export async function onRequest(context) {
  return jsonResponse(
    { ok: true },
    200,
    { "Set-Cookie": clearSessionCookie() }
  );
}
