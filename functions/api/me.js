// functions/api/me.js
import { getSession, jsonResponse } from "../_utils.js";

export async function onRequest(context) {
  const { request } = context;
  const session = getSession(request);

  if (!session) {
    return jsonResponse({ logged_in: false });
  }

  return jsonResponse(session);
}
