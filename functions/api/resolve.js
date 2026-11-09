// functions/api/resolve.js
import { getSession, jsonResponse } from "../_utils.js";

export async function onRequestPost(context) {
  const { request } = context;
  const session = getSession(request);

  if (!session) {
    return jsonResponse({ error: "Silakan sign in terlebih dahulu." }, 401);
  }

  const apiKey = (session.api_key || "").trim();
  if (!apiKey) {
    return jsonResponse({ error: "API Key belum diatur." }, 400);
  }

  let body = {};
  try {
    body = await request.json();
  } catch (err) {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const items = body.items || [];
  const results = [];

  for (const item of items) {
    const { id, op } = item;
    if (!op) {
      results.push({ id, state: "fail", error: "Operation path kosong." });
      continue;
    }

    try {
      // Periksa status operasi di Roblox Open Cloud
      const opUrl = op.startsWith("http")
        ? op
        : `https://apis.roblox.com/assets/v1/${op.replace(/^\/+/, "")}`;

      const res = await fetch(opUrl, {
        headers: {
          "x-api-key": apiKey,
        },
      });

      const data = await res.json();

      if (!res.ok) {
        results.push({
          id,
          state: "fail",
          error: data.message || "Gagal mengambil status operasi dari Roblox.",
        });
        continue;
      }

      if (data.done) {
        if (data.error) {
          results.push({
            id,
            state: "fail",
            error: data.error.message || "Gagal diproses oleh Roblox.",
          });
        } else {
          const newId = data.response?.assetId || data.assetId;
          results.push({
            id,
            state: "done",
            new_id: String(newId),
          });
        }
      } else {
        // Masih pending
        results.push({
          id,
          state: "pending",
        });
      }
    } catch (err) {
      results.push({
        id,
        state: "fail",
        error: err.message,
      });
    }
  }

  return jsonResponse({ results });
}
