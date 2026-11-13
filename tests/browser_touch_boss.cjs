// Actual fixed joystick + action fingers; no game or save setters.
const {chromium}=require('playwright'),fs=require('node:fs'),assert=require('node:assert/strict');
const base=process.env.DBW_URL||'http://127.0.0.1:8877',out=process.env.DBW_EVIDENCE_DIR||'work/touch-boss';fs.mkdirSync(out,{recursive:true});
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const result={status:'FAIL',errors:[]};try{
 const context=await browser.newContext({viewport:{width:390,height:844},hasTouch:true,isMobile:true}),page=await context.newPage(),cdp=await context.newCDPSession(page);
 page.on('pageerror',e=>result.errors.push(e.message));page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 const state=()=>page.evaluate(()=>window.__dbwQA),wait=fn=>page.waitForFunction(fn,null,{timeout:30000});
 const point=async(x,y,id)=>{const q=await state(),b=await page.locator('#canvas').boundingBox();return{x:b.x+x*b.width/q.view[0],y:b.y+y*b.height/q.view[1],id};};
 const center=async(r,id)=>point(r[0]+r[2]/2,r[1]+r[3]/2,id);
 const tap=async r=>{const p=await center(r,0);await page.touchscreen.tap(p.x,p.y);};
 await page.goto(base+'/?qa&qa_render=normal');await wait(()=>window.__dbwQA?.screen==='title');await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='briefing');await tap((await state()).choices[0]);await wait(()=>window.__dbwQA?.screen==='run');
 let stick,action='',active=false,rotated=false,lastPulse=0;const started=Date.now();
 const release=async()=>{if(active)await cdp.send('Input.dispatchTouchEvent',{type:'touchEnd',touchPoints:[]});active=false;action='';};
 while(true){let q=await state();assert.equal(q.screen,'run');if(q.over){result.terminal={hp:q.hp,distance:q.distance,boss:q.boss,ending:q.ending_text};assert(q.boss.defeated&&q.ending_text.includes('ETAP TAMAMLANDI'));result.boss=q.boss.name;result.hp=q.hp;result.distance=q.distance;break;}assert(Date.now()-started<150000,'touch boss stage timed out');
  for(const w of q.radio_ui.widgets)assert(w.fits,'touch HUD text fit: '+w.text);
  if(q.boss.active&&q.boss.phase===2&&!rotated){await release();await page.screenshot({path:out+'/portrait-boss-phase2.png'});await page.setViewportSize({width:844,height:390});await wait(()=>window.__dbwQA.paused&&window.__dbwQA.view[0]>window.__dbwQA.view[1]);q=await state();const pausedPos=q.player.slice();await page.waitForTimeout(200);assert.deepEqual((await state()).player,pausedPos);await page.screenshot({path:out+'/landscape-boss-paused.png'});await tap(q.pause_menu[0]);await wait(()=>!window.__dbwQA.paused);rotated=true;q=await state();}
  let best=q.lane,bestCost=Infinity;const [px,py]=q.player;
  for(let lane=0;lane<3;lane++){const x=256+lane*64;let cost=Math.abs(x-px)*.04;for(const e of q.traffic)if(e.lane===lane&&Math.abs(e.y-py)<165)cost+=(165-Math.abs(e.y-py))*2;for(const o of q.hazards)if(Math.abs(o.x-x)<25&&Math.abs(o.y-py)<150)cost+=250;if(q.pickup_targets.some(p=>p.lane===lane&&p.y>130&&p.y<py))cost-=30;if(q.boss.active){for(const p of q.boss.targets)if(Math.abs(p[0]-x)<34)cost+=180;if(q.boss.rear)cost+=Math.abs(q.boss.position[0]-x)*.5;}for(const warning of q.warnings)if(['shot','drop'].includes(warning.kind)&&Math.abs(warning.target[0]-x)<34)cost+=160;if(cost<bestCost){bestCost=cost;best=lane;}}
  const dx=256+best*64-px,axis=Math.abs(dx)<8?0:Math.sign(dx)*.98,j=q.joystick;
  stick=await point(j[0]+j[2]/2+axis*j[2]*.43,j[1]+j[3]/2,0);
  const rearThreat=q.traffic.some(e=>Math.abs(e.x-px)<26&&e.y>py+25&&e.y<py+140);
  const wanted=q.boss.rear?'drive_mine':'drive_fire';
  if(action!==wanted&&active)await release();
  const finger=await center(q.actions[wanted],1);
  if(!active){await cdp.send('Input.dispatchTouchEvent',{type:'touchStart',touchPoints:[stick,finger]});active=true;action=wanted;}else await cdp.send('Input.dispatchTouchEvent',{type:'touchMove',touchPoints:[stick,finger]});
  const auxiliary=rearThreat&&q.mine_cooldown<=0?'drive_mine':q.traffic.some(e=>Math.abs(e.x-px)<28&&Math.abs(e.y-py)<60)&&q.dodge<=0?'drive_dodge':(Date.now()-lastPulse>8500?'drive_comfort':'');
  if(auxiliary){await release();await tap(q.actions[auxiliary]);if(auxiliary==='drive_comfort')lastPulse=Date.now();}
  await page.waitForTimeout(100);
 }
 await release();assert(rotated);await page.screenshot({path:out+'/touch-boss-victory.png'});
 await tap((await state()).result[0]);await wait(()=>window.__dbwQA?.screen==='briefing');await tap((await state()).choices[0]);await wait(()=>window.__dbwQA?.screen==='road_story');
 await page.setViewportSize({width:390,height:844});await page.waitForTimeout(400);if((await state()).paused)await tap((await state()).resume);
 const seen=new Set(),storyStart=Date.now();
 while((await state()).screen==='road_story'){
  const n=await state();assert(n.fits);assert.equal(n.combat,false);assert(Date.now()-storyStart<100000);
  if(!seen.has(n.chapter.step)){seen.add(n.chapter.step);await page.screenshot({path:out+'/touch-novel-'+n.chapter.step+'.png'});}
  if(n.chapter.step==='race'||n.chapter.step==='trap'){await page.waitForTimeout(150);continue;}
  if(n.choices.length)await tap(n.choices[0]);else if(n.next_visible)await tap(n.next);
  await page.waitForTimeout(180);
 }
 assert(seen.has('plea')&&seen.has('promise'));assert.equal((await state()).stage,2);
 result.novel='PASS: portrait touch dialogue, friendly race, trap, revenge promise and next chapter';assert.deepEqual(result.errors,[]);result.status='PASS';result.flow='Fixed joystick/action fingers, actual400m robot combat, portrait→landscape safe pause/resume and victory';console.log(JSON.stringify(result));
 }catch(e){result.error=String(e);throw e;}finally{fs.writeFileSync(out+'/touch-boss-results.json',JSON.stringify(result,null,2));await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1});
