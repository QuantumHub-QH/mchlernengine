#!/usr/bin/env python3
"""
SPOOFER AND REUPLOAD ASET ID - Local Development Server
Menjalankan backend lokal untuk pengujian di Termux sebelum atau sesudah deploy ke Cloudflare.
"""

import os
import json
import base64
import requests
from flask import Flask, request, jsonify, redirect, send_from_directory, make_response

app = Flask(__name__, static_folder='static', static_url_path='/static')
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

SESSION_COOKIE = 'spoofer_session'

def get_session():
    cookie = request.cookies.get(SESSION_COOKIE)
    if not cookie:
        return None
    try:
        raw = base64.b64decode(cookie).decode('utf-8')
        return json.loads(raw)
    except Exception:
        return None

def set_session_cookie(response, data):
    raw = base64.b64encode(json.dumps(data).encode('utf-8')).decode('utf-8')
    response.set_cookie(SESSION_COOKIE, raw, path='/', max_age=30*86400, httponly=True, samesite='Lax')
    return response

@app.route('/')
def index():
    return send_from_directory(BASE_DIR, 'index.html')

@app.route('/auth/discord')
def auth_discord():
    discord_client_id = os.environ.get('DISCORD_CLIENT_ID')
    if not discord_client_id:
        # Demo login langsung tanpa setup OAuth
        default_user = {
            'logged_in': True,
            'id': '100000000000000001',
            'name': 'Owner / Roblox Developer',
            'avatar': None,
            'vip': True,
            'vip_days': None,
            'limit': 999999,
            'used': 0,
            'owner': True,
            'target_type': 'user',
            'target_id': '',
            'api_key': ''
        }
        resp = make_response(redirect('/#home'))
        return set_session_cookie(resp, default_user)

    redirect_uri = request.host_url.rstrip('/') + '/auth/callback'
    discord_url = (
        f"https://discord.com/oauth2/authorize?client_id={discord_client_id}"
        f"&response_type=code&redirect_uri={redirect_uri}&scope=identify"
    )
    return redirect(discord_url)

@app.route('/auth/callback')
def auth_callback():
    code = request.args.get('code')
    if not code:
        return redirect('/#home')

    discord_client_id = os.environ.get('DISCORD_CLIENT_ID')
    discord_client_secret = os.environ.get('DISCORD_CLIENT_SECRET')
    redirect_uri = request.host_url.rstrip('/') + '/auth/callback'

    token_resp = requests.post(
        'https://discord.com/api/oauth2/token',
        data={
            'client_id': discord_client_id,
            'client_secret': discord_client_secret,
            'grant_type': 'authorization_code',
            'code': code,
            'redirect_uri': redirect_uri
        },
        headers={'Content-Type': 'application/x-www-form-urlencoded'}
    )
    token_data = token_resp.json()
    access_token = token_data.get('access_token')
    if not access_token:
        return f"Login Discord gagal: {token_data}", 400

    user_resp = requests.get('https://discord.com/api/users/@me', headers={'Authorization': f'Bearer {access_token}'})
    user_data = user_resp.json()

    avatar_url = None
    if user_data.get('avatar'):
        avatar_url = f"https://cdn.discordapp.com/avatars/{user_data['id']}/{user_data['avatar']}.png"

    session = {
        'logged_in': True,
        'id': user_data.get('id'),
        'name': user_data.get('global_name') or user_data.get('username'),
        'avatar': avatar_url,
        'vip': True,
        'vip_days': None,
        'limit': 999999,
        'used': 0,
        'owner': True,
        'target_type': 'user',
        'target_id': '',
        'api_key': ''
    }

    resp = make_response(redirect('/#home'))
    return set_session_cookie(resp, session)

@app.route('/api/me', methods=['GET', 'POST'])
def api_me():
    session = get_session()
    if not session:
        return jsonify({'logged_in': False})
    return jsonify(session)

@app.route('/api/setup', methods=['POST'])
def api_setup():
    session = get_session()
    if not session:
        return jsonify({'error': 'Silakan sign in terlebih dahulu.'}), 401
    
    data = request.get_json(silent=True) or {}
    session['api_key'] = (data.get('api_key') or '').strip()
    session['target_type'] = (data.get('target_type') or 'user').lower()
    session['target_id'] = (data.get('target_id') or '').strip()

    resp = make_response(jsonify({'ok': True, 'message': 'Setup berhasil disimpan!'}))
    return set_session_cookie(resp, session)

@app.route('/api/stats', methods=['GET'])
def api_stats():
    return jsonify({
        'visitors': 248,
        'members': 86,
        'vip': 45,
        'free_limit': 5,
        'wa': '6282197014242',
        'plans': [
            {'d': 1, 'label': '1 Hari', 'price': 10000, 'final': 10000},
            {'d': 7, 'label': '1 Minggu', 'price': 25000, 'final': 25000},
            {'d': 30, 'label': '1 Bulan', 'price': 50000, 'final': 50000}
        ],
        'promo': None,
        'maintenance': {'on': False, 'msg': ''}
    })

@app.route('/api/logout', methods=['GET', 'POST'])
def api_logout():
    resp = make_response(jsonify({'ok': True}))
    resp.set_cookie(SESSION_COOKIE, '', path='/', max_age=0)
    return resp

