// Cross-engine opening check. Desktop Firefox is not a physical Android/iOS test.
const {chromium,firefox}=require('playwright');
const assert=require('node:assert/strict');const fs=require('node:fs');
const kind=process.env.DBW_BROWSER||'chromium';
const base=process.env.DBW_URL||'http://127.0.0.1:8877';
const out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v070';fs.mkdirSync(out,{recursive:true});
(async()=>{
 const browser=kind==='firefox'?await firefox.launch({headless:true,firefoxUserPrefs:{'webgl.force-enabled':true,'webgl.disabled':false,'gfx.webrender.software':true}}):await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const result={browser:kind,version:browser.version(),platform:'Linux automated desktop',status:'FAIL',errors:[]};
 try{
  const ctx=await browser.newContext({viewport:{width:1280,height:720}});const page=await ctx.newPage();
  page.on('pageerror',e=>result.errors.push(e.message));
  await page.goto(base+'/?qa&qa_render=normal');
  await page.waitForFunction(()=>window.__dbwQA?.screen==='title'||document.documentElement.dataset.gameState==='failed',null,{timeout:90000});
  const failed=await page.evaluate(()=>document.documentElement.dataset.gameState==='failed');
  if(failed){
   result.notice=await page.locator('#status-notice').innerText();
   result.status='BLOCKED';await page.screenshot({path:`${out}/${kind}-blocked.png`});
  }else{
   const metadata=await page.evaluate(async()=>{const r=await fetch('/version.json',{cache:'no-store'});return r.json();});
   assert.equal(await page.evaluate(()=>document.documentElement.dataset.release),metadata.version);
   assert.equal(new URL(page.url()).pathname,metadata.entry);
   result.commit=metadata.commit;result.game_version=metadata.version;
   const tap=async field=>{const q=await page.evaluate(()=>window.__dbwQA),r=q[field],b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+(r[0]+r[2]/2)*b.width/q.view[0],b.y+(r[1]+r[3]/2)*b.height/q.view[1]);};
   await tap('play');await page.waitForFunction(()=>window.__dbwQA.screen==='briefing');
   await tap('steady');await page.waitForFunction(()=>window.__dbwQA.screen==='run');
   const x=await page.evaluate(()=>window.__dbwQA.player[0]);await page.keyboard.down('KeyD');
   await page.waitForFunction(x=>window.__dbwQA.player[0]>x+25,x);await page.keyboard.up('KeyD');
   await page.keyboard.press('Escape');await page.waitForFunction(()=>window.__dbwQA.paused);
   await page.screenshot({path:`${out}/${kind}-open.png`});
   await page.reload();await page.waitForFunction(()=>window.__dbwQA?.screen==='title',null,{timeout:90000});
   assert.deepEqual(result.errors,[]);result.status='PASS';result.flow='root/versioned entry, scene start, keyboard XY, pause, reload';
  }
 }catch(e){result.error=String(e).split('\n')[0];throw e;}
 finally{fs.writeFileSync(`${out}/${kind}-open.json`,JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));await browser.close();}
})().catch(e=>{console.error(String(e).split('\n')[0]);process.exitCode=1;});
