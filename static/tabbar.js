/* Lensa kaca geser di tab bar bawah: geser jari atau ketuk, lensa melar lalu mendarat di tab */
(function(){
 const bar=document.getElementById('tabbar');if(!bar)return;
 const btns=[...bar.querySelectorAll('button')],lens=document.createElement('div');lens.className='tb-lens';bar.prepend(lens);
 let drag=false,cur=btns[0],hot=null;
 const act=()=>bar.querySelector('button.on')||cur;
 function put(b,anim){if(!b)return;cur=b;lens.style.setProperty('--lx',b.offsetLeft+'px');lens.style.setProperty('--lw',b.offsetWidth+'px');lens.classList.add('rdy');
  if(anim){lens.classList.remove('st');void lens.offsetWidth;lens.classList.add('st')}}
 function near(x){const r=bar.getBoundingClientRect();let best=btns[0],d=1e9;btns.forEach(b=>{const c=r.left+b.offsetLeft+b.offsetWidth/2,k=Math.abs(c-x);if(k<d){d=k;best=b}});return best}
 function setHot(b){if(hot===b)return;hot&&hot.classList.remove('hot');hot=b;b&&b.classList.add('hot')}
 bar.addEventListener('pointerdown',e=>{drag=true;bar.classList.add('drag');try{bar.setPointerCapture(e.pointerId)}catch(_){}
  const b=near(e.clientX);setHot(b);put(b,true)});
 bar.addEventListener('pointermove',e=>{if(!drag)return;const b=near(e.clientX);setHot(b);
  const r=bar.getBoundingClientRect(),w=b.offsetWidth,x=Math.max(4,Math.min(r.width-w-4,e.clientX-r.left-w/2));
  lens.style.transition='width .2s,opacity .2s';lens.style.setProperty('--lx',x+'px');lens.style.setProperty('--lw',w+'px');cur=b});
 function end(e,cancel){if(!drag)return;drag=false;lens.style.transition='';bar.classList.remove('drag');const b=cancel?null:near(e.clientX);setHot(null);
  if(b){if(b.id==='tbMenu'){put(act(),true);b.click()}else{b.click();put(b,true);setTimeout(()=>put(act(),false),160)}}else put(act(),false)}
 bar.addEventListener('pointerup',e=>end(e,false));bar.addEventListener('pointercancel',e=>end(e,true));
 bar.addEventListener('click',e=>{if(e.isTrusted&&e.detail>0){e.stopPropagation();e.preventDefault()}},true);
 new MutationObserver(()=>{if(!drag){const a=bar.querySelector('button.on');if(a&&a!==cur)put(a,true)}}).observe(bar,{subtree:true,attributes:true,attributeFilter:['class']});
 addEventListener('resize',()=>put(act(),false));
 requestAnimationFrame(()=>requestAnimationFrame(()=>put(act(),false)));
})();
