'use strict';
const $=id=>document.getElementById(id);
const api=async(u,b)=>{const r=await fetch(u,b===undefined?{}:{method:'POST',headers:{'Content-Type':'application/json','X-Requested-With':'fetch'},body:JSON.stringify(b)});let d={};try{d=await r.json()}catch(e){}if(!r.ok)apiFail(r,d);return d};
const show=(e,on)=>e.classList.toggle('hide',!on);
const h=(t,p,...c)=>{const e=document.createElement(t);if(p)for(const k in p){if(k==='class')e.className=p[k];else if(k.startsWith('on'))e[k]=p[k];else e.setAttribute(k,p[k])}for(const x of c.flat())if(x!=null&&x!==false)e.append(x.nodeType?x:document.createTextNode(x));return e};
const ico=n=>{const s=document.createElementNS('http://www.w3.org/2000/svg','svg'),u=document.createElementNS('http://www.w3.org/2000/svg','use');s.setAttribute('class','i');u.setAttribute('href','#i-'+n);s.append(u);return s};
const row=(p,t,c)=>{const d=h('div',{class:'res '+(c||'')},t);p.appendChild(d);return d};
function apiFail(r,d){if(d.maintenance)showMaint(d.error);else if(d.banned)refreshMe();throw new Error(d.error||'HTTP '+r.status)}
let ME={logged_in:false};

/* ───────── util ───────── */
function toast(m){const t=$('toast');t.textContent=m;t.classList.add('on');clearTimeout(toast.t);toast.t=setTimeout(()=>t.classList.remove('on'),2400)}
function copy(txt,msg){const ok=()=>toast(msg||'Disalin');
  if(navigator.clipboard&&navigator.clipboard.writeText)return navigator.clipboard.writeText(txt).then(ok,()=>fb());fb();
  function fb(){const t=h('textarea',{style:'position:fixed;opacity:0'});t.value=txt;document.body.append(t);t.select();try{document.execCommand('copy');ok()}catch(e){toast('Gagal menyalin')}t.remove()}}
function save(name,text,type){const u=URL.createObjectURL(new Blob([text],{type}));const a=h('a',{href:u,download:name});document.body.append(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(u),4000)}
const pad=n=>String(n).padStart(2,'0');
const hhmmss=()=>{const d=new Date();return pad(d.getHours())+':'+pad(d.getMinutes())+':'+pad(d.getSeconds())};

/* ───────── tema ───────── */
const metaTheme=()=>{const m=document.querySelector('meta[name=theme-color]');if(m)m.content=document.documentElement.dataset.theme==='light'?'#fafafa':'#0a0a0a'};
$('tg').onclick=()=>{const r=document.documentElement,n=r.dataset.theme==='light'?'dark':'light';r.classList.add('tt');r.dataset.theme=n;try{localStorage.setItem('theme',n)}catch(e){}metaTheme();setTimeout(()=>r.classList.remove('tt'),500)};
metaTheme();

/* ───────── navigasi ───────── */
const PAGES=['home','spoof','upload','setup','buy','vip','owner'];
function go(p,push=true){
  if(!PAGES.includes(p))p='home';
  if(p!=='home'&&!ME.logged_in){$('gate').classList.remove('hide');return}
  if(p==='owner'&&!ME.owner)p='home';
  PAGES.forEach(x=>{const e=$('p-'+x);show(e,x===p);if(x===p){e.classList.remove('page');void e.offsetWidth;e.classList.add('page')}});
  document.querySelectorAll('.side-drawer button[data-go],.tabbar button[data-go]').forEach(b=>b.classList.toggle('on',b.dataset.go===p));
  if(push)history.replaceState(null,'','#'+p);scrollTo(0,0);if(p==='home')loadStats();if(p==='owner')loadOwner(true).catch(()=>{});show($('menu'),false);if(typeof setNavOpen==='function')setNavOpen(false);
}
document.querySelectorAll('[data-go]').forEach(b=>b.onclick=()=>go(b.dataset.go));
/* ───────── animated side navigation ───────── */
const navDrawer=$('nav'),navShade=$('navShade'),navToggle=$('navToggle');
function setNavOpen(open){
  if(!navDrawer||!navShade||!navToggle)return;
  navDrawer.classList.toggle('open',open);
  navShade.classList.toggle('open',open);
  navToggle.classList.toggle('open',open);
  navToggle.setAttribute('aria-expanded',String(open));
  navShade.setAttribute('aria-hidden',String(!open));
  document.body.classList.toggle('nav-open',open);
}
navToggle?.addEventListener('click',()=>setNavOpen(!navDrawer.classList.contains('open')));
navShade?.addEventListener('click',()=>setNavOpen(false));
document.addEventListener('keydown',e=>{if(e.key==='Escape')setNavOpen(false)});
$('navClose')?.addEventListener('click',()=>setNavOpen(false));
$('tbMenu')?.addEventListener('click',()=>setNavOpen(!navDrawer.classList.contains('open')));
$('navAcc')?.addEventListener('click',()=>{if(ME.logged_in)go('setup');else location.href='/auth/discord'});
const _render=render;render=function(){_render();const on=!!ME.logged_in,av=$('navAv');
  $('navName').textContent=on?ME.name:'Belum terhubung';$('navSub').textContent=on?(ME.api_key?'Roblox terhubung':'Hubungkan Roblox di Setup'):'Ketuk untuk masuk';
  av.replaceChildren();if(on&&ME.avatar)av.append(h('img',{src:ME.avatar,alt:''}));else if(on)av.textContent=(ME.name||'?').trim().charAt(0).toUpperCase();else av.append(ico('user'));limitUI();contactUpdate();gateUI();spoofGate();loadStats()};

$('gateX').onclick=()=>$('gate').classList.add('hide');
$('gate').onclick=e=>{if(e.target===$('gate'))$('gate').classList.add('hide')};
$('avbtn').onclick=e=>{e.stopPropagation();$('menu').classList.toggle('hide')};
document.addEventListener('click',e=>{if(!$('menu').contains(e.target))show($('menu'),false)});
$('logout').onclick=async()=>{try{await api('/api/logout',{})}catch(e){}location.href='/'};

