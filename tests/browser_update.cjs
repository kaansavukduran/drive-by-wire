// Exercise an upgrade in ONE browser profile with a deliberately stale HTTP cache.
// First copy the previous build/web into work/legacy-v061, then build the new version.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const http=require('node:http');
const assert=require('node:assert/strict');
const legacy=path.resolve(process.env.DBW_LEGACY_BUILD||'work/legacy-v061');
const current=path.resolve('build/web');
const output=process.env.DBW_EVIDENCE_DIR||'work/evidence-update';
const manifest=JSON.parse(fs.readFileSync(path.join(current,'version.json')));
assert(fs.existsSync(path.join(legacy,'index.pck')),'prepare the previous flat web export first');
fs.mkdirSync(output,{recursive:true});
let active=legacy,future=false;
const futureEntry='/play/0.6.3-222222222222/';
const types={'.html':'text/html; charset=utf-8','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.png':'image/png','.ttf':'font/ttf'};
const server=http.createServer((req,res)=>{
 const url=new URL(req.url,'http://localhost');
 if(future&&url.pathname==='/version.json'){
  res.writeHead(200,{'Content-Type':'application/json','Cache-Control':'no-store'});
  res.end(JSON.stringify({...manifest,commit:'2'.repeat(40),entry:futureEntry}));return;
 }
 if(future&&url.pathname===futureEntry){res.writeHead(200,{'Content-Type':'text/html'});res.end('<h1>Test update destination</h1>');return;}
 let file=path.resolve(active,'.'+decodeURIComponent(url.pathname));
 if(!file.startsWith(active+path.sep)&&file!==active){res.writeHead(403);res.end();return;}
 try{
  if(fs.statSync(file).isDirectory())file=path.join(file,'index.html');
  const data=fs.readFileSync(file);
  res.writeHead(200,{'Content-Type':types[path.extname(file)]||'application/octet-stream','Cache-Control':active===legacy?'public, max-age=31536000, immutable':'no-store'});
  res.end(data);
 }catch{res.writeHead(404);res.end();}
});
async function savedFiles(page){
 return page.evaluate(async()=>{
  const found=[];
  for(const meta of await indexedDB.databases()){
   if(!meta.name.startsWith('/userfs'))continue;
   const db=await new Promise((resolve,reject)=>{const req=indexedDB.open(meta.name);req.onsuccess=()=>resolve(req.result);req.onerror=()=>reject(req.error);});
   if(db.objectStoreNames.contains('FILE_DATA')){
    await new Promise((resolve,reject)=>{
     const tx=db.transaction('FILE_DATA','readonly');const req=tx.objectStore('FILE_DATA').openCursor();
     req.onsuccess=()=>{const c=req.result;if(!c)return;if(String(c.key).endsWith('/save.json'))found.push(JSON.parse(new TextDecoder().decode(c.value.contents)));c.continue();};
     tx.oncomplete=resolve;tx.onerror=()=>reject(tx.error);
    });
   }
   db.close();
  }
  return found;
 });
}
(async()=>{
 await new Promise(resolve=>server.listen(0,'127.0.0.1',resolve));
 const origin=`http://127.0.0.1:${server.address().port}`;
 const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const result={fixture:'synthetic immutable legacy HTTP cache; same origin and profile',version:manifest.version,status:'FAIL'};
 try{
  const ctx=await browser.newContext({viewport:{width:390,height:844},hasTouch:true,isMobile:true});
  const page=await ctx.newPage();const errors=[];
  page.on('pageerror',e=>errors.push(e.message));
  const state=()=>page.evaluate(()=>window.__dbwQA);
  const screen=s=>page.waitForFunction(s=>window.__dbwQA?.screen===s,s,{timeout:90000});
  const tap=async rect=>{const q=await state(),b=await page.locator('#canvas').boundingBox();await page.touchscreen.tap(b.x+(rect[0]+rect[2]/2)*b.width/q.view[0],b.y+(rect[1]+rect[3]/2)*b.height/q.view[1]);};
  await page.goto(origin+'/?qa&qa_render=normal');await screen('title');
  assert.equal(await page.evaluate(()=>document.documentElement.dataset.release),undefined);
  await page.evaluate(()=>localStorage.setItem('dbw.upgrade-test','keep'));
  await tap((await state()).garage);await screen('garage');
  await tap((await state()).buttons[0]);
  await page.waitForTimeout(1500);
  const before=await savedFiles(page);assert(before.length>0,'the real garage choice must persist a Godot save');
  result.legacy_save={trust:before[0].trust,runs:before[0].memory.runs};
  // The same profile retains the old root HTML/JS/PCK after the server changes.
  active=current;
  const stale=await page.goto(origin+'/?qa&qa_render=normal');
  assert((await stale.text()).includes('v0.6.1'),'the fixture must really retain old cached HTML');
  // A cached old shell may keep running OR fail when it asks for replaced files.
  // Do not require that old executable to finish loading before using /play/.
  result.stale_cache_reproduced=true;
  const assetPaths=[];page.on('request',r=>{if(/\.(pck|wasm|js)$/.test(new URL(r.url()).pathname))assetPaths.push(new URL(r.url()).pathname);});
  await page.goto(origin+'/play/?qa&qa_render=normal');errors.length=0;await screen('title');
  assert.equal(await page.evaluate(()=>document.documentElement.dataset.release),manifest.version);
  assert(new URL(page.url()).pathname===manifest.entry);
  assert(assetPaths.some(p=>p.endsWith('.pck'))&&assetPaths.some(p=>p.endsWith('.wasm')));
  assert(assetPaths.every(p=>p.startsWith(manifest.entry)),'all game files must come from the new release directory');
  assert.equal(await page.evaluate(()=>localStorage.getItem('dbw.upgrade-test')),'keep');
  const after=await savedFiles(page);assert.deepEqual(after,before,'update must preserve the real Godot save');
  result.cache_upgrade='PASS';result.save_preserved='PASS';result.asset_paths=assetPaths;
  await page.screenshot({path:path.join(output,'updated-phone-title.png')});
  await tap((await state()).play);await screen('briefing');await tap((await state()).choices[1]);await screen('run');
  const q=await state();assert(q.touch&&q.view[1]>q.view[0]);assert.equal(q.finish,400);
  await tap(q.pause);await page.waitForFunction(()=>window.__dbwQA.paused);
  const distance=(await state()).distance;
  future=true;
  await page.waitForTimeout(15500);
  await page.evaluate(()=>dispatchEvent(new Event('focus')));
  await page.locator('#release-notice').waitFor({state:'visible'});
  assert.equal((await state()).distance,distance,'update notice must not unpause or replace the game');
  await page.screenshot({path:path.join(output,'update-notice.png')});
  await page.locator('#release-open').click();await page.waitForURL(url=>url.pathname===futureEntry);
  result.future_update_notice='PASS';
  await ctx.close();
  // A clean root navigation must also reach the new release automatically.
  future=false;const clean=await browser.newContext({viewport:{width:390,height:844},hasTouch:true,isMobile:true});const fresh=await clean.newPage();
  await fresh.goto(origin+'/?qa');await fresh.waitForFunction(()=>window.__dbwQA?.screen==='title',null,{timeout:90000});
  assert.equal(new URL(fresh.url()).pathname,manifest.entry);await clean.close();
  assert.deepEqual(errors,[]);result.runtime_errors=errors;result.root_entry='PASS';result.status='PASS';
 }catch(e){result.error=e.message;throw e;}
 finally{fs.writeFileSync(path.join(output,'update-results.json'),JSON.stringify(result,null,2)+'\n');console.log(JSON.stringify(result));await browser.close();server.close();}
})().catch(e=>{console.error(e.message);process.exitCode=1;server.close();});
