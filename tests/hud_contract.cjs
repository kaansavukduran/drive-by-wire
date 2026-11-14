const assert=require('node:assert/strict');
// Ignore intentional modal occlusion; ordinary world labels must never share ink.
module.exports=function assertHud(q){
 const widgets=q.radio_ui?.widgets||[];
 for(const w of widgets){assert(w.fits,`HUD text fits: ${w.id||w.text}`);assert(w.rect[0]>=-1&&w.rect[1]>=-1&&w.rect[0]+w.rect[2]<=q.view[0]+1&&w.rect[1]+w.rect[3]<=q.view[1]+1,`HUD stays on screen: ${w.id||w.text}`);}
 if(q.paused||q.over)return;
 const bounds=w=>{const a=w.rect,o=w.outline||0;return[a[0]-o,a[1]-o,a[2]+o*2,a[3]+o*2];};
 for(let i=0;i<widgets.length;i++)for(let j=i+1;j<widgets.length;j++){
  const a=bounds(widgets[i]),b=bounds(widgets[j]);
  assert(!(a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1]),`HUD overlap: ${widgets[i].id||widgets[i].text} / ${widgets[j].id||widgets[j].text}`);
 }
};
