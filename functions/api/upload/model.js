// functions/api/upload/model.js
import { getSession, jsonResponse } from "../../_utils.js";

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
    const formData = await request.formData();
    const file = formData.get("file");
    const name = formData.get("name") || file?.name || "Uploaded Model";

    if (!file) {
      return jsonResponse({ error: "File model (.rbxm) tidak ditemukan." }, 400);
    }

    const robloxForm = new FormData();
    const meta = {
      assetType: "Model",
      displayName: String(name).slice(0, 50),
      description: "Uploaded via SPOOFER AND REUPLOAD ASET ID",
      creationContext: {
        creator: {
          [targetType === "group" ? "groupId" : "userId"]: targetId,
        },
      },
    };

    robloxForm.append("request", JSON.stringify(meta));
    robloxForm.append("fileContent", file, file.name || "model.rbxm");

    const upRes = await fetch("https://apis.roblox.com/assets/v1/assets", {
      method: "POST",
      headers: { "x-api-key": apiKey },
      body: robloxForm,
    });

    const upJson = await upRes.json();
    if (!upRes.ok) {
      return jsonResponse({ error: upJson.message || "Gagal upload model ke Roblox." }, upRes.status);
    }

    const assetId = upJson.response?.assetId || upJson.assetId;
    return jsonResponse({ asset_id: String(assetId || "pending") });
  } catch (err) {
    return jsonResponse({ error: err.message }, 500);
  }
}