/* ───────── data akun ───────── */
async function loadMe(){try{ME=await api('/api/me')}catch(e){ME={logged_in:false}}}
const maxIds=()=>ME.vip?999999:1;
function render(){
  const on=!!ME.logged_in;document.body.classList.toggle('out',!on);
  show($('signin'),!on);show($('avbtn'),on);show($('ownBtn'),on&&ME.owner);show($('ownTile'),on&&ME.owner);
  const heroBtn=$('heroBtn');show(heroBtn,!on);
  const wav=$('wav');wav.replaceChildren();
  if(!on){wav.append(ico('user'));$('hello').textContent='Selamat datang';$('heroT').textContent='Spoof asset Roblox, tanpa ribet.';$('heroP').textContent='Sign in dengan Discord untuk membuka semua tools. Tanpa sign in, halaman lain terkunci.';
    $('arc').style.strokeDashoffset=264;$('rt').textContent='—';$('planPill').textContent='TAMU';$('planPill').className='chip big';$('planT').textContent='Belum sign in';$('planTxt').textContent='Sign in untuk melihat jatah harianmu.';$('cfgSmall').textContent='API key & target';return}
  const initial=(ME.name||'?').trim().charAt(0).toUpperCase();
  const av=$('avbtn');av.replaceChildren();wav.replaceChildren();
  if(ME.avatar){av.append(h('img',{src:ME.avatar,alt:''}));wav.append(h('img',{src:ME.avatar,alt:''}))}else{av.textContent=initial;wav.textContent=initial}
  $('hello').textContent=ME.name;$('heroT').textContent='Halo, '+ME.name+'.';$('heroP').textContent=!ME.vip?(ME.api_key?'Akun Roblox sudah terhubung. Buka Upload untuk mengunggah decal, audio, atau model. Spoof khusus VIP.':'Hubungkan akun Roblox di Setup, lalu mulai upload asset. Spoof khusus VIP.'):ME.api_key?'Akun Roblox sudah terhubung. Buka Spoof dan tempel Asset ID.':'Hubungkan akun Roblox di Setup, lalu mulai spoof asset.';
  const vip=ME.vip,left=Math.max(0,ME.limit-ME.used);
  $('planPill').textContent=vip?'VIP':'FREE';$('planPill').className='chip big'+(vip?' ok':'');
  $('planT').textContent=vip?'Paket VIP':'Paket Gratis';
  if(vip){$('arc').style.strokeDashoffset=0;$('rt').textContent='∞';$('planTxt').textContent=ME.vip_days===null?'VIP permanen':'Aktif · sisa '+ME.vip_days+' hari'}
  else{$('arc').style.strokeDashoffset=264*(1-left/ME.limit);$('rt').textContent=left;$('planTxt').textContent=`${left} dari ${ME.limit} jatah gratis`}
  $('mName').textContent=ME.name;$('mPlan').textContent=vip?'VIP':'Paket gratis';
  $('cfgNow').textContent=ME.api_key?`Tersimpan: ${ME.api_key} · ${ME.target_type} ${ME.target_id}`:'Belum ada konfigurasi.';
  $('cfgSmall').textContent=ME.api_key?'Terhubung ✓':'Belum terhubung';
  $('vipPill').textContent=vip?'VIP':'FREE';$('vipPill').className='chip big'+(vip?' ok':'');$('vipTxt').textContent=vip?(ME.vip_days===null?'VIP permanen':'Sisa '+ME.vip_days+' hari'):'Belum VIP';
  limitNote();sumUpdate();upNote();
}

/* ───────── spoof: input ───────── */
const parseIds=t=>(String(t).match(/\d+/g)||[]).filter(x=>x.length>=5&&x.length<=19);
function limitNote(){if(!ME.logged_in)return;const left=Math.max(0,ME.limit-ME.used);
  $('limitNote').textContent=ME.vip?'VIP: unlimited ID per proses, tanpa batas harian.':'Spoof khusus VIP. Akun gratis hanya bisa memakai fitur Upload.'}
function sumUpdate(){const all=parseIds($('ids').value),u=new Set(all);$('sT').textContent=all.length;$('sU').textContent=u.size;$('sDn').textContent=all.length-u.size;$('sD').disabled=all.length===u.size}
$('ids').oninput=sumUpdate;
/* pilihan tipe asset yang di-spoof: upload ke tipe yang sama */
const TYPES=[['auto','Otomatis (deteksi)'],['Animation','Animasi'],['Audio','Lagu / Audio'],['Decal','Gambar / Decal'],['Model','Model']];
const typeSel=h('select',{id:'atype',style:'width:100%;margin-top:8px;padding:10px 12px;border-radius:12px;border:1px solid rgba(255,255,255,.18);background:transparent;color:inherit;font:inherit'},TYPES.map(([v,t])=>{const o=h('option',{value:v,style:'color:#000'},t);return o}));
try{const sv=localStorage.getItem('spoofType');if(sv&&TYPES.some(x=>x[0]===sv))typeSel.value=sv}catch(e){}
typeSel.onchange=()=>{try{localStorage.setItem('spoofType',typeSel.value)}catch(e){}};
(()=>{const box=$('up').closest('label')||$('up').parentNode;box.after(h('div',{class:'mut',style:'margin-top:10px;font-size:13px'},'Tipe asset yang di-spoof (upload ke tipe ini)',typeSel))})();

$('sD').onclick=()=>{$('ids').value=[...new Set(parseIds($('ids').value))].join('\n');sumUpdate();toast('Duplikat dihapus')};
document.querySelectorAll('[data-tab]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-tab]').forEach(x=>x.classList.toggle('on',x===b));show($('tab-paste'),b.dataset.tab==='paste');show($('tab-file'),b.dataset.tab==='file')});
function readFile(f){if(!f)return;if(f.size>2e6){toast('File terlalu besar (maks 2 MB)');return}
  const r=new FileReader();r.onload=()=>{const ids=parseIds(r.result);if(!ids.length){toast('Tidak ada Asset ID di file ini');return}
    const cur=$('ids').value.trim();$('ids').value=(cur?cur+'\n':'')+ids.join('\n');sumUpdate();
    document.querySelector('[data-tab=paste]').click();toast(`${ids.length} ID dimuat dari ${f.name}`);log(`File "${f.name}": ${ids.length} ID dimuat.`)};r.readAsText(f)}
$('file').onchange=e=>{readFile(e.target.files[0]);e.target.value=''};
const dr=$('drop');['dragenter','dragover'].forEach(v=>dr.addEventListener(v,e=>{e.preventDefault();dr.classList.add('over')}));
['dragleave','drop'].forEach(v=>dr.addEventListener(v,e=>{e.preventDefault();dr.classList.remove('over')}));
dr.addEventListener('drop',e=>readFile(e.dataTransfer.files[0]));

/* ───────── spoof: log, antrian, proses ───────── */
let Q=[],running=false,stopReq=false;
function log(m,k){const l=$('log');l.append(h('div',{class:k==='err'?'err':k==='w'?'w':''},h('span',{class:'t'},hhmmss()),m));while(l.children.length>200)l.firstChild.remove();l.scrollTop=l.scrollHeight}
$('clrL').onclick=()=>$('log').replaceChildren();
const ST={wait:'MENUNGGU',run:'MEMPROSES',ok:'SELESAI',fail:'GAGAL',stop:'DIHENTIKAN'};
function paintRow(it){const e=it.el;if(!e)return;
  e.st.textContent=ST[it.status];e.st.className='chip '+(it.status==='run'?'run':it.status==='ok'?'ok':it.status==='fail'?'fail':'');
  e.bar.style.width=(it.status==='ok'||it.status==='fail'?100:it.pct)+'%';e.bar.parentNode.classList.toggle('run',it.status==='run');
  e.nm.textContent=it.name?`${it.name}${it.type?' · '+it.type:''}`:(it.status==='wait'?'Menunggu giliran…':it.status==='run'?'Mengunduh & mengunggah…':'');
  e.res.replaceChildren();
  if(it.status==='ok'){e.res.append(h('span',{class:'mut'},it.newId?'ID baru':'Diunduh'));
    if(it.newId)e.res.append(h('code',null,it.newId),h('button',{class:'btn sm',onclick:()=>copy(it.newId,'ID baru disalin')},ico('copy'),'Salin'));
    if(it.file)e.res.append(h('a',{class:'btn sm',href:'/api/files/'+encodeURIComponent(it.file)},ico('down'),'File'))}
  if(it.status==='fail')e.res.append(h('span',{class:'err'},it.err||'Gagal'));
  show(e.res,e.res.childNodes.length>0)}
