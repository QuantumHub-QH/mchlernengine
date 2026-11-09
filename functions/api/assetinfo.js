// functions/api/assetinfo.js
import { getSession, jsonResponse } from "../_utils.js";

const ASSET_TYPE_MAP = {
  1: "Image",
  2: "T-Shirt",
  3: "Audio",
  4: "Mesh",
  5: "Lua",
  9: "Place",
  10: "Model",
  11: "Shirt",
  12: "Pants",
  13: "Decal",
  24: "Animation",
  38: "Plugin",
  40: "MeshPart",
};

export async function onRequestGet(context) {
  const { request } = context;
  const session = getSession(request);

  if (!session) {
    return jsonResponse({ error: "Silakan sign in terlebih dahulu." }, 401);
  }

  const url = new URL(request.url);
  const id = url.searchParams.get("id");

  if (!id) {
    return jsonResponse({ error: "ID asset diperlukan." }, 400);
  }

  try {
    const res = await fetch(`https://economy.roblox.com/v2/assets/${id}/details`, {
      headers: {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Roblox/OpenCloud",
      },
    });

    if (res.ok) {
      const data = await res.json();
      const typeName = ASSET_TYPE_MAP[data.AssetTypeId] || data.AssetType || "Asset";
      return jsonResponse({
        name: data.Name || `Asset ${id}`,
        type: typeName,
        creator: data.Creator?.Name || "Roblox",
      });
    }

    return jsonResponse({
      name: `Asset ${id}`,
      type: "Asset",
      creator: "Roblox",
    });
  } catch (err) {
    return jsonResponse({
      name: `Asset ${id}`,
      type: "Asset",
      creator: "Roblox",
    });
  }
}
