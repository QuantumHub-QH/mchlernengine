// functions/api/process.js
import { getSession, jsonResponse } from "../_utils.js";

// Deteksi otomatis tipe file berdasarkan byte signature
function detectAssetType(bytes) {
  if (bytes.length >= 4) {
    // PNG: 89 50 4E 47
    if (bytes[0] === 0x89 && bytes[1] === 0x50 && bytes[2] === 0x4e && bytes[3] === 0x47) {
      return { type: "Decal", ext: "png", mime: "image/png" };
    }
    // JPEG: FF D8 FF
    if (bytes[0] === 0xff && bytes[1] === 0xd8 && bytes[2] === 0xff) {
      return { type: "Decal", ext: "jpg", mime: "image/jpeg" };
    }
    // OGG: 4F 67 67 53
    if (bytes[0] === 0x4f && bytes[1] === 0x67 && bytes[2] === 0x67 && bytes[3] === 0x53) {
      return { type: "Audio", ext: "ogg", mime: "audio/ogg" };
    }
    // MP3 (ID3): 49 44 33
    if (bytes[0] === 0x49 && bytes[1] === 0x44 && bytes[2] === 0x33) {
      return { type: "Audio", ext: "mp3", mime: "audio/mpeg" };
    }
  }

  // Model RBXM / XML
  const textSample = new TextDecoder().decode(bytes.slice(0, 100));
  if (textSample.includes("<roblox") || textSample.includes("ROBLOX")) {
    return { type: "Model", ext: "rbxm", mime: "application/octet-stream" };
  }

  return { type: "Model", ext: "rbxm", mime: "application/octet-stream" };
}

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
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const { asset_ids, upload, name, asset_type } = body;
  const ids = (String(asset_ids).match(/\d+/g) || []).filter((x) => x.length >= 5 && x.length <= 19);

  if (!ids.length) {
    return jsonResponse({ error: "Tidak ada Asset ID yang valid." }, 400);
  }

  const apiKey = (session.api_key || "").trim();
  const targetId = (session.target_id || "").trim();
  const targetType = (session.target_type || "user").toLowerCase();

  if (upload && (!apiKey || !targetId)) {
    return jsonResponse({
      error: "Roblox API Key dan Target ID belum diatur di menu Setup.",
    }, 400);
  }

  const results = [];

  for (const id of ids) {
    try {
      // 1. Download asset dari CDN Roblox
      const cdnUrl = `https://assetdelivery.roblox.com/v1/asset/?id=${id}`;
      const assetRes = await fetch(cdnUrl, {
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Roblox/OpenCloud",
        },
      });

      if (!assetRes.ok) {
        results.push({
          id,
          ok: false,
          error: `Gagal mengunduh asset dari Roblox (HTTP ${assetRes.status})`,
        });
        continue;
      }

      const buffer = await assetRes.arrayBuffer();
      const bytes = new Uint8Array(buffer);

      if (bytes.length === 0) {
        results.push({
          id,
          ok: false,
          error: "Asset kosong atau tidak ditemukan.",
        });
        continue;
      }

      // Deteksi tipe asset
      const detected = detectAssetType(bytes);
      const finalType = (asset_type && asset_type !== "auto") ? asset_type : detected.type;
      const displayName = name ? name.trim() : `Asset_${id}`;

      // Jika hanya download/cek (upload = false)
      if (!upload) {
        results.push({
          id,
          ok: true,
          new_id: "",
          name: displayName,
          type: finalType,
        });
        continue;
      }

      // 2. Upload ke Roblox via Open Cloud API
      const formData = new FormData();
      const meta = {
        assetType: finalType,
        displayName: displayName,
        description: "Reuploaded via SPOOFER AND REUPLOAD ASET ID",
        creationContext: {
          creator: {
            [targetType === "group" ? "groupId" : "userId"]: targetId,
          },
        },
      };

      formData.append("request", JSON.stringify(meta));
      formData.append(
        "fileContent",
        new Blob([buffer], { type: detected.mime }),
        `asset_${id}.${detected.ext}`
      );

      const uploadRes = await fetch("https://apis.roblox.com/assets/v1/assets", {
        method: "POST",
        headers: {
          "x-api-key": apiKey,
        },
        body: formData,
      });

      const upJson = await uploadRes.json();

      if (!uploadRes.ok) {
        results.push({
          id,
          ok: false,
          error: upJson.message || upJson.error || `Error Roblox (${uploadRes.status})`,
          name: displayName,
          type: finalType,
        });
        continue;
      }

      // Tangani respon Roblox Open Cloud
      let newAssetId = upJson.response?.assetId || upJson.assetId;
      let op = upJson.path || "";

      if (newAssetId) {
        results.push({
          id,
          ok: true,
          new_id: String(newAssetId),
          name: displayName,
          type: finalType,
        });
      } else if (op) {
        results.push({
          id,
          ok: true,
          new_id: "pending",
          op: op,
          name: displayName,
          type: finalType,
        });
      } else {
        results.push({
          id,
          ok: true,
          new_id: "",
          name: displayName,
          type: finalType,
        });
      }
    } catch (err) {
      results.push({
        id,
        ok: false,
        error: err.message,
      });
    }
  }

  return jsonResponse({ results });
}