function renderQueue(){const q=$('queue');q.replaceChildren();
  if(!Q.length){q.append(h('div',{class:'empty'},'Antrian kosong.'));paintProg();return}
  Q.forEach((it,i)=>{const st=h('span',{class:'chip'}),bar=h('i'),nm=h('div',{class:'qn mut'}),res=h('div',{class:'qr hide'});
    it.el={st,bar,nm,res};q.append(h('div',{class:'q'},h('div',{class:'qt'},h('span',{class:'qi mono'},pad(i+1)),h('b',{class:'mono'},it.id),st),nm,h('div',{class:'pbar sm'},bar),res));paintRow(it)});paintProg()}
function paintProg2(done,total,ok,fail){
  const pct=total?Math.round(done/total*100):0;
  $('cT').textContent=total;$('cD').textContent=ok;$('cF').textContent=fail;$('cR').textContent=total-done;
  $('pPct').textContent=pct+'%';
  $('pBar').firstElementChild.style.width=pct+'%';
  $('pBar').classList.toggle('run',running);$('prog').classList.toggle('run',running);
  $('pTxt').textContent=!total?'Siap. Belum ada proses.':running?`Memproses (${done}/${total})…`:`Selesai · ${ok} berhasil, ${fail} gagal`;
  const has=ok>0;['cpAll','exTxt','exCsv','exJson'].forEach(i=>$(i).disabled=!has);
}
function paintProg(){const T=Q.length,D=Q.filter(x=>x.status==='ok').length,F=Q.filter(x=>x.status==='fail').length,S=Q.filter(x=>x.status==='stop').length,R=T-D-F-S;
  const cur=Q.find(x=>x.status==='run'),pct=T?Math.round((D+F+S+(cur?cur.pct/100:0))/T*100):0;
  $('cT').textContent=T;$('cD').textContent=D;$('cF').textContent=F;$('cR').textContent=T-D-F;$('pPct').textContent=pct+'%';
  $('pBar').firstElementChild.style.width=pct+'%';$('pBar').classList.toggle('run',running);$('prog').classList.toggle('run',running);
  $('pTxt').textContent=!T?'Siap. Belum ada proses.':running?`Memproses (${D+F+1}/${T})…`:`Selesai · ${D} berhasil, ${F} gagal${S?`, ${S} dihentikan`:''}`;
  const has=Q.some(x=>x.status==='ok');['cpAll','exTxt','exCsv','exJson'].forEach(i=>$(i).disabled=!has)}
$('clrQ').onclick=()=>{if(running){toast('Tunggu proses selesai');return}Q=[];renderQueue()};
const setRun=on=>{running=on;$('go').disabled=on;$('stop').disabled=!on};

async function start(){
  if(running)return;
  if(!ME.vip){toast('Spoof khusus VIP');log('Spoof khusus VIP. Akun gratis hanya bisa memakai Upload.','err');return}
  const uniq=[...new Set(parseIds($('ids').value))];
  if(!uniq.length){toast('Masukkan minimal satu Asset ID');return}
  const up=$('up').checked;
  if(up&&!ME.api_key){log('Isi API key & target dulu di Setup.','err');toast('Isi dulu Setup Roblox');return}
  if(up&&!ME.vip&&ME.used>=ME.limit){log(`Jatah gratis ${ME.limit}x per hari habis. Reset besok (WIB) atau upgrade VIP.`,'err');toast('Jatah gratis habis');return}
  const mx=maxIds(),ids=ME.vip?uniq:uniq.slice(0,mx);
  // unlimited: tidak ada potong ID
  // Simpan semua ID, tidak render antrian
  const allIds=ids;
  let allResults=[];
  stopReq=false;setRun(true);
  // Reset progress
  Q=allIds.map(id=>({id,status:'wait',pct:0}));
  paintProg2(0,allIds.length,0,0);
  log(`Memulai proses untuk ${allIds.length} asset…`);
  const name=allIds.length===1?$('nm').value.trim():'';
  const CHUNK=30;
  const chunks=[];
  for(let i=0;i<allIds.length;i+=CHUNK)chunks.push(allIds.slice(i,i+CHUNK));

  // Tunggu upload 1 batch (30 ID) sampai semua dapat ID baru / gagal, baru lanjut batch berikutnya
  const waitBatch=async(ids,label)=>{
    const set=new Set(ids.map(String));
    const pend=()=>allResults.filter(r=>set.has(String(r.id))&&r.ok&&r.new_id==='pending'&&r.op);
    if(!up||!pend().length)return;
    log(`${label}: ${pend().length} asset masih diproses Roblox, menunggu ID baru…`,'w');
    const t0=Date.now();let wait=3000;
    while(pend().length&&!stopReq&&Date.now()-t0<600000){
      await new Promise(r=>setTimeout(r,wait));wait=Math.min(wait+1500,8000);
      const list=pend();
      try{
        const d=await api('/api/resolve',{items:list.map(r=>({id:String(r.id),op:r.op}))});
        (d.results||[]).forEach(x=>{
          const r=list.find(p=>String(p.id)===String(x.id));if(!r)return;
          if(x.state==='done'){r.new_id=String(x.new_id);log(`ID ${r.id} selesai → ID baru ${x.new_id}`)}
          else if(x.state==='fail'){r.ok=false;r.new_id='';r.error=x.error||'Gagal diproses Roblox';log(`ID ${r.id} gagal: ${r.error}`,'err')}
        });
      }catch(e){log('Cek status error: '+e.message,'err')}
      const ok2=allResults.filter(r=>r.ok&&r.new_id!=='pending').length,f2=allResults.filter(r=>!r.ok).length;
      paintProg2(ok2+f2,allIds.length,ok2,f2);
    }
    pend().forEach(r=>{r.ok=false;r.new_id='';r.error=stopReq?'Dihentikan sebelum ID baru keluar.':'Masih diproses Roblox >10 menit. Cek Creator Hub → Creations nanti.'});
  };
  for(let ci=0;ci<chunks.length;ci++){
    if(stopReq)break;
    const chunk=chunks[ci];
    const doneNow=allResults.filter(r=>r.ok).length;
    const failNow=allResults.filter(r=>!r.ok).length;
    log(`Batch ${ci+1}/${chunks.length}: ${chunk.length} ID…`);
    paintProg2(doneNow+failNow,allIds.length,doneNow,failNow);
    try{
      const d=await api('/api/process',{asset_ids:chunk.join(' '),upload:up,name,asset_type:typeSel.value});
      const results=d.results||[];
      results.forEach(r=>{
        const it=Q.find(x=>x.id===String(r.id));
        if(it){
          it.newId=r.new_id?String(r.new_id):'';
          const noNew=!!r.ok&&up&&!/^\d+$/.test(it.newId)&&it.newId!=='pending';
          it.status=r.ok&&!noNew?'ok':'fail';
          it.name=r.name;it.type=r.type;it.err=r.error||'';
        }
        allResults.push(r);
      });
    }catch(e){
      log(`Batch ${ci+1} error: ${e.message}`,'err');
      chunk.forEach(id=>allResults.push({id,ok:false,error:e.message}));
    }
    await waitBatch(chunk,`Batch ${ci+1}/${chunks.length}`);
    if(!stopReq&&ci<chunks.length-1)log(`Batch ${ci+1}/${chunks.length} selesai, lanjut batch berikutnya…`);
    const D2=allResults.filter(r=>r.ok).length;
    const F2=allResults.filter(r=>!r.ok).length;
    paintProg2(D2+F2,allIds.length,D2,F2);
  }

  setRun(false);
  const D=allResults.filter(r=>r.ok).length;
  const F=allResults.filter(r=>!r.ok).length;
  paintProg2(allIds.length,allIds.length,D,F);
  log(stopReq?'Proses dihentikan.':`Selesai: ${D}/${allIds.length} berhasil.`,stopReq?'w':'');
  toast(stopReq?'Dihentikan':`Selesai: ${D}/${allIds.length} berhasil`);

  // Render antrian hanya hasil akhir
  Q=allResults.map(r=>({
    id:String(r.id),status:r.ok?'ok':'fail',
    name:r.name,type:r.type,
    newId:r.new_id?String(r.new_id):'',
    err:r.error||'',pct:100,el:null
  }));
  renderQueue();

  const pr=pairList();
  if(pr.length)autoTxt(pr,D<allIds.length);
  else if(up&&allIds.length>1)log('Tidak ada pasangan ID baru, file TXT tidak dibuat.','w');
  await loadMe();render();
}
$('go').onclick=start;
$('stop').onclick=()=>{stopReq=true;$('stop').disabled=true;log('Berhenti setelah asset yang sedang berjalan…','w')};
$('info').onclick=async()=>{const id=parseIds($('ids').value)[0];if(!id){toast('Isi Asset ID dulu');return}
  try{const d=await api('/api/assetinfo?id='+id);log(`INFO ${id}: ${d.name} · ${d.type} · oleh ${d.creator}`)}catch(e){log(`INFO ${id}: ${e.message}`,'err')}};
