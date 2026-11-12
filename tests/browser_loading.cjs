// Test actual delayed/failed requests. No fabricated progress percentages or clocks.
const {chromium}=require('playwright');const assert=require('node:assert/strict');const fs=require('node:fs');const crypto=require('node:crypto');
const out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v060';fs.mkdirSync(out,{recursive:true});const base=process.env.DBW_URL||'http://127.0.0.1:8765';const gameVersion=fs.readFileSync('project.godot','utf8').match(/^config\/version="([^"]+)"/m)[1];
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const result={layouts:[],stall:'NOT TESTED',failure:'NOT TESTED'};try{
 for(const [name,width,height] of [['desktop',1280,720],['portrait',390,844],['landscape',844,390]]){
  const context=await browser.newContext({viewport:{width,height},reducedMotion:'reduce'});const page=await context.newPage();let release;const gate=new Promise(r=>release=r);
  await page.route('**/index.wasm',async r=>{await gate;await r.continue();});
  await page.goto(base,{waitUntil:'domcontentloaded'});await page.locator('#status').waitFor({state:'visible'});
  await page.waitForTimeout(900);
  assert.equal(await page.locator('#status-progress span').count(),10);
  const segments=await page.locator('#status-progress span').evaluateAll(items=>items.map(e=>{const r=e.getBoundingClientRect();return {x:r.x,y:r.y,w:r.width,h:r.height};}));assert(segments.every(s=>s.w>10&&s.h>=16&&Math.abs(s.y-segments[0].y)<1));assert(segments[9].x>segments[0].x+200);assert.equal(await page.locator('#status-version').innerText(),'v'+gameVersion);
  const bounds=await page.evaluate(()=>['status-brand','status-title','status-bottom','status-version'].map(id=>{const r=document.getElementById(id).getBoundingClientRect();return {id,inside:r.x>=0&&r.y>=0&&r.right<=innerWidth+1&&r.bottom<=innerHeight+1};}));assert(bounds.every(b=>b.inside),JSON.stringify(bounds));
  const art=await context.request.get(base+'/fragaria-reference.jpg');assert.equal(crypto.createHash('sha256').update(await art.body()).digest('hex'),'e72d624a012cb86e5b21011452fd1a8fb1954b2f19c68b51d8910bebef093828');
  assert((await page.locator('#status').evaluate(e=>getComputedStyle(e).backgroundColor))==='rgb(0, 0, 0)');
  const percent=await page.locator('#status-progress').getAttribute('aria-valuenow');assert(percent===null||Number(percent)>=0&&Number(percent)<=100);
  await page.screenshot({path:`${out}/loading-${name}.png`});
  if(name==='desktop'){
   await page.waitForTimeout(32000);await page.waitForFunction(()=>document.getElementById('status-notice').textContent.includes('uzun sürüyor'),null,{timeout:5000});assert(await page.locator('#status-retry').isVisible());
   await page.screenshot({path:`${out}/loading-stall.png`});result.stall='PASS: actual wasm request held >30s; notice and retry; resumed without fake progress';
  }
  release();await page.waitForFunction(()=>document.documentElement.dataset.gameState==='started',null,{timeout:60000});
  result.layouts.push({name,status:'PASS',version:gameVersion,referenceHash:'PASS',percentWhileHeld:percent});await context.close();
 }
 const context=await browser.newContext({viewport:{width:390,height:844}});const page=await context.newPage();
 await page.route('**/index.pck',r=>r.abort('internetdisconnected'));await page.goto(base);await page.waitForFunction(()=>document.documentElement.dataset.gameState==='failed',null,{timeout:60000});
 assert(await page.locator('#status-retry').isVisible());assert.equal(await page.evaluate(()=>document.activeElement.id),'status-retry');await page.screenshot({path:`${out}/loading-failed-portrait.png`});
 await page.unroute('**/index.pck');await page.locator('#status-retry').click();await page.waitForFunction(()=>document.documentElement.dataset.gameState==='started',null,{timeout:60000});result.failure='PASS: failed PCK request, focused retry, successful reload';await context.close();
 console.log(JSON.stringify(result));
 }finally{fs.writeFileSync(`${out}/loading-results.json`,JSON.stringify(result,null,2)+'\n');await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
