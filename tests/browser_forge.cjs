// Real Godot web input paths. ?qa exposes read-only state; no gameplay setters.
const {chromium}=require('playwright');
const fs=require('node:fs');
const assert=require('node:assert/strict');
const out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v050';
const base=process.env.DBW_URL||'http://127.0.0.1:8765';
fs.mkdirSync(out,{recursive:true});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{
 const browser=await chromium.launch({executablePath:process.env.DBW_CHROMIUM||'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});
 const result={devices:[],controller:null};
 const devices=[
  {name:'desktop',width:1280,height:720,touch:false},
  {name:'phone-portrait',width:390,height:844,touch:true},
  {name:'phone-landscape',width:844,height:390,touch:true},
  {name:'tablet-portrait',width:768,height:1024,touch:true},
  {name:'tablet-landscape',width:1024,height:768,touch:true},
  {name:'phone-low-power',width:390,height:844,touch:true,low:true},
 ];
 function inside(rect,view){return rect[0]>=-1&&rect[1]>=-1&&rect[0]+rect[2]<=view[0]+1&&rect[1]+rect[3]<=view[1]+1;}
 async function point(page,x,y,id){const q=await page.evaluate(()=>window.__dbwQA);const box=await page.locator('#canvas').boundingBox();return {x:box.x+x*box.width/q.view[0],y:box.y+y*box.height/q.view[1],...(id===undefined?{}:{id})};}
 async function center(page,rect,id){return point(page,rect[0]+rect[2]/2,rect[1]+rect[3]/2,id);}
 async function tap(page,rect,touch){const p=await center(page,rect);if(touch)await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y);}
 async function state(page,screen){await page.waitForFunction(s=>window.__dbwQA?.screen===s,screen,{timeout:20000});return page.evaluate(()=>window.__dbwQA);}
 async function wait(page,fn){await page.waitForFunction(fn,null,{timeout:5000});return page.evaluate(()=>window.__dbwQA);}
 try{
  for(const device of devices){
   const context=await browser.newContext({viewport:{width:device.width,height:device.height},hasTouch:device.touch,isMobile:device.touch});
   const page=await context.newPage();const errors=[];const entry={name:device.name,status:'FAIL',errors};
   page.on('pageerror',e=>errors.push(e.message));page.on('console',m=>{if(m.type()==='error')errors.push(m.text());});
   try{
    await page.goto(`${base}/?qa&qa_render=${device.low?'low':'normal'}`);
    let q=await state(page,'title');
    assert(inside(q.play,q.view),'title play must be on screen');
    await page.screenshot({path:`${out}/${device.name}-title.png`});
    await tap(page,q.garage,device.touch);
    q=await state(page,'garage');await sleep(300);q=await page.evaluate(()=>window.__dbwQA);
    for(const rect of [q.quick,q.speech,q.footer,...q.buttons])assert(inside(rect,q.view),'garage controls must fit');
    for(let i=0;i<q.buttons.length;i++)for(let j=i+1;j<q.buttons.length;j++){const a=q.buttons[i],b=q.buttons[j];assert(!(a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1]),'garage choices must not overlap');}
    if(q.brief_visible&&q.buttons.length)assert(q.brief[1]>=q.buttons.at(-1)[1]+q.buttons.at(-1)[3]-1,'garage brief must clear choices');
    if(device.touch){assert(q.quick[3]>=44);for(const rect of q.buttons)assert(rect[3]>=44);}
    const castBefore=JSON.stringify(q.cast);
    for(const actor of q.cast.actors){const a=actor.rect,b=actor.slot;assert(a[0]>=b[0]&&a[1]>=b[1]&&a[0]+a[2]<=b[0]+b[2]&&a[1]+a[3]<=b[1]+b[3],'actor stays inside its own fixed floor slot');for(const c of [q.speech,q.footer,...q.buttons])assert(!(a[0]<c[0]+c[2]&&a[0]+a[2]>c[0]&&a[1]<c[1]+c[3]&&a[1]+a[3]>c[1]),'actors must not overlap UI');}
    const b=await page.locator('#canvas').boundingBox(),r=q.cast.area;
    const clip={x:b.x+r[0]*b.width/q.view[0],y:b.y+r[1]*b.height/q.view[1],width:r[2]*b.width/q.view[0],height:r[3]*b.height/q.view[1]};
    const beforePixels=await page.screenshot({clip});await sleep(2000);q=await page.evaluate(()=>window.__dbwQA);assert.equal(JSON.stringify(q.cast),castBefore);assert(beforePixels.equals(await page.screenshot({clip})),'garage actor pixels cannot slide between idle frames');
    entry.garageActors='PASS: fixed feet, own slots, no UI overlap and identical rendered pixels over time';
    await tap(page,q.buttons[0],device.touch);q=await wait(page,()=>window.__dbwQA.stage==='upgrade');await sleep(150);q=await page.evaluate(()=>window.__dbwQA);assert.equal(JSON.stringify(q.cast),castBefore,'upgrade must preserve actor slots');
    await page.screenshot({path:`${out}/${device.name}-garage-upgrade.png`});await tap(page,q.buttons[0],device.touch);q=await wait(page,()=>window.__dbwQA.stage==='ready');await sleep(150);q=await page.evaluate(()=>window.__dbwQA);assert.equal(JSON.stringify(q.cast),castBefore,'ready must preserve actor slots');
    if(device.name==='phone-portrait'){
     await page.setViewportSize({width:844,height:390});await wait(page,()=>window.__dbwQA.view[0]>window.__dbwQA.view[1]);await sleep(200);await page.screenshot({path:`${out}/garage-rotated.png`});
     await page.setViewportSize({width:390,height:844});await wait(page,()=>window.__dbwQA.view[1]>window.__dbwQA.view[0]);await sleep(200);q=await page.evaluate(()=>window.__dbwQA);assert.equal(JSON.stringify(q.cast),castBefore,'rotation roundtrip restores floor marks');
    }

    await page.screenshot({path:`${out}/${device.name}-garage.png`});
    await page.keyboard.press('Escape');q=await state(page,'title');
    await tap(page,q.play,device.touch);
    q=await state(page,'briefing');
    await wait(page,()=>{const q=window.__dbwQA;return q.back[1]+q.back[3]<=q.view[1];});
    q=await page.evaluate(()=>window.__dbwQA);
    for(const key of ['panel','back'])assert(inside(q[key],q.view),`briefing ${key} must stay on screen`);
    for(const index of [0,1,3,2]){
     await tap(page,q.tabs[index],device.touch);await page.waitForFunction(i=>window.__dbwQA.page===i,index);await sleep(150);q=await page.evaluate(()=>window.__dbwQA);
     assert.equal(q.scrollbars,0);
     for(const rect of [...q.tabs,q.back,...q.visible_controls])assert(inside(rect,q.view),'every visible page control fits without scrolling');
     for(const rect of q.visible_controls)assert(rect[0]>=q.reading[0]-1&&rect[1]>=q.reading[1]-1&&rect[0]+rect[2]<=q.reading[0]+q.reading[2]+1&&rect[1]+rect[3]<=q.reading[1]+q.reading[3]+1,'content fits bounded page');
     await page.screenshot({path:`${out}/${device.name}-briefing-page${index}.png`});
    }
    await tap(page,q.supplies,device.touch);
    q=await state(page,'run');
    assert.equal(q.paused,false);assert.equal(q.route,'supplies');assert.equal(q.mines,-1);
    if(q.view[1]>q.view[0]){
     const hud=q.portrait_hud;
     for(const rect of Object.values(hud))assert(inside(rect,q.view),'portrait HUD must fit');
     assert(hud.health[1]+hud.health[3]<=hud.energy_bar[1],'health text must clear energy bar');
     assert(hud.meters[1]>=hud.hp_bar[1]+hud.hp_bar[3],'distance must clear health bar');
     assert(hud.meters[0]+hud.meters[2]<=hud.energy[0],'distance must clear energy caption');
     entry.portraitHud='PASS: health, distance and energy do not overlap';
    }
    if(device.touch){
     assert(q.touch,'touch devices must work without external input');
     for(const rect of Object.values(q.actions))assert(inside(rect,q.view),'action must stay on screen');
     const cdp=await context.newCDPSession(page);
     const origin=await center(page,q.joystick,0),fire=await center(page,q.actions.drive_fire,1);
     const px=q.player[0],py=q.player[1];
     const diagonal=await point(page,q.joystick[0]+q.joystick[2]/2+35,q.joystick[1]+q.joystick[3]/2-30,0);
     await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[origin,fire]});
     await wait(page,()=>window.__dbwQA.fire);
     await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[diagonal,fire]});
     await page.waitForFunction(({px,py})=>window.__dbwQA.player[0]>px+12&&window.__dbwQA.player[1]<py-10&&window.__dbwQA.fire,{px,py});
     await page.screenshot({path:`${out}/${device.name}-joystick-fire.png`});
     await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
     await wait(page,()=>!window.__dbwQA.fire&&window.__dbwQA.stick[0]===0&&window.__dbwQA.stick[1]===0);
     q=await page.evaluate(()=>window.__dbwQA);
     const reverse=await point(page,q.joystick[0]+q.joystick[2]/2-35,q.joystick[1]+q.joystick[3]/2+30,0);
     const before=q.player.slice();
     await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[origin]});
     await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[reverse]});
     await page.waitForFunction(p=>window.__dbwQA.player[0]<p[0]-10&&window.__dbwQA.player[1]>p[1]+10,before);
     await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
     q=await page.evaluate(()=>window.__dbwQA);
     const turbo=await center(page,q.actions.drive_boost,0);
     await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[turbo,fire]});
     await wait(page,()=>window.__dbwQA.boost&&window.__dbwQA.fire&&window.__dbwQA.energy<100);
     await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});
     await wait(page,()=>!window.__dbwQA.boost&&!window.__dbwQA.fire&&!window.__dbwQA.paused);
     const boxes=[q.joystick,q.pause,...Object.values(q.actions)];
     for(let i=0;i<boxes.length;i++)for(let j=i+1;j<boxes.length;j++){
      const a=boxes[i],b=boxes[j];assert(!(a[0]<b[0]+b[2]&&a[0]+a[2]>b[0]&&a[1]<b[1]+b[3]&&a[1]+a[3]>b[1]),'joystick/actions/pause must not overlap');
     }
     entry.multitouch='PASS: fixed joystick, diagonal/reverse movement, independent fire and turbo, no pause overlap';
    }else{
     await page.keyboard.down('KeyA');await wait(page,()=>window.__dbwQA.player[0]<280);await page.keyboard.up('KeyA');
     await page.keyboard.down('ArrowRight');await wait(page,()=>window.__dbwQA.player[0]>320);await page.keyboard.up('ArrowRight');
     await page.keyboard.down('KeyW');await wait(page,()=>window.__dbwQA.player[1]<240);await page.keyboard.up('KeyW');
     await page.keyboard.down('KeyS');await wait(page,()=>window.__dbwQA.player[1]>280);await page.keyboard.up('KeyS');
     await page.keyboard.down('KeyE');await wait(page,()=>window.__dbwQA.speed>260);await page.keyboard.up('KeyE');
     await page.keyboard.down('KeyQ');await wait(page,()=>window.__dbwQA.speed<200);await page.keyboard.up('KeyQ');
     q=await page.evaluate(()=>window.__dbwQA);const road=await center(page,q.road);
     await page.mouse.move(road.x,road.y);await page.mouse.down();await wait(page,()=>window.__dbwQA.fire);
     await page.mouse.move(1,1);await page.mouse.up();await wait(page,()=>!window.__dbwQA.fire);
     const mines=q.mine_drops;await page.mouse.move(road.x,road.y);await page.mouse.down({button:'right'});await page.waitForFunction(m=>window.__dbwQA.mine_drops>=m+2,mines);await page.mouse.move(1,1);await page.mouse.up({button:'right'});await wait(page,()=>!window.__dbwQA.mine_held);
     await page.keyboard.press('Shift');await wait(page,()=>window.__dbwQA.support>0);await page.keyboard.press('KeyR');await wait(page,()=>window.__dbwQA.dodge>0);
     assert(await page.evaluate(()=>{const e=new MouseEvent('contextmenu',{bubbles:true,cancelable:true});document.getElementById('canvas').dispatchEvent(e);return e.defaultPrevented;}),'canvas context menu is suppressed for rear mines');
     entry.desktopInput='PASS: continuous XY arrows/WASD, E/Q, mouse fire/right held mines, Shift pulse and R dodge';
    }
    await wait(page,()=>window.__dbwQA.mine_cooldown<=0);q=await page.evaluate(()=>window.__dbwQA);const mines=q.mine_drops;if(device.touch)await tap(page,q.actions.drive_mine,true);else await page.keyboard.press('KeyX');await page.waitForFunction(n=>window.__dbwQA.mine_drops===n+1,mines);q=await page.evaluate(()=>window.__dbwQA);await tap(page,q.pause,device.touch);q=await wait(page,()=>window.__dbwQA.paused);
    const distance=q.distance;await sleep(400);assert.equal((await page.evaluate(()=>window.__dbwQA)).distance,distance,'pause must stop simulation');
    await tap(page,q.pause_menu[1],device.touch);q=await wait(page,()=>{const q=window.__dbwQA;return q.settings&&q.settings_back[1]+q.settings_back[3]<=q.view[1];});
    assert(inside(q.settings_rect,q.view)&&inside(q.settings_back,q.view),'settings must fit');
    await page.screenshot({path:`${out}/${device.name}-settings.png`});
    await tap(page,q.settings_back,device.touch);q=await wait(page,()=>!window.__dbwQA.settings);
    await tap(page,q.pause_menu[5],device.touch);q=await wait(page,()=>{const q=window.__dbwQA;return q.journal&&q.journal_back[1]>q.journal_rect[1]+q.journal_rect[3]-70;});
    assert(inside(q.journal_rect,q.view)&&inside(q.journal_back,q.view),'journal must fit');
    await page.screenshot({path:`${out}/${device.name}-journal.png`});
    await tap(page,q.journal_back,device.touch);q=await wait(page,()=>!window.__dbwQA.journal);
    await tap(page,q.pause_menu[0],device.touch);q=await wait(page,()=>!window.__dbwQA.paused);
    if(device.name==='phone-portrait'){
     await page.setViewportSize({width:844,height:390});
     q=await wait(page,()=>window.__dbwQA.view[0]>window.__dbwQA.view[1]&&window.__dbwQA.paused);
     assert.equal(q.fire,false);for(const rect of Object.values(q.actions))assert(inside(rect,q.view));
     entry.rotation='PASS: portrait -> landscape, safe pause, no held input';
     await page.screenshot({path:`${out}/rotation-paused.png`});
    }
    assert.deepEqual(errors,[],'runtime errors');entry.status='PASS';
   }catch(e){entry.error=String(e);entry.state=await page.evaluate(()=>window.__dbwQA).catch(()=>null);await page.screenshot({path:`${out}/${device.name}-failure.png`}).catch(()=>{});}
   result.devices.push(entry);console.log(JSON.stringify(entry));await context.close();
  }
  const context=await browser.newContext({viewport:{width:1280,height:720}});const page=await context.newPage();
  const padResult={status:'FAIL',errors:[]};page.on('pageerror',e=>padResult.errors.push(e.message));
  try{
   await page.addInitScript(()=>{
    const pad={id:'Xbox 360 Controller (XInput STANDARD GAMEPAD)',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};window.__pad=pad;
    Object.defineProperty(navigator,'getGamepads',{value:()=>{pad.timestamp=performance.now();return pad.connected?[pad]:[];}});
   });
   await page.goto(`${base}/?qa&qa_render=low`);await state(page,'title');
   await page.evaluate(()=>{const e=new Event('gamepadconnected');Object.defineProperty(e,'gamepad',{value:window.__pad});dispatchEvent(e);});
   const press=async(i,on)=>page.evaluate(({i,on})=>window.__pad.buttons[i]={pressed:on,touched:on,value:on?1:0},{i,on});
   const tapPad=async i=>{await press(i,true);await sleep(160);await press(i,false);await sleep(250);};
   await tapPad(13);await tapPad(0);await state(page,'garage');
   await tapPad(13);await tapPad(0);await wait(page,()=>window.__dbwQA.stage==='upgrade');
   await tapPad(0);await wait(page,()=>window.__dbwQA.stage==='ready');
   await tapPad(0);await state(page,'briefing');await tapPad(15);await tapPad(0);
   let q=await state(page,'run');assert.equal(q.route,'supplies');
   await page.evaluate(()=>window.__pad.axes[0]=-0.8);await wait(page,()=>window.__dbwQA.player[0]<280);
   await page.evaluate(()=>window.__pad.axes[0]=0);await sleep(200);
   await page.evaluate(()=>window.__pad.axes[0]=0.8);await wait(page,()=>window.__dbwQA.player[0]>300);
   await page.evaluate(()=>window.__pad.axes[0]=0);
   await press(5,true);await press(7,true);await wait(page,()=>window.__dbwQA.fire&&window.__dbwQA.boost);await press(5,false);await press(7,false);
   await tapPad(9);await wait(page,()=>window.__dbwQA.paused);await tapPad(1);await wait(page,()=>!window.__dbwQA.paused);
   await page.evaluate(()=>{window.__pad.connected=false;const e=new Event('gamepaddisconnected');Object.defineProperty(e,'gamepad',{value:window.__pad});dispatchEvent(e);});
   await wait(page,()=>window.__dbwQA.paused);
   await page.evaluate(()=>{window.__pad.connected=true;const e=new Event('gamepadconnected');Object.defineProperty(e,'gamepad',{value:window.__pad});dispatchEvent(e);});
   await sleep(300);assert((await page.evaluate(()=>window.__dbwQA)).paused);
   await page.screenshot({path:`out/controller-forge.png`.replace('out/',`${out}/`)});
   assert.deepEqual(padResult.errors,[]);padResult.status='PASS';padResult.flow='D-pad/A garage, dialogue, upgrade, route choice, analog, RB/RT, Start/B, disconnect/reconnect';
  }catch(e){padResult.error=String(e);padResult.state=await page.evaluate(()=>window.__dbwQA).catch(()=>null);await page.screenshot({path:`${out}/controller-failure.png`}).catch(()=>{});}
  result.controller=padResult;console.log(JSON.stringify(padResult));await context.close();
  fs.writeFileSync(`${out}/forge-results.json`,JSON.stringify(result,null,2)+'\n');
  assert(result.devices.every(x=>x.status==='PASS')&&padResult.status==='PASS','some browser flows failed; see forge-results.json');
 }finally{await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