const done=()=>Q.filter(x=>x.status==='ok');
/* pasangan ID lama -> ID baru: selalu dari item antrian yang sama (id & newId satu objek), hanya yang sukses dan punya ID baru berupa angka */
const pairList=()=>Q.filter(x=>x.status==='ok'&&/^\d+$/.test(String(x.newId||''))).map(x=>({old:x.id,neu:String(x.newId)}));
const pairsTxt=p=>p.map(x=>`Id lama : ${x.old} id baru : ${x.neu}`).join('\n')+'\n';
const stamp=()=>{const d=new Date();return `${d.getFullYear()}${pad(d.getMonth()+1)}${pad(d.getDate())}-${pad(d.getHours())}${pad(d.getMinutes())}`};
function autoTxt(p,partial){save(`hasil-spoof-massal-${stamp()}.txt`,pairsTxt(p),'text/plain');
  log(`File TXT otomatis diunduh: ${p.length} pasangan ID lama dan ID baru${partial?' (proses belum lengkap, hanya yang berhasil)':''}.`);toast('File TXT hasil spoof diunduh')}
$('cpAll').onclick=()=>{const l=done().filter(x=>x.newId).map(x=>x.newId);if(!l.length){toast('Belum ada ID baru');return}copy(l.join('\n'),`${l.length} ID baru disalin`)};
$('exTxt').onclick=()=>{const p=pairList();if(!p.length){toast('Belum ada ID baru');return}save('hasil-spoof.txt',pairsTxt(p),'text/plain')};
const csvc=v=>{v=String(v==null?'':v);if(/^[=+\-@\t\r]/.test(v))v="'"+v;return '"'+v.replace(/"/g,'""')+'"'};
$('exCsv').onclick=()=>save('hasil-spoof.csv',['id_lama,id_baru,nama,tipe'].concat(done().map(x=>[x.id,x.newId,x.name,x.type].map(csvc).join(','))).join('\n'),'text/csv');
$('exJson').onclick=()=>save('hasil-spoof.json',JSON.stringify(done().map(x=>({id_lama:x.id,id_baru:x.newId||null,nama:x.name||null,tipe:x.type||null})),null,2),'application/json');


/* ───────── upload: audio & decal ───────── */
const fdApi=async(u,fd)=>{const r=await fetch(u,{method:'POST',headers:{'X-Requested-With':'fetch'},body:fd});let d={};try{d=await r.json()}catch(e){}if(!r.ok)apiFail(r,d);return d};
const fmtT=s=>{s=Math.round(s);return Math.floor(s/60)+':'+pad(s%60)};
const msg=(id,t,bad)=>{const m=$(id);m.textContent=t||'';m.className='msg'+(bad?' err':'')};
document.querySelectorAll('[data-ut]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-ut]').forEach(x=>x.classList.toggle('on',x===b));show($('ut-audio'),b.dataset.ut==='audio');show($('ut-decal'),b.dataset.ut==='decal');show($('ut-model'),b.dataset.ut==='model')});
document.querySelectorAll('[data-as]').forEach(b=>b.onclick=()=>{document.querySelectorAll('[data-as]').forEach(x=>x.classList.toggle('on',x===b));show($('as-link'),b.dataset.as==='link');show($('as-file'),b.dataset.as==='file')});
const srcMode=()=>document.querySelector('[data-as].on').dataset.as;
function upNote(){const t=ME.tools||{};const w=[];if(!t.ffmpeg)w.push('ffmpeg belum terpasang di server (audio tidak bisa diproses).');if(!t.ytdlp)w.push('yt-dlp belum terpasang (link YouTube/TikTok tidak bisa dipakai).');
  $('upNote').textContent=w.join(' ')||(ME.vip?'VIP: upload tanpa batas harian.':`Tiap upload ke Roblox memakai 1 jatah (sisa ${Math.max(0,ME.limit-ME.used)}/${ME.limit}; habis = tunggu 24 jam). Proses convert tidak memakai jatah.`)}
