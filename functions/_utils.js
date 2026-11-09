// functions/_utils.js
// Utility helpers for Cloudflare Pages Functions

export function parseCookies(request) {
  const header = request.headers.get("Cookie") || "";
  const cookies = {};
  header.split(";").forEach((pair) => {
    const [key, ...vals] = pair.trim().split("=");
    if (key) cookies[key] = decodeURIComponent(vals.join("="));
  });
  return cookies;
}

export function getSession(request) {
  const cookies = parseCookies(request);
  if (!cookies.spoofer_session) return null;
  try {
    const decoded = atob(cookies.spoofer_session);
    return JSON.parse(decoded);
  } catch (err) {
    return null;
  }
}

export function createSessionCookie(data) {
  const encoded = btoa(JSON.stringify(data));
  return `spoofer_session=${encodeURIComponent(encoded)}; Path=/; HttpOnly; SameSite=Lax; Max-Age=2592000`;
}

export function clearSessionCookie() {
  return "spoofer_session=; Path=/; HttpOnly; SameSite=Lax; Max-Age=0";
}

export function jsonResponse(data, status = 200, extraHeaders = {}) {
  return new Response(JSON.stringify(data), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...extraHeaders,
    },
  });
}