@app.route('/api/assetinfo', methods=['GET'])
def api_assetinfo():
    asset_id = request.args.get('id')
    if not asset_id:
        return jsonify({'error': 'Asset ID diperlukan'}), 400
    try:
        r = requests.get(f'https://economy.roblox.com/v2/assets/{asset_id}/details', timeout=10)
        if r.ok:
            d = r.json()
            return jsonify({
                'name': d.get('Name', f'Asset {asset_id}'),
                'type': d.get('AssetType', 'Asset'),
                'creator': d.get('Creator', {}).get('Name', 'Roblox')
            })
    except Exception:
        pass
    return jsonify({'name': f'Asset {asset_id}', 'type': 'Asset', 'creator': 'Roblox'})

@app.route('/api/process', methods=['POST'])
def api_process():
    session = get_session()
    if not session:
        return jsonify({'error': 'Silakan sign in terlebih dahulu.'}), 401

    data = request.get_json(silent=True) or {}
    asset_ids_raw = data.get('asset_ids', '')
    upload = data.get('upload', True)
    custom_name = data.get('name', '')
    asset_type = data.get('asset_type', 'auto')

    import re
    ids = [x for x in re.findall(r'\d+', str(asset_ids_raw)) if 5 <= len(x) <= 19]
    if not ids:
        return jsonify({'error': 'Tidak ada Asset ID yang valid'}), 400

    api_key = session.get('api_key', '').strip()
    target_id = session.get('target_id', '').strip()
    target_type = session.get('target_type', 'user').lower()

    if upload and (not api_key or not target_id):
        return jsonify({'error': 'API key dan Target ID belum diatur di menu Setup.'}), 400

    results = []
    for aid in ids:
        try:
            cdn_url = f'https://assetdelivery.roblox.com/v1/asset/?id={aid}'
            down = requests.get(cdn_url, timeout=15)
            if not down.ok:
                results.push({'id': aid, 'ok': False, 'error': f'Gagal unduh (HTTP {down.status_code})'})
                continue

            content = down.content
            # Auto detect type
            mtype = 'Model'
            ext = 'rbxm'
            if content.startswith(b'\x89PNG') or content.startswith(b'\xff\xd8\xff'):
                mtype = 'Decal'
                ext = 'png'
            elif content.startswith(b'OggS') or content.startswith(b'ID3'):
                mtype = 'Audio'
                ext = 'ogg'

            final_type = asset_type if (asset_type and asset_type != 'auto') else mtype
            display_name = custom_name.strip() if custom_name else f"Asset_{aid}"

            if not upload:
                results.append({'id': aid, 'ok': True, 'new_id': '', 'name': display_name, 'type': final_type})
                continue

            meta = {
                'assetType': final_type,
                'displayName': display_name,
                'description': 'Reuploaded via SPOOFER AND REUPLOAD ASET ID',
                'creationContext': {
                    'creator': {
                        ('groupId' if target_type == 'group' else 'userId'): target_id
                    }
                }
            }

            files = {
                'request': (None, json.dumps(meta), 'application/json'),
                'fileContent': (f'asset_{aid}.{ext}', content, 'application/octet-stream')
            }

            up = requests.post(
                'https://apis.roblox.com/assets/v1/assets',
                headers={'x-api-key': api_key},
                files=files,
                timeout=20
            )
            up_json = up.json() if up.headers.get('content-type', '').startswith('application/json') else {}
            if not up.ok:
                results.append({'id': aid, 'ok': False, 'error': up_json.get('message', f'Error HTTP {up.status_code}'), 'name': display_name, 'type': final_type})
                continue

            new_id = up_json.get('response', {}).get('assetId') or up_json.get('assetId')
            op = up_json.get('path', '')
            if new_id:
                results.append({'id': aid, 'ok': True, 'new_id': str(new_id), 'name': display_name, 'type': final_type})
            elif op:
                results.append({'id': aid, 'ok': True, 'new_id': 'pending', 'op': op, 'name': display_name, 'type': final_type})
            else:
                results.append({'id': aid, 'ok': True, 'new_id': '', 'name': display_name, 'type': final_type})

        except Exception as e:
            results.append({'id': aid, 'ok': False, 'error': str(e)})

    return jsonify({'results': results})

@app.route('/api/resolve', methods=['POST'])
def api_resolve():
    session = get_session()
    if not session:
        return jsonify({'error': 'Silakan sign in terlebih dahulu.'}), 401

    api_key = session.get('api_key', '').strip()
    data = request.get_json(silent=True) or {}
    items = data.get('items', [])
    results = []

    for item in items:
        aid = item.get('id')
        op = item.get('op', '')
        if not op:
            results.append({'id': aid, 'state': 'fail', 'error': 'Operation kosong'})
            continue
        try:
            url = op if op.startswith('http') else f"https://apis.roblox.com/assets/v1/{op.lstrip('/')}"
            r = requests.get(url, headers={'x-api-key': api_key}, timeout=10)
            rj = r.json()
            if rj.get('done'):
                if rj.get('error'):
                    results.append({'id': aid, 'state': 'fail', 'error': rj['error'].get('message')})
                else:
                    new_id = rj.get('response', {}).get('assetId') or rj.get('assetId')
                    results.append({'id': aid, 'state': 'done', 'new_id': str(new_id)})
            else:
                results.append({'id': aid, 'state': 'pending'})
        except Exception as e:
            results.append({'id': aid, 'state': 'fail', 'error': str(e)})

    return jsonify({'results': results})

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 3000))
    print(f"[*] SPOOFER AND REUPLOAD ASET ID berjalan di http://localhost:{port}")
    app.run(host='0.0.0.0', port=port, debug=False)