/* PlaybackSpeed */
const SPD_PICKS=[0.25,0.3,0.35,0.4,0.43,0.5,0.6,0.75];
const spd=()=>{const v=parseFloat(String($('aSpd').value).replace(',','.'));return v>=0.1&&v<=1?Math.round(v*1000)/1000:0};
function spdHint(){const v=spd(),on=$('aConv').checked;show($('aSpeedBox'),on);
  document.querySelectorAll('.pk').forEach(b=>b.classList.toggle('on',+b.dataset.v===v));
  $('aHint').textContent=v?`Audio dipercepat ${(1/v).toFixed(2)}× (nada ikut naik). Di Roblox set Sound.PlaybackSpeed = ${v} supaya kembali normal.`:'Isi PlaybackSpeed antara 0.1 dan 1.0.'}
SPD_PICKS.forEach(v=>$('aPicks').append(h('button',{class:'pk',type:'button','data-v':v,onclick:()=>{$('aSpd').value=v;spdHint()}},String(v))));
$('aSpd').oninput=spdHint;$('aConv').onchange=spdHint;spdHint();
/* file audio */
let AF=null;
function pickAudio(f){if(!f)return;const mx=(ME.tools&&ME.tools.max_mb)||25;if(f.size>mx*1048576){toast(`File terlalu besar (maks ${mx} MB)`);return}AF=f;$('aFileName').textContent=f.name;$('aFileHint').textContent=(f.size/1048576).toFixed(1)+' MB · siap diproses'}
$('aFile').onchange=e=>{pickAudio(e.target.files[0]);e.target.value=''};
const adr=$('aDrop');['dragenter','dragover'].forEach(v=>adr.addEventListener(v,e=>{e.preventDefault();adr.classList.add('over')}));
['dragleave','drop'].forEach(v=>adr.addEventListener(v,e=>{e.preventDefault();adr.classList.remove('over')}));adr.addEventListener('drop',e=>pickAudio(e.dataTransfer.files[0]));
/* proses audio */
let AO=null,aBusy=false;
$('aGo').onclick=async()=>{
  if(aBusy)return;const conv=$('aConv').checked,v=spd(),link=$('aLink').value.trim();
  if(conv&&!v){msg('aMsg','PlaybackSpeed harus antara 0.1 dan 1.0.',1);return}
  if(srcMode()==='link'&&!link){msg('aMsg','Tempel link YouTube / TikTok dulu.',1);return}
  if(srcMode()==='file'&&!AF){msg('aMsg','Pilih file audio dulu.',1);return}
  const fd=new FormData();fd.append('convert',conv?'1':'0');fd.append('speed',v||'');fd.append('name',$('aName').value.trim());
  if(srcMode()==='link')fd.append('link',link);else fd.append('file',AF,AF.name);
  aBusy=true;$('aGo').disabled=true;show($('aBar'),true);show($('aRes'),false);show($('aDone'),false);msg('aMsg',srcMode()==='link'?'Mengunduh & mengonversi… (bisa 10–60 detik)':'Mengonversi audio…');
  try{const d=await fdApi('/api/upload/audio/prepare',fd);AO=d;
    msg('aMsg','Selesai diproses.');show($('aRes'),true);
    $('aInfo').textContent=`${d.name} · ${fmtT(d.dur_src)} → ${fmtT(d.dur_out)} · ${(d.size/1048576).toFixed(2)} MB`+(d.speed?` · dipercepat ${d.factor}× (PlaybackSpeed ${d.speed})`:' · tanpa percepatan');
    const pl=$('aPlayer');pl.src='/api/preview/'+encodeURIComponent(d.file);
    const r=d.speed||1;pl.defaultPlaybackRate=r;pl.playbackRate=r;pl.preservesPitch=false;pl.webkitPreservesPitch=false;pl.mozPreservesPitch=false;
    $('aPrevNote').textContent=(d.speed?`Pratinjau diputar pada ${d.speed}× — begini kira-kira bunyinya di Roblox.`:'')+(d.too_long?` ⚠ Durasi ${fmtT(d.dur_out)} melebihi ${fmtT(d.max_sec)}; Roblox mungkin menolak. Pakai PlaybackSpeed lebih besar atau potong audio.`:'');
    $('aDl').href='/api/files/'+encodeURIComponent(d.file);$('aSend').disabled=false;
  }catch(e){msg('aMsg',e.message,1)}
  aBusy=false;$('aGo').disabled=false;show($('aBar'),false)};
$('aSend').onclick=async()=>{
  if(!AO||aBusy)return;if(!ME.api_key){msg('aMsg','Isi API key & target dulu di Setup.',1);return}
  aBusy=true;$('aSend').disabled=true;show($('aBar'),true);msg('aMsg','Mengunggah ke Roblox… (moderasi audio bisa sampai 1–2 menit)');
  try{const d=await api('/api/upload/audio/send',{file:AO.file,name:$('aName').value.trim()||AO.name});
    msg('aMsg','Upload berhasil.');$('aId').textContent=d.asset_id;show($('aDone'),true);
    $('aSnip').textContent=`local s = Instance.new("Sound")\ns.SoundId = "rbxassetid://${d.asset_id}"\n`+(AO.speed?`s.PlaybackSpeed = ${AO.speed}\n`:'')+`s.Parent = workspace\ns:Play()`;
    toast('Audio berhasil diupload');await loadMe();render();upNote();
  }catch(e){msg('aMsg',e.message,1);$('aSend').disabled=false}
  aBusy=false;show($('aBar'),false)};
$('aCpId').onclick=()=>copy($('aId').textContent,'ID disalin');$('aCpSnip').onclick=()=>copy($('aSnip').textContent,'Script disalin');
/* decal */
let DF=null;
function pickDecal(f){if(!f)return;const mx=(ME.tools&&ME.tools.max_mb)||25;if(!/^image\/(png|jpeg|bmp)$/.test(f.type)&&!/\.(png|jpe?g|bmp)$/i.test(f.name)){toast('Format harus PNG, JPG, atau BMP');return}
  if(f.size>mx*1048576){toast(`File terlalu besar (maks ${mx} MB)`);return}DF=f;$('dFileName').textContent=f.name;
  const old=$('dPrev').src;if(old&&old.startsWith('blob:'))URL.revokeObjectURL(old);$('dPrev').src=URL.createObjectURL(f);show($('dPrevBox'),true);show($('dDone'),false);msg('dMsg','')}
