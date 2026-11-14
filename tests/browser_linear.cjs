// Real input only. QA is an observer: no game/save setters, no teleport or HP edits.
const {chromium}=require('playwright'),fs=require('node:fs'),assert=require('node:assert/strict');
const assertHud=require('./hud_contract.cjs');
const base=process.env.DBW_URL||'http://127.0.0.1:8915',mode=process.env.DBW_INPUT||'keyboard',out=process.env.DBW_EVIDENCE_DIR||'work/v012/browser-'+mode;
fs.mkdirSync(out,{recursive:true});const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const result={status:'FAIL',input:mode,errors:[],combat:[],interludes:[],bosses:[]};let page;
try{
 const context=await browser.newContext({viewport:mode==='touch'?{width:390,height:844}:{width:1280,height:720},hasTouch:mode==='touch',isMobile:mode==='touch'});page=await context.newPage();const cdp=await context.newCDPSession(page);
 page.on('pageerror',e=>result.errors.push(e.message));page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 if(mode==='pad')await page.addInitScript(()=>{const p={id:'Xbox 360 Controller (XInput STANDARD GAMEPAD)',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};window.__pad=p;Object.defineProperty(navigator,'getGamepads',{value:()=>{p.timestamp=performance.now();return[p];}});});
 const state=()=>page.evaluate(()=>window.__dbwQA),wait=fn=>page.waitForFunction(fn,null,{timeout:30000});
 const button=async(i,on)=>page.evaluate(({i,on})=>window.__pad.buttons[i]={pressed:on,touched:on,value:on?1:0},{i,on});
 const tapPad=async i=>{await button(i,true);await sleep(100);await button(i,false);await sleep(120);};
 const axis=async v=>page.evaluate(v=>window.__pad.axes[0]=v,v);
 const point=async(r,id)=>{const q=await state(),b=await page.locator('#canvas').boundingBox();return{x:b.x+(r[0]+r[2]/2)*b.width/q.view[0],y:b.y+(r[1]+r[3]/2)*b.height/q.view[1],...(id===undefined?{}:{id})};};
 const tap=async r=>{if(mode==='pad')return tapPad(0);const p=await point(r);if(mode==='touch')await page.touchscreen.tap(p.x,p.y);else await page.mouse.click(p.x,p.y);};
 await page.goto(base+'/?qa&qa_render=low');await wait(()=>window.__dbwQA?.screen==='title');
 if(mode==='pad')await page.evaluate(()=>{const e=new Event('gamepadconnected');Object.defineProperty(e,'gamepad',{value:window.__pad});dispatchEvent(e);});
 await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='briefing');
 let touchActive=false,held='',mine=false;
 const release=async()=>{if(mode==='pad'){await button(7,false);await button(2,false);await axis(0);}else if(mode==='touch'){if(touchActive)await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});touchActive=false;}else{if(held)await page.keyboard.up(held);held='';await page.mouse.up({button:'left'});if(mine)await page.mouse.up({button:'right'});mine=false;}};
 for(let stage=0;stage<2;stage++){
  let q=await state();assert.equal(q.stage,stage);assert.equal(q.radio_answers.length,3,'three meaningful dialogue replies');
  const choice=mode==='touch'?2:mode==='pad'?1:0;const prompt=q.reply_text;
  if(!q.reply_ready){if(mode==='pad')for(let i=0;i<choice;i++)await tapPad(13);await tap(q.radio_answers[choice]);await wait(()=>window.__dbwQA.reply_ready);q=await state();assert(q.radio_selected);assert.notEqual(q.reply_text,prompt);}
  await tap(q.reply_continue);await wait(()=>window.__dbwQA?.screen==='run');
  assert.equal((await state()).health_panel_visible,false);assert.deepEqual(Object.keys((await state()).actions).sort(),['drive_fire','drive_mine']);
  const biomes=new Set(),seenTraffic=new Set();let rearSpawns=0;
  const start=Date.now();
  if(mode==='pad')await button(7,true);else if(mode==='keyboard'){const p=await point((await state()).road);await page.mouse.move(p.x,p.y);await page.mouse.down({button:'left'});}
  while(true){q=await state();assert.equal(q.screen,'run');assertHud(q);
   biomes.add(q.biome);assert.equal(biomes.size,1,'a stage cannot change biome mid-drive');
   for(const e of q.traffic){if(!seenTraffic.has(e.id)){seenTraffic.add(e.id);if(e.spawn_y>0){rearSpawns++;assert(e.y-54>q.camera_bottom,'new rear traffic is wholly beyond camera');}}}
   if(q.over){await release();result.combat.push({stage:stage+1,biome:[...biomes][0],rearSpawns,hp:q.hp,distance:q.distance,boss:q.boss,ending:q.ending_text});assert(q.boss.defeated&&q.ending_text.includes('ETAP TAMAMLANDI'),'actual boss victory, not timeout/death');break;}
   assert(Date.now()-start<140000,'combat timeout');
   if(q.boss.active&&!result.bosses.some(b=>b.name===q.boss.name&&b.phase===q.boss.phase)){result.bosses.push({name:q.boss.name,phase:q.boss.phase});await page.screenshot({path:out+`/stage${stage+1}-boss${q.boss.phase}.png`});}
   const [px,py]=q.player;let best=q.lane,bestCost=Infinity;
   for(let lane=0;lane<3;lane++){const x=256+lane*64;let cost=Math.abs(x-px)*.04;for(const e of q.traffic)if(e.lane===lane&&Math.abs(e.y-py)<165)cost+=(165-Math.abs(e.y-py))*2;for(const o of q.hazards)if(Math.abs(o.x-x)<25&&Math.abs(o.y-py)<150)cost+=250;if(q.pickup_targets.some(p=>p.lane===lane&&p.y>130&&p.y<py))cost-=30;if(q.boss.active){for(const t of q.boss.targets)if(Math.abs(t[0]-x)<34)cost+=180;if(q.boss.rear)cost+=Math.abs(q.boss.position[0]-x)*.5;}if(cost<bestCost){bestCost=cost;best=lane;}}
   const dx=256+best*64-px,v=Math.abs(dx)<8?0:Math.sign(dx)*.95,rear=q.boss.rear||q.traffic.some(e=>Math.abs(e.x-px)<26&&e.y>py+25&&e.y<py+140);
   if(mode==='pad'){await axis(v);await button(2,rear);}
   else if(mode==='touch'){
    const j=q.joystick,b=await page.locator('#canvas').boundingBox(),origin=await point(j,0);origin.x+=v*j[2]*.43*b.width/q.view[0];const fire=await point(q.actions.drive_fire,1),points=[origin,fire];if(rear)points.push(await point(q.actions.drive_mine,2));
    if(touchActive)await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:points});touchActive=true;
   }else{const next=v<0?'ArrowLeft':v>0?'ArrowRight':'';if(next!==held){if(held)await page.keyboard.up(held);if(next)await page.keyboard.down(next);held=next;}if(rear!==mine){if(rear)await page.mouse.down({button:'right'});else await page.mouse.up({button:'right'});mine=rear;}}
   await sleep(100);
  }
  q=await state();if(mode==='pad'){await axis(-.9);await wait(()=>window.__dbwQA.result_focus===0);await axis(0);}await tap(q.result[0]);await wait(()=>window.__dbwQA?.screen==='road_story');
  const steps=new Set(),frames=new Set();let rotated=false,reloaded=false;const started=Date.now();
  while((await state()).screen==='road_story'){
   q=await state();assert.equal(q.interlude,stage+1);assert(q.fits,'compact dialogue must retain all words in its actual bounds');assert(!q.combat);assert(Date.now()-started<150000,'interlude timeout');
   if(q.cliff?.aion_car){assert(q.cliff.aion_car[1]-37>=q.cliff.edge_y,'car never crosses visible cliff rim');if(q.cliff.actors)frames.add(q.cliff.frame);}
   if(!steps.has(q.chapter.step)){steps.add(q.chapter.step);await page.screenshot({path:out+`/interlude${stage+1}-${q.chapter.step}.png`});}
   if(q.paused){await tap(q.resume);continue;}
   if(stage===1&&q.chapter.step==='check'&&mode==='touch'&&!rotated){const pos=q.cliff.kurt_foot;await page.setViewportSize({width:844,height:390});await wait(()=>window.__dbwQA.paused);assert.deepEqual((await state()).cliff.kurt_foot,pos);await tap((await state()).resume);rotated=true;continue;}
   if(stage===1&&q.chapter.step==='thanks'&&mode==='keyboard'&&!reloaded){await page.reload();await wait(()=>window.__dbwQA?.screen==='title');await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='road_story');assert.equal((await state()).chapter.step,'thanks');reloaded=true;continue;}
   if(['race','trap','approach','impact','brake','exit'].includes(q.chapter.step)){await sleep(75);continue;}
   if(q.choices.length)await tap(q.choices[0]);else if(q.next_visible)await tap(q.next);await sleep(150);
  }
  assert(steps.has(stage===0?'trap':'impact')&&steps.has(stage===0?'eren':'promise'));
  if(stage===1){assert(frames.has(0)&&frames.has(1)&&frames.has(2)&&frames.has(3),'all four new Kurt poses actually play');result.cliffFrames=[...frames];result.cliffReload=reloaded;result.cliffRotation=rotated;}
  result.interludes.push({number:stage+1,steps:[...steps]});
  await wait(stage===0?()=>window.__dbwQA?.screen==='briefing':()=>window.__dbwQA?.screen==='ending');
 }
 let q=await state();assert.equal(q.title,'DEVAM EDECEK');assert.equal(q.stage,2);assert.equal(q.phase,'continued');assert.equal(q.scrollbars,0);
 const prose=[];while(true){q=await state();assert(q.reader.fits);prose.push(q.reader.text);if(q.reader.page+1===q.reader.pages)break;if(mode==='pad')await tapPad(15);else if(mode==='touch')await tap(q.reader.next);else await page.keyboard.press('ArrowRight');await sleep(180);}
 assert(prose.join(' ').includes('yeni bir araba'));assert(prose.join(' ').includes('oynanamaz'));await page.screenshot({path:out+'/continued.png'});
 await page.reload();await wait(()=>window.__dbwQA?.screen==='title');await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='ending');assert.equal((await state()).phase,'continued');result.reopen='PASS: stays at continued; no unbuilt third stage';
 assert.deepEqual(result.errors,[]);result.status='PASS';console.log(JSON.stringify(result));
}catch(e){result.error=String(e);if(page)try{await page.screenshot({path:out+'/failure.png'});}catch{}throw e;}finally{fs.writeFileSync(out+'/linear-results.json',JSON.stringify(result,null,2)+'\n');await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
