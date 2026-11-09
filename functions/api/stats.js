// functions/api/stats.js
import { jsonResponse } from "../_utils.js";

export async function onRequest(context) {
  const { env } = context;
  const wa = env?.CONTACT_WA || "6282197014242";

  return jsonResponse({
    visitors: 248,
    members: 86,
    vip: 45,
    free_limit: 5,
    wa: wa,
    plans: [
      { d: 1, label: "1 Hari", price: 10000, final: 10000 },
      { d: 7, label: "1 Minggu", price: 25000, final: 25000 },
      { d: 30, label: "1 Bulan", price: 50000, final: 50000 },
    ],
    promo: null,
    maintenance: {
      on: false,
      msg: "Website sedang maintenance. Silakan kembali lagi nanti.",
    },
  });
}