$('dFile').onchange=e=>{pickDecal(e.target.files[0]);e.target.value=''};
const ddr=$('dDrop');['dragenter','dragover'].forEach(v=>ddr.addEventListener(v,e=>{e.preventDefault();ddr.classList.add('over')}));
['dragleave','drop'].forEach(v=>ddr.addEventListener(v,e=>{e.preventDefault();ddr.classList.remove('over')}));ddr.addEventListener('drop',e=>pickDecal(e.dataTransfer.files[0]));
let dBusy=false;
$('dGo').onclick=async()=>{
  if(dBusy)return;if(!DF){msg('dMsg','Pilih gambar dulu.',1);return}if(!ME.api_key){msg('dMsg','Isi API key & target dulu di Setup.',1);return}
  const fd=new FormData();fd.append('name',$('dName').value.trim());fd.append('file',DF,DF.name);
  dBusy=true;$('dGo').disabled=true;show($('dBar'),true);show($('dDone'),false);msg('dMsg','Mengunggah ke Roblox…');
  try{const d=await fdApi('/api/upload/decal',fd);msg('dMsg','Upload berhasil.');$('dId').textContent=d.asset_id;show($('dDone'),true);toast('Decal berhasil diupload');await loadMe();render();upNote()}
  catch(e){msg('dMsg',e.message,1)}
  dBusy=false;$('dGo').disabled=false;show($('dBar'),false)};
$('dCpId').onclick=()=>copy($('dId').textContent,'ID disalin');$('dCpUri').onclick=()=>copy('rbxassetid://'+$('dId').textContent,'Disalin');

/* model (.rbxm) */
let MF=null;
function pickModel(f){if(!f)return;const mx=(ME.tools&&ME.tools.max_model_mb)||20;
  if(!/\.rbxmx?$/i.test(f.name)){toast('Format harus .rbxm');return}
  if(f.size>mx*1048576){toast(`File terlalu besar (maks ${mx} MB)`);return}
  MF=f;$('mFileName').textContent=f.name;$('mFileHint').textContent=(f.size/1048576).toFixed(2)+' MB · siap diupload';show($('mDone'),false);msg('mMsg','')}
$('mFile').onchange=e=>{pickModel(e.target.files[0]);e.target.value=''};
const mdr=$('mDrop');['dragenter','dragover'].forEach(v=>mdr.addEventListener(v,e=>{e.preventDefault();mdr.classList.add('over')}));
['dragleave','drop'].forEach(v=>mdr.addEventListener(v,e=>{e.preventDefault();mdr.classList.remove('over')}));mdr.addEventListener('drop',e=>pickModel(e.dataTransfer.files[0]));
let mBusy=false;
$('mGo').onclick=async()=>{
  if(mBusy)return;if(!MF){msg('mMsg','Pilih file .rbxm dulu.',1);return}if(!ME.api_key){msg('mMsg','Isi API key & target dulu di Setup.',1);return}
  const fd=new FormData();fd.append('name',$('mdName').value.trim());fd.append('file',MF,MF.name);
  mBusy=true;$('mGo').disabled=true;show($('mBar'),true);show($('mDone'),false);msg('mMsg','Mengunggah ke Roblox… (bisa sampai 1–2 menit)');
  try{const d=await fdApi('/api/upload/model',fd);msg('mMsg','Upload berhasil.');$('mId').textContent=d.asset_id;
    $('mSnip').textContent=`local InsertService = game:GetService("InsertService")\nlocal model = InsertService:LoadAsset(${d.asset_id})\nmodel.Parent = workspace`;
    show($('mDone'),true);toast('Model berhasil diupload');await loadMe();render();upNote()}
  catch(e){msg('mMsg',e.message,1)}
  mBusy=false;$('mGo').disabled=false;show($('mBar'),false)};
$('mCpId').onclick=()=>copy($('mId').textContent,'ID disalin');$('mCpUri').onclick=()=>copy('rbxassetid://'+$('mId').textContent,'Disalin');$('mCpSnip').onclick=()=>copy($('mSnip').textContent,'Script disalin');

/* ───────── setup, vip, owner ───────── */
$('save').onclick=async()=>{const m=$('cmsg');try{await api('/api/setup',{api_key:$('ak').value,target_id:$('ti').value,target_type:$('tt').value});$('ak').value='';m.className='msg';m.textContent='Tersimpan.';await loadMe();render()}catch(e){m.className='msg err';m.textContent=e.message}};
$('rst').onclick=async()=>{await api('/api/reset',{});$('cmsg').textContent='';await loadMe();render()};
let OWN=[],SET={maintenance:{},prices:{},promo:null,plans:[]};
function renderMembers(){const u=$('users'),q=($('uSearch').value||'').trim().toLowerCase();u.replaceChildren();
  const list=OWN.filter(m=>!q||(m.name||'').toLowerCase().includes(q)||String(m.id).includes(q));
  if(!list.length){row(u,q?'Tidak ada yang cocok.':'Belum ada member.','mut');return}
  for(const m of list){const e=row(u,'');e.classList.add('mem');
    e.append(h('div',{class:'mi'},h('b',{},m.name||'-'),h('span',{class:'mut'},` · ${m.vip_days===null?(m.owner?'Owner':'VIP Unlimited'):m.vip_days>0?'VIP '+fmtDur(m.vip_secs):'Free'} · limit ${m.used}/${ME.limit}`),m.banned?h('span',{class:'chip fail'},'BANNED'):null,h('small',{class:'mut mono'},'ID '+m.id+(m.banned&&m.ban_reason?' · '+m.ban_reason:''))));
    const r=h('div',{class:'row mb'});
    for(const [t,days] of [['+1h',1],['+3h',3],['+7h',7],['+30h',30],['∞',9999],['Cabut',0]])r.append(h('button',{class:'btn sm',onclick:async()=>{try{await giveVip(m.id,days)}catch(x){toast(x.message)}}},t));
    if(!m.owner)r.append(h('button',{class:'btn sm',onclick:async()=>{try{
      if(m.banned)await banUser(m.id,false);
      else{const why=prompt('Alasan ban (opsional, tampil ke user):','');if(why===null)return;await banUser(m.id,true,why)}}catch(x){toast(x.message)}}},m.banned?'Unban':'Ban'));
    e.append(r)}}
function renderSettings(){const mt=SET.maintenance||{},pm=SET.promo;
  $('mtOn').checked=!!mt.on;$('mtMsg').value=mt.msg||'';$('mtState').textContent=mt.on?'MAINTENANCE AKTIF':'WEBSITE TERBUKA';$('mtState').className='chip big'+(mt.on?' fail':' ok');
  for(const d of [1,3,7,30])$('pr'+d).value=(SET.prices||{})[d]||'';
  $('pmNow').textContent=pm?`Aktif: ${pm.name} · diskon ${pm.percent}% · ${pm.secs_left==null?'sampai dimatikan':'sisa '+fmtDur(pm.secs_left)}`:'Tidak ada promo aktif.';
  $('pmPrev').textContent=(SET.plans||[]).map(p=>`${p.label}: ${rp(p.price)}`+(p.final<p.price?` → ${rp(p.final)}`:'')).join('\n')}
