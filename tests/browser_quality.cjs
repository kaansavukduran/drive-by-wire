// Same-viewport render comparison and browser Gamepad API emulation.
// Physical controller, assistive technology and target-device testing remain separate.
const {chromium}=require('playwright');
const fs=require('node:fs');
const path=require('node:path');
const assert=require('node:assert/strict');
const output=process.env.DBW_EVIDENCE_DIR||'work/evidence-v040';
const base=process.env.DBW_URL||'http://127.0.0.1:8765';
fs.mkdirSync(output,{recursive:true});
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.DBW_CHROMIUM||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const results={renderer:'Chromium SwiftShader software; no physical GPU',viewport:[1280,720],modes:{},browserErrors:[]};
 try {
  for(const mode of ['normal','low']) {
   const context=await browser.newContext({viewport:{width:1280,height:720}});
   const page=await context.newPage();
   const requests=[];
   page.on('request',r=>requests.push(r.url()));
   page.on('pageerror',e=>results.browserErrors.push(e.message));
   page.on('console',m=>{if(m.type()==='error')results.browserErrors.push(m.text());});
   await page.addInitScript(()=>{
    const pad={id:'Xbox 360 Controller (XInput STANDARD GAMEPAD)',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};
    window.__pad=pad;
    Object.defineProperty(navigator,'getGamepads',{value:()=>{pad.timestamp=performance.now();return pad.connected?[pad]:[];}});
   });
   await page.goto(`${base}/?qa_render=${mode}`);
   await page.waitForFunction(()=>document.documentElement.dataset.gameState==='started',null,{timeout:60000});
   const tap=async(index)=>{
    await page.evaluate(i=>{window.__pad.buttons[i]={pressed:true,touched:true,value:1};},index);
    await page.waitForTimeout(180);
    await page.evaluate(i=>{window.__pad.buttons[i]={pressed:false,touched:false,value:0};},index);
    await page.waitForTimeout(250);
   };
   await page.evaluate(()=>{const event=new Event('gamepadconnected');Object.defineProperty(event,'gamepad',{value:window.__pad});window.dispatchEvent(event);});
   await tap(0); // Title A, through navigator.getGamepads -> Godot -> native Button.
   await page.waitForFunction(()=>Number(document.documentElement.dataset.gameFps)>0,null,{timeout:15000});
   const samples=[];
   for(let i=0;i<3;i++){
    samples.push(await page.evaluate(()=>Number(document.documentElement.dataset.gameFps)));
    if(i<2)await page.waitForTimeout(5100);
   }
   await page.screenshot({path:path.join(output,`controller-${mode}.png`)});
   const cdp=await context.newCDPSession(page);
   await cdp.send('Performance.enable');
   const metrics=await cdp.send('Performance.getMetrics');
   results.modes[mode]=await page.evaluate(()=>({load_ms:Number(document.documentElement.dataset.loadMs),canvas:[document.querySelector('canvas').width,document.querySelector('canvas').height],display:[document.querySelector('canvas').clientWidth,document.querySelector('canvas').clientHeight],render_mode:document.documentElement.dataset.renderMode}));
   results.modes[mode].fps_samples=samples;
   results.modes[mode].js_heap_bytes=metrics.metrics.find(m=>m.name==='JSHeapUsedSize')?.value;
   results.modes[mode].third_party_requests=requests.filter(url=>new URL(url).origin!==new URL(base).origin);
   assert.deepEqual(results.modes[mode].third_party_requests,[]);
   if(mode==='low')assert.deepEqual(results.modes[mode].canvas,[640,360]);
   await tap(9); // Start pause
   const clip={x:448,y:16,width:384,height:70};
   const before=await page.screenshot({clip});
   await page.waitForTimeout(500);
   assert(before.equals(await page.screenshot({clip})),'Start must pause road');
   await page.screenshot({path:path.join(output,`controller-pause-${mode}.png`)});
   if(mode==='low') {
    await tap(1); // B resumes
    await page.evaluate(()=>{location.hash='accessible-help';});
    await page.waitForTimeout(300);
    assert(await page.locator('#accessible-help').isVisible());
    assert.equal(await page.evaluate(()=>document.activeElement.id),'accessible-help');
    await page.locator('#accessible-help').evaluate(e=>e.style.fontSize='200%');
    const overflow=await page.locator('#accessible-help').evaluate(e=>e.scrollWidth>e.clientWidth);
    assert(!overflow,'200% help text must reflow without horizontal scroll');
    await page.screenshot({path:path.join(output,'accessible-help-200.png')});
    await page.locator('#accessible-help a').click();
    await page.waitForTimeout(250);
    const paused=await page.screenshot({clip});
    await page.waitForTimeout(500);
    assert(paused.equals(await page.screenshot({clip})),'closing HTML help keeps game paused');
    results.html_help='PASS: semantic content, focus, 200% text reflow, world pauses';
   }
   await context.close();
  }
  assert.deepEqual(results.browserErrors,[]);
  fs.writeFileSync(path.join(output,'quality-results.json'),JSON.stringify(results,null,2)+'\n');
  console.log(JSON.stringify(results,null,2));
 } finally {await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
