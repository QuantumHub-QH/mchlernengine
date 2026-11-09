// functions/api/upload/audio/prepare.js
import { getSession, jsonResponse } from "../../../_utils.js";

export async function onRequestPost(context) {
  const { request } = context;
  const session = getSession(request);

  if (!session) {
    return jsonResponse({ error: "Silakan sign in terlebih dahulu." }, 401);
  }

  try {
    const formData = await request.formData();
    const file = formData.get("file");

    if (!file) {
      return jsonResponse({ error: "File audio tidak ditemukan." }, 400);
    }

    return jsonResponse({
      name: file.name,
      file: file.name,
      size: file.size,
      dur_src: 180,
      dur_out: 180,
      factor: 1,
      speed: null,
    });
  } catch (err) {
    return jsonResponse({ error: err.message }, 500);
  }
}