async function loadOwner(withSettings){const d=await api('/api/owner');OWN=d.users||[];if(d.settings)SET=d.settings;renderMembers();if(withSettings)renderSettings()}
$('uSearch').oninput=renderMembers;
const parseDid=t=>(String(t).match(/\d{17,20}/)||[])[0]||'';
/* VIP */
async function giveVip(id,days){const d=await api('/api/owner/vip',{id,days});
  toast(days===9999?`VIP unlimited untuk ${d.name}`:days?`VIP +${days} hari untuk ${d.name}`:`VIP ${d.name} dicabut`);await loadOwner();return d}
/* tempel seluruh pesan WhatsApp: Discord ID & durasi (kalau ada) diambil otomatis */
$('ovId').oninput=()=>{const t=$('ovId').value,id=parseDid(t);
  if(id&&t.trim()!==id){$('ovId').value=id;const m=t.match(/VIP\s+(1 Hari|3 Hari|1 Minggu|1 Bulan|Unlimited)/i);
    if(m){const d={'1 hari':1,'3 hari':3,'1 minggu':7,'1 bulan':30,'unlimited':9999}[m[1].toLowerCase()];const b=document.querySelector(`#gdSeg [data-d="${d}"]`);if(b)b.click()}}};
$('ovGive').onclick=async()=>{const id=parseDid($('ovId').value);if(!id){msg('omsg','Discord ID tidak valid (17–20 angka).',1);return}
  try{const d=await giveVip(id,+$('gd').value);msg('omsg',`Berhasil: ${d.name} sekarang VIP (${d.vip_secs==null?'unlimited, permanen':'sisa '+fmtDur(d.vip_secs)}).`)}catch(e){msg('omsg',e.message,1)}};
$('ovRevoke').onclick=async()=>{const id=parseDid($('ovId').value);if(!id){msg('omsg','Discord ID tidak valid (17–20 angka).',1);return}
  try{const d=await giveVip(id,0);msg('omsg',`VIP ${d.name} sudah dicabut.`)}catch(e){msg('omsg',e.message,1)}};
/* ban */
async function banUser(id,ban,reason){const d=await api('/api/owner/ban',{id,ban,reason:reason||''});
  toast(ban?`${d.name} di-ban`:`${d.name} di-unban`);await loadOwner();return d}
$('bnGo').onclick=async()=>{const id=parseDid($('bnId').value);if(!id){msg('bnOut','Discord ID tidak valid (17–20 angka).',1);return}
  try{const d=await banUser(id,true,$('bnWhy').value.trim());msg('bnOut',`${d.name} sudah di-ban.`)}catch(e){msg('bnOut',e.message,1)}};
$('bnUn').onclick=async()=>{const id=parseDid($('bnId').value);if(!id){msg('bnOut','Discord ID tidak valid (17–20 angka).',1);return}
  try{const d=await banUser(id,false);msg('bnOut',`${d.name} sudah di-unban.`)}catch(e){msg('bnOut',e.message,1)}};
/* maintenance */
$('mtSave').onclick=async()=>{const on=$('mtOn').checked;
  if(on&&!confirm('Semua user selain owner akan diblokir dari website. Aktifkan maintenance?'))return;
  try{await api('/api/owner/maintenance',{on,msg:$('mtMsg').value.trim()});
    msg('mtOut',on?'Maintenance AKTIF. User biasa tidak bisa mengakses website.':'Maintenance dimatikan. Website terbuka untuk semua.');
    await refreshMe();await loadOwner(true)}catch(e){msg('mtOut',e.message,1)}};
/* harga */
$('prSave').onclick=async()=>{const p={};for(const d of [1,3,7,30])p[d]=$('pr'+d).value.replace(/\D/g,'');
  try{await api('/api/owner/prices',{prices:p});msg('prOut','Harga disimpan.');await loadStats();await loadOwner(true)}catch(e){msg('prOut',e.message,1)}};
$('prReset').onclick=async()=>{if(!confirm('Kembalikan semua harga ke default?'))return;
  try{await api('/api/owner/prices',{reset:true});msg('prOut','Harga dikembalikan ke default.');await loadStats();await loadOwner(true)}catch(e){msg('prOut',e.message,1)}};
/* promo */
$('pmOn').onclick=async()=>{try{await api('/api/owner/promo',{name:$('pmName').value.trim(),percent:$('pmPct').value.trim(),hours:$('pmHrs').value.trim().replace(',','.')});
  msg('pmOut','Promo aktif.');await loadStats();await loadOwner(true)}catch(e){msg('pmOut',e.message,1)}};
$('pmOff').onclick=async()=>{try{await api('/api/owner/promo',{off:true});msg('pmOut','Promo dimatikan.');await loadStats();await loadOwner(true)}catch(e){msg('pmOut',e.message,1)}};

/* ───────── V9: spoof khusus VIP ───────── */
function spoofGate(){const lock=!!ME.logged_in&&!ME.vip&&!ME.banned;
  show($('spoofLock'),lock);show($('spoofBody'),!lock);document.body.classList.toggle('novip',lock);
  $('spoofTileSm').textContent=lock?'Khusus VIP':'Tempel ID, unduh & unggah ulang'}

/* ───────── V8: layar maintenance & ban ───────── */
let mtT=null;
async function refreshMe(){try{ME=await api('/api/me');render()}catch(e){}}
function showMaint(m){ME.maintenance={on:true,msg:m};gateUI()}
function gateUI(){const mt=ME.maintenance||{},ban=!!ME.banned,lock=!!mt.on&&!ME.owner&&!ban;
  show($('maint'),lock);show($('banned'),ban);show($('ownBar'),!!(ME.owner&&mt.on));
  document.body.classList.toggle('locked',lock||ban);
  if(mt.msg)$('maintMsg').textContent=mt.msg;
  show($('maintOwn'),!ME.logged_in);
  if(ban){$('banReason').textContent=ME.ban_reason?'Alasan: '+ME.ban_reason:'';banContact()}
  clearInterval(mtT);if(lock)mtT=setInterval(refreshMe,15000)}
function banContact(){const t=`Halo Admin SPOOFER & REUPLOAD, akun saya di-ban dan saya mau mengajukan banding.\nNama: ${ME.name||'-'}\nDiscord ID: ${ME.id||'-'}`;$('banWa').href=`https://wa.me/${WA}?text=${encodeURIComponent(t)}`}
$('maintReload').onclick=()=>location.reload();
$('banOut').onclick=async()=>{try{await api('/api/logout',{})}catch(e){}location.href='/'};

/* ───────── loading screen ───────── */
const ld=$('ld'),T0=performance.now();let lp=0,lt=88,fin=false;const MSG=['MENYIAPKAN','MEMERIKSA SESI','MEMUAT TAMPILAN','HAMPIR SELESAI'];
const lti=setInterval(()=>{lp+=(lt-lp)*(fin?.22:.045);const v=Math.min(100,Math.round(lp));$('ldn').textContent=v;$('ldb').style.width=lp+'%';
  $('ldt').textContent=MSG[fin?3:lp<30?0:lp<60?1:2];
  if(fin&&lp>=99.4){clearInterval(lti);$('ldn').textContent=100;$('ldb').style.width='100%';setTimeout(()=>ld.classList.add('go'),260);setTimeout(()=>ld.remove(),1500)}},32);
