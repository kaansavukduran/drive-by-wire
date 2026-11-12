// A complete story played through real browser keyboard/mouse input.
// QA publishes read-only state; this test never writes Godot state.
const {chromium}=require('playwright');const assert=require('node:assert/strict');const fs=require('node:fs');
const out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v060';fs.mkdirSync(out,{recursive:true});
const base=process.env.DBW_URL||'http://127.0.0.1:8765';
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const result={status:'FAIL',legs:[],errors:[]};try{
 const context=await browser.newContext({viewport:{width:1280,height:720},hasTouch:true});const page=await context.newPage();
 page.on('pageerror',e=>result.errors.push(e.message));page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 const state=()=>page.evaluate(()=>window.__dbwQA);const wait=fn=>page.waitForFunction(fn,null,{timeout:30000});
 const tap=async rect=>{const q=await state();const b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+(rect[0]+rect[2]/2)*b.width/q.view[0],b.y+(rect[1]+rect[3]/2)*b.height/q.view[1]);};
 await page.goto(base+'/?qa&qa_render=low');await wait(()=>window.__dbwQA?.screen==='title');
 await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='briefing');
 for(let stage=0;stage<3;stage++){
  const brief=await state();assert.equal(brief.stage,stage);
  await tap(brief.choices[0]);await wait(()=>window.__dbwQA?.screen==='run');
  assert.equal((await state()).finish,400);await page.keyboard.press('KeyC');await page.keyboard.down('Space');
  const started=Date.now();
  while(true){
   const q=await state();assert.equal(q.screen,'run');
   if(q.over){assert(q.ending_text.includes('ETAP TAMAMLANDI'),'actual combat must survive');result.legs.push({stage:stage+1,distance:q.distance,hp:q.hp,kills:q.kills,collected:q.collected,wall_ms:Date.now()-started});break;}
   assert(Date.now()-started<120000,'chapter timeout');
   if(q.paused)await page.keyboard.press('Escape');
   const pickup=q.pickup_targets.find(p=>p.y>110&&p.y<235);
   if(pickup&&pickup.lane!==q.lane)await page.keyboard.press(pickup.lane<q.lane?'ArrowLeft':'ArrowRight');
   await page.waitForTimeout(150);
  }
  await page.keyboard.up('Space');
  await page.screenshot({path:`${out}/book-leg-${stage+1}-complete.png`});
  await tap((await state()).result[0]);
  await wait(stage===2?()=>window.__dbwQA?.screen==='ending':()=>window.__dbwQA?.screen==='briefing');
 }
 let q=await state();assert(q.unlocked.includes('e01'));
 await page.screenshot({path:`${out}/book-ending-desktop.png`});
 // Scroll prose and open gallery with native focus navigation.
 await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');await wait(()=>window.__dbwQA?.screen==='endings');
 q=await state();assert.equal(q.entries.length,13);assert.equal(q.entries.filter(e=>!e.disabled).length,1);
 await page.screenshot({path:`${out}/book-gallery-desktop.png`});
 await page.setViewportSize({width:390,height:844});await page.waitForTimeout(500);q=await state();
 assert(q.panel[0]>=0&&q.panel[1]>=0&&q.panel[0]+q.panel[2]<=q.view[0]&&q.panel[1]+q.panel[3]<=q.view[1]);
 await page.screenshot({path:`${out}/book-gallery-portrait.png`});
 const b=await page.locator('#canvas').boundingBox();const r=q.entries.find(e=>!e.disabled).rect;
 await page.touchscreen.tap(b.x+(r[0]+r[2]/2)*b.width/q.view[0],b.y+(r[1]+r[3]/2)*b.height/q.view[1]);await wait(()=>window.__dbwQA?.screen==='ending');
 await page.screenshot({path:`${out}/book-ending-portrait.png`});
 // Persisted completion survives a full page/engine reload.
 await page.reload();await wait(()=>window.__dbwQA?.screen==='title');await tap((await state()).endings);await wait(()=>window.__dbwQA?.screen==='endings');
 assert((await state()).unlocked.includes('e01'));
 assert.deepEqual(result.errors,[]);result.status='PASS';result.reload='PASS';result.galleryTouch='PASS';
 console.log(JSON.stringify(result));
 }finally{fs.writeFileSync(`${out}/book-browser-results.json`,JSON.stringify(result,null,2)+'\n');await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
