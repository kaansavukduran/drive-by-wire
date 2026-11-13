// Observe real enemy windups through native browser input, never write game state.
const {chromium}=require('playwright');
const assert=require('node:assert/strict');const fs=require('node:fs');
const out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v061';fs.mkdirSync(out,{recursive:true});
const base=process.env.DBW_URL||'http://127.0.0.1:8765';
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
const result={status:'FAIL',seen:[],errors:[],pausedWindup:'NOT TESTED'};
let page;
try{
 const context=await browser.newContext({viewport:{width:1280,height:720}});page=await context.newPage();
 page.on('pageerror',e=>result.errors.push(e.message));page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 const q=()=>page.evaluate(()=>window.__dbwQA);
 const screen=async name=>{await page.waitForFunction(n=>window.__dbwQA?.screen===n,name,{timeout:30000});return q();};
 const tap=async r=>{const s=await q();const b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+(r[0]+r[2]/2)*b.width/s.view[0],b.y+(r[1]+r[3]/2)*b.height/s.view[1]);};
 await page.goto(base+'/?qa&qa_render=low');await tap((await screen('title')).play);
 let captured=false;
 for(let attempt=0;attempt<3&&!captured;attempt++){
  let s=await screen('briefing');await tap(s.choices[0]);await screen('run');await page.keyboard.press('KeyC');
  const start=Date.now();let supportAt=Date.now();
  while(Date.now()-start<65000){
   s=await q();assert.equal(s.screen,'run');
   if(s.over)break;
   if(s.paused){await page.keyboard.press('Escape');await page.waitForTimeout(200);continue;}
   for(const w of s.warnings){if(!result.seen.includes(w.kind))result.seen.push(w.kind);assert(w.progress>=0&&w.progress<=1);}
   const cue=s.warnings.find(w=>['shot','drop'].includes(w.kind)&&w.progress<0.4);
   if(cue){
    // Existing optional chat slows time through real input, keeping the short cue readable for the screenshot.
    await page.keyboard.press('KeyT');await page.waitForTimeout(100);await page.screenshot({path:`${out}/warning-${cue.kind}-live.png`});
    await page.keyboard.press('Escape');await page.keyboard.press('KeyP');await page.waitForFunction(()=>window.__dbwQA.paused);
    const before=(await q()).warnings;if(!before.some(w=>['shot','drop'].includes(w.kind))){result.races=(result.races||0)+1;await page.keyboard.press('Escape');continue;}
    await page.waitForTimeout(500);assert.deepEqual((await q()).warnings,before,'pause must freeze vital warning target/progress');
    result.pausedWindup='PASS';result.sample=before.find(w=>['shot','drop'].includes(w.kind));captured=true;break;
   }
   const danger=new Set(s.warnings.filter(w=>['rear','ram','shot','drop'].includes(w.kind)).map(w=>w.lane));
   if(danger.has(s.lane)){
    const lane=[0,1,2].filter(l=>!danger.has(l)).sort((a,b)=>Math.abs(a-s.lane)-Math.abs(b-s.lane))[0];
    if(lane!==undefined)await page.keyboard.press(lane<s.lane?'ArrowLeft':'ArrowRight');
    else await page.keyboard.press('KeyR');
   }else{
    const pickup=s.pickup_targets.find(p=>p.y>100&&p.y<235&&!danger.has(p.lane));
    if(pickup&&pickup.lane!==s.lane)await page.keyboard.press(pickup.lane<s.lane?'ArrowLeft':'ArrowRight');
   }
   if(Date.now()-supportAt>8200){await page.keyboard.press('KeyC');supportAt=Date.now();}
   await page.waitForTimeout(100);
  }
  if(!captured){s=await q();assert(s.over,'attempt should finish rather than hang');await tap(s.result[0]);}
 }
 assert(captured,'a real shooter/truck windup must be observed within three chapters');
 assert.deepEqual(result.errors,[]);result.status='PASS';console.log(JSON.stringify(result));
}catch(e){result.error=String(e);if(page){result.state=await page.evaluate(()=>window.__dbwQA).catch(()=>null);await page.screenshot({path:`${out}/warnings-failure.png`}).catch(()=>{});}throw e;}
finally{fs.writeFileSync(`${out}/warnings-browser-results.json`,JSON.stringify(result,null,2)+'\n');await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