function finishLoader(){if(fin)return;fin=true;lt=100}
setTimeout(finishLoader,6500);

/* ───────── boot ───────── */
(async()=>{
  const minWait=new Promise(r=>setTimeout(r,Math.max(0,1900-(performance.now()-T0))));
  await Promise.all([loadMe(),minWait]);render();
  if(/[?&]err/.test(location.search)){toast('Login Discord gagal, coba lagi.');history.replaceState(null,'','/')}
  go(location.hash.slice(1)||'home',false);
  finishLoader();
})();


/* ───────── V6: statistik beranda, hitung mundur limit, Buy VIP ───────── */
let PLANS=[],PROMO=null;
const rp=n=>'Rp'+n.toLocaleString('id-ID');
let WA='6282197014242',selPlan=null,cdT=null;
function countTo(el,n){const from=+el.dataset.v||0;el.dataset.v=n;if(from===n){el.textContent=n.toLocaleString('id-ID');return}
  const t0=performance.now(),D=800;(function f(t){const k=Math.min(1,(t-t0)/D),e=1-Math.pow(1-k,3);el.textContent=Math.round(from+(n-from)*e).toLocaleString('id-ID');if(k<1)requestAnimationFrame(f)})(t0)}
async function loadStats(){try{const d=await api('/api/stats');countTo($('stV'),d.visitors);countTo($('stVip'),d.vip);if(d.wa)WA=d.wa;PLANS=d.plans||[];PROMO=d.promo||null;if(selPlan)selPlan=PLANS.find(x=>x.d===selPlan.d)||null;buildPlans();promoUI();buyUpdate();contactUpdate()}catch(e){}}
function fmtDur(s){s=s||0;const d=Math.floor(s/86400),h=Math.floor(s%86400/3600),m=Math.floor(s%3600/60);return d?`${d} hari ${h} jam`:h?`${h} jam ${m} menit`:`${Math.max(1,m)} menit`}
const fmtClock=s=>pad(Math.floor(s/3600))+':'+pad(Math.floor(s%3600/60))+':'+pad(s%60);
function limitUI(){clearInterval(cdT);
  if(!ME.logged_in){$('stLim').textContent='3x';$('stLimT').textContent='Jatah gratis / 24 jam';return}
  if(ME.vip){$('stLim').textContent='∞';$('stLimT').textContent='Limit · VIP';if(ME.vip_secs!=null)$('planTxt').textContent='Aktif · sisa '+fmtDur(ME.vip_secs);return}
  const left=Math.max(0,ME.limit-ME.used);$('stLim').textContent=left+'/'+ME.limit;$('stLimT').textContent='Sisa limit';
  if(left===0&&ME.reset_in>0){const end=Date.now()+ME.reset_in*1000;
    const tick=()=>{const r=Math.max(0,Math.round((end-Date.now())/1000));$('planTxt').textContent='Limit habis · reset dalam '+fmtClock(r);$('stLimT').textContent='Reset '+fmtClock(r);
      if(r<=0){clearInterval(cdT);loadMe().then(render)}};tick();cdT=setInterval(tick,1000)}}
function buildPlans(){const w=$('plans');if(!w)return;w.replaceChildren();
  PLANS.forEach(p=>{const disc=p.final<p.price;w.append(h('button',{class:'plan-c',type:'button','data-d':p.d,onclick:()=>{selPlan=p;buyUpdate()}},
    p.d===30?h('span',{class:'ribbon'},'Paling hemat'):null,disc&&PROMO?h('span',{class:'ptag'},'-'+PROMO.percent+'%'):null,h('small',{class:'pd'},p.label),
    disc?h('s',{class:'old'},rp(p.price)):null,h('b',{},rp(p.final)),h('small',{class:'mut'},'≈ '+rp(Math.round(p.final/p.d))+' / hari')))})}
function buyUpdate(){document.querySelectorAll('.plan-c').forEach(b=>b.classList.toggle('on',!!selPlan&&+b.dataset.d===selPlan.d));
  const a=$('bWa');if(!a)return;const disc=!!selPlan&&selPlan.final<selPlan.price&&!!PROMO;
  $('bSel').textContent=selPlan?`Paket ${selPlan.label} · ${rp(selPlan.final)}${disc?' (promo -'+PROMO.percent+'%)':''}`:'Belum dipilih.';$('bAmt').textContent=selPlan?rp(selPlan.final):'—';
  a.classList.toggle('off',!selPlan);
  if(selPlan){const t=`Halo Admin SPOOFER & REUPLOAD, saya sudah bayar VIP ${selPlan.label} (${rp(selPlan.final)}) via QRIS.`+(disc?`\nPromo: ${PROMO.name} (-${PROMO.percent}%)`:'')+`\nNama: ${ME.name||'-'}\nDiscord ID: ${ME.id||'-'}\nBukti pembayaran saya lampirkan di chat ini.`;a.href=`https://wa.me/${WA}?text=${encodeURIComponent(t)}`}else a.href='#'}
$('bWa').onclick=e=>{if(!selPlan){e.preventDefault();toast('Pilih paket dulu')}};
$('bCopy').onclick=()=>copy(String(ME.id||''),'ID Discord disalin');
function contactUpdate(){if(ME.banned)banContact();const a=$('vWa');if(!a)return;$('vId').textContent=ME.id||'—';
  if(ME.logged_in){const t=`Halo Admin SPOOFER & REUPLOAD, saya mau minta akses VIP.\nNama: ${ME.name||'-'}\nDiscord ID: ${ME.id}\nTolong aktifkan VIP ke akun Discord saya.`;a.href=`https://wa.me/${WA}?text=${encodeURIComponent(t)}`}else a.href='#'}
function promoUI(){const sub=PROMO?(PROMO.secs_left==null?'Berlaku sampai promo dimatikan.':'Berakhir dalam '+fmtDur(PROMO.secs_left)+'.'):'';
  show($('promoBar'),!!PROMO);show($('buyPromo'),!!PROMO);
  if(PROMO){const t=`${PROMO.name} · diskon ${PROMO.percent}%`;$('pbT').textContent=t;$('pbS').textContent=sub;$('bpT').textContent=t;$('bpS').textContent=sub}
  const m=PLANS.length?Math.min(...PLANS.map(p=>p.final)):0;$('buySmall').textContent=m?`Mulai ${rp(m)} · bayar via QRIS`:'Bayar via QRIS'}
$('vCp').onclick=()=>copy(String(ME.id||''),'ID Discord disalin');
$('vRef').onclick=async()=>{await loadMe();render();toast(ME.vip?'VIP aktif':'Belum VIP')};
document.querySelectorAll('#gdSeg button').forEach(b=>b.onclick=()=>{document.querySelectorAll('#gdSeg button').forEach(x=>x.classList.toggle('on',x===b));$('gd').value=b.dataset.d});
buildPlans();loadStats();
