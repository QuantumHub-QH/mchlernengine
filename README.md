# 🚀 SPOOFER AND REUPLOAD ASET ID

Aplikasi web modern untuk **Spoofing, Download & Re-upload Asset Roblox** (Decal, Audio, Model .rbxm, Animasi) langsung ke akun Roblox milik Anda atau Group via **Roblox Open Cloud API**.

Dilengkapi dengan sistem autentikasi **Discord OAuth2**, antrian spoof massal, dan kompatibilitas serverless **Cloudflare Pages**.

---

## ⚡ Fitur Utama
* **Spoof Asset Massal**: Masukkan puluhan Asset ID sekaligus, sistem mengunduh dari CDN Roblox dan mengunggah ulang ke akun Anda dengan Asset ID baru.
* **Roblox Open Cloud API**: Menggunakan jalur resmi Roblox (Aman dari ban cookie `.ROBLOSECURITY`).
* **Upload Langsung**: Dukungan upload Audio, Decal/Gambar, dan Model `.rbxm`.
* **Login Discord OAuth2**: Hanya menggunakan login Discord (tanpa formulir Gmail / email).
* **Cloudflare Pages Ready**: Serverless backend di `functions/` (100% gratis selamanya tanpa butuh server/VPS).

---

## 🌐 Cara Deploy ke Cloudflare Pages (100% Gratis)

1. Buka dashboard [Cloudflare](https://dash.cloudflare.com/).
2. Masuk ke menu **Workers & Pages** > **Create application** > Tab **Pages**.
3. Pilih **Connect to Git** dan hubungkan repository GitHub ini (`mchlernengine`).
4. Atur pengaturan build:
   * **Project name**: `spoofer-and-reupload-aset-id` (atau bebas)
   * **Framework preset**: `None`
   * **Build command**: *(kosongkan)*
   * **Build output directory**: `/` (atau kosongkan)
5. Klik **Save and Deploy**! Website Anda akan langsung aktif dengan domain `.pages.dev`.

### (Opsional) Menghubungkan Discord OAuth2 Resmi:
Di dashboard Cloudflare Pages:
1. Buka project Anda > **Settings** > **Environment variables**.
2. Tambahkan variable:
   * `DISCORD_CLIENT_ID` = `Client ID dari Discord Developer Portal`
   * `DISCORD_CLIENT_SECRET` = `Client Secret dari Discord Developer Portal`
3. Di [Discord Developer Portal](https://discord.com/developers/applications):
   * Tambahkan Redirect URL: `https://<domain-kamu>.pages.dev/auth/callback`

> **Note**: Jika variabel Discord di atas belum diset, website akan otomatis mengizinkan **Demo Instant Login** saat tombol *Sign in dengan Discord* diklik.

---

## 💻 Cara Menjalankan Lokal di Termux / Komputer

Jika ingin mencoba di HP/Termux sebelum atau saat pengembangan:

```bash
python3 server.py
```

Buka browser dan akses: `http://localhost:3000`

---

## 🔑 Cara Penggunaan di Web
1. Klik **Sign in dengan Discord**.
2. Buka menu **Setup Roblox**:
   * Buka [create.roblox.com/dashboard/credentials](https://create.roblox.com/dashboard/credentials).
   * Buat API Key baru dengan izin **Assets (Read & Write)**.
   * Masukkan API Key dan User ID / Group ID Anda di menu Setup, lalu simpan.
3. Buka menu **Spoof Asset**:
   * Tempel Asset ID Roblox lama yang ingin Anda spoof.
   * Klik **Mulai Proses** dan tunggu hingga ID baru keluar!
