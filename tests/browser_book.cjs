// A complete story played through real browser keyboard/mouse input.
// QA publishes read-only state; this test never writes Godot state.
const {chromium}=require('playwright');const assert=require('node:assert/strict');const fs=require('node:fs');
const out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v060';fs.mkdirSync(out,{recursive:true});
const base=process.env.DBW_URL||'http://127.0.0.1:8765';
const touch=process.env.DBW_TOUCH!=='0';
const choices=(process.env.DBW_BOOK_PATH||'0,0,0').split(',').map(Number),expectedEnding=process.env.DBW_ENDING||'e01';
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const result={status:'FAIL',legs:[],errors:[],biomes:[],bosses:[]};try{
 const context=await browser.newContext({viewport:{width:1280,height:720},hasTouch:touch});const page=await context.newPage();
 page.on('pageerror',e=>result.errors.push(e.message));page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 const state=()=>page.evaluate(()=>window.__dbwQA);const wait=fn=>page.waitForFunction(fn,null,{timeout:30000});
 const tap=async rect=>{const q=await state();const b=await page.locator('#canvas').boundingBox();await page.mouse.click(b.x+(rect[0]+rect[2]/2)*b.width/q.view[0],b.y+(rect[1]+rect[3]/2)*b.height/q.view[1]);};
 await page.goto(base+'/?qa&qa_render=low');await wait(()=>window.__dbwQA?.screen==='title');
 // A real car selection must persist before entering the story.
 await tap((await state()).vehicles);await wait(()=>window.__dbwQA?.screen==='vehicles');
 await tap((await state()).buttons[1]);await wait(()=>window.__dbwQA?.selected==='courier');
 await page.screenshot({path:`${out}/vehicle-courier.png`});
 await tap((await state()).back);await wait(()=>window.__dbwQA?.screen==='title');
 await page.reload();await wait(()=>window.__dbwQA?.screen==='title');
 await tap((await state()).vehicles);await wait(()=>window.__dbwQA?.screen==='vehicles');assert.equal((await state()).selected,'courier');
 await tap((await state()).back);await wait(()=>window.__dbwQA?.screen==='title');result.vehicle='PASS: real selection and reload';
 await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='briefing');
 for(let stage=0;stage<3;stage++){
  let brief=await state();assert.equal(brief.stage,stage);
  if(brief.radio_answers.length){
   await tap(brief.tabs[0]);await page.waitForTimeout(200);brief=await state();
   if(stage===0){
    const cast=new Set([brief.speaker]);
    for(let i=1;i<brief.line_count;i++){await tap((await state()).radio_next);await page.waitForTimeout(150);cast.add((await state()).speaker);}
    assert.deepEqual([...cast].sort(),['emre','eren','kurt','kuzu','omega','omer']);result.cast=[...cast];
    await page.screenshot({path:`${out}/cast-conversation.png`});
   }
   await tap((await state()).tabs[1]);await page.waitForTimeout(200);await tap((await state()).radio_answers[1]);
   await wait(()=>window.__dbwQA?.screen==='briefing'&&window.__dbwQA.radio_selected==='together');
   await tap((await state()).tabs[2]);await page.waitForTimeout(200);brief=await state();
  }
  await tap(brief.choices[choices[stage]]);
  if(stage===1){
   await wait(()=>window.__dbwQA?.screen==='road_story');
   const seen=new Set(),frames=new Set();let restored=false,rotated=false,erenRecord="";const started=Date.now();
   while((await state()).screen==='road_story'){
    const n=await state();assert(n.fits,'novel speech must fit');assert.equal(n.combat,false);assert.equal(n.vehicle,'courier');
    assert(Date.now()-started<100000,'novel timeout');
    if(n.chapter.record)erenRecord=n.chapter.record;
    if(n.paused){await page.keyboard.press('Escape');continue;}
    if(!seen.has(n.chapter.step)){seen.add(n.chapter.step);await page.screenshot({path:`${out}/novel-${n.chapter.step}.png`});}
    if(n.chapter.step==='race'||n.chapter.step==='trap'){await page.waitForTimeout(120);continue;}
    if(n.chapter.step==='plea'){
     assert.deepEqual(n.actors,[[210,248],[445,248],[520,248]],'aftermath actors stay in fixed ground slots');frames.add(n.frame);
     if(!rotated){
      const fixed=JSON.stringify(n.cast.map(a=>[a.id,a.world,a.contact]));
      const actingStart=Date.now();for(let i=0;i<35||frames.size<6;i++){
       assert(Date.now()-actingStart<12000,"all acting frames must be observable within multiple real-time loops");
       const pose=await state();assert.equal(JSON.stringify(pose.cast.map(a=>[a.id,a.world,a.contact])),fixed,'rendered foot origins cannot drift across the full acting loop');
       assert.deepEqual(pose.cast.map(a=>a.id),['aion','emre','eren']);
       assert(Math.max(...pose.cast.map(a=>a.contact[1]))-Math.min(...pose.cast.map(a=>a.contact[1]))<.1,'all actors share the actual road support plane');
       frames.add(pose.frame);if([0,12,24,34].includes(i))await page.screenshot({path:`${out}/grounded-acting-${i}.png`});
       await page.waitForTimeout(75);
      }
      assert.equal(frames.size,6,'all six distinct injury frames play in the browser');
      await page.setViewportSize({width:390,height:844});await page.waitForTimeout(450);let m=await state();assert(m.paused,'rotation pauses scene');
      await page.keyboard.press('Escape');await page.waitForTimeout(200);m=await state();assert(m.fits);assert.deepEqual(m.actors,n.actors);
      await page.screenshot({path:`${out}/novel-plea-phone.png`});
      await page.waitForTimeout(1300);await page.setViewportSize({width:1280,height:720});await page.waitForTimeout(400);await page.keyboard.press('Escape');rotated=true;continue;
     }
     if(!restored){
      await tap(n.pause);await page.waitForTimeout(200);await tap((await state()).leave);await wait(()=>window.__dbwQA?.screen==='title');
      await page.reload();await wait(()=>window.__dbwQA?.screen==='title');await tap((await state()).play);await wait(()=>window.__dbwQA?.screen==='briefing');
      await tap((await state()).choices[choices[stage]]);await wait(()=>window.__dbwQA?.screen==='road_story');
      assert.equal((await state()).chapter.step,'plea');assert.equal((await state()).chapter.pace,'race');restored=true;continue;
     }
    }
    if(n.choices.length)await tap(n.choices[n.chapter.step==='reveal'?1:0]);
    else if(n.next_visible)await tap(n.next);
    await page.waitForTimeout(180);
   }
   assert(seen.has('race')&&seen.has('trap')&&seen.has('plea')&&seen.has('eren')&&seen.has('witness')&&seen.has('rescue')&&seen.has('complete'));assert(restored&&rotated);
   result.legs.push({stage:2,erenRecord,actingFrames:[...frames],mode:'visual_novel',scenes:[...seen],checkpointReload:'PASS',rotation:'PASS'});
   await wait(()=>window.__dbwQA?.screen==='briefing');continue;
  }
  await wait(()=>window.__dbwQA?.screen==='run');
  assert.equal((await state()).finish,400);await page.keyboard.press('KeyC');await page.keyboard.down('Space');
  const started=Date.now();let held='',lastMine=0,lastSupport=Date.now();
  while(true){
   const q=await state();assert.equal(q.screen,'run');
   if(q.radio_ui){
    for(const w of q.radio_ui.widgets)assert(w.fits,'visible HUD text must fit its bounded area: '+w.text);
    const a=q.radio_ui.bubble,b=q.radio_ui.status;if(q.touch===false&&q.view[0]>=q.view[1])assert(a[1]+a[3]<=b[1],'radio body must clear status');
    if(q.radio_ui.speaker==='omer'&&q.radio_ui.widgets.some(w=>w.text.includes('İki kapı'))){result.reportedOmerLine='PASS';await page.screenshot({path:`${out}/reported-omer-radio-fixed.png`});}
   }
   if(!result.biomes.includes(q.biome))result.biomes.push(q.biome);if(q.boss?.active&&!result.bosses.some(b=>b.name===q.boss.name&&b.phase===q.boss.phase)){result.bosses.push({name:q.boss.name,phase:q.boss.phase});await page.screenshot({path:`${out}/robot-${stage+1}-phase${q.boss.phase}.png`});}
   if(q.over){assert(q.boss.defeated,'story robot must actually be defeated');assert(q.ending_text.includes('ETAP TAMAMLANDI'),'actual combat must survive');result.legs.push({stage:stage+1,distance:q.distance,hp:q.hp,kills:q.kills,collected:q.collected,wall_ms:Date.now()-started});break;}
   assert(Date.now()-started<120000,'chapter timeout');
   if(q.paused)await page.keyboard.press('Escape');
   const [px,py]=q.player;let best=q.lane,bestCost=Infinity;
   for(let lane=0;lane<3;lane++){
    let cost=Math.abs(256+lane*64-px)*.04;
    for(const e of q.traffic){const gap=Math.abs(e.y-py);if(e.lane===lane&&gap<165)cost+=(165-gap)*2;}
    for(const o of q.hazards){if(Math.abs(o.x-(256+lane*64))<25&&Math.abs(o.y-py)<150)cost+=250;}
    if(q.pickup_targets.some(p=>p.lane===lane&&p.y>130&&p.y<py))cost-=30;
    if(q.boss?.active){for(const target of q.boss.targets)if(Math.abs(target[0]-(256+lane*64))<34)cost+=180;if(q.boss.rear)cost+=Math.abs(q.boss.position[0]-(256+lane*64))*.5;}
    if(cost<bestCost){bestCost=cost;best=lane;}
   }
   const desired=256+best*64;
   const direction=Math.abs(desired-px)<8?'':(desired<px?'ArrowLeft':'ArrowRight');
   if(direction!==held){if(held)await page.keyboard.up(held);if(direction)await page.keyboard.down(direction);held=direction;}
   if((q.boss?.rear||q.traffic.some(e=>Math.abs(e.x-px)<25&&e.y>py+25&&e.y<py+140))&&q.mines===-1&&Date.now()-lastMine>800){await page.keyboard.press('KeyX');lastMine=Date.now();}
   if(q.traffic.some(e=>Math.abs(e.x-px)<28&&Math.abs(e.y-py)<60)&&q.dodge<=0)await page.keyboard.press('KeyR');
   if(Date.now()-lastSupport>8500){await page.keyboard.press('KeyC');lastSupport=Date.now();}
   await page.waitForTimeout(150);
  }
  if(held)await page.keyboard.up(held);await page.keyboard.up('Space');
  await page.screenshot({path:`${out}/book-leg-${stage+1}-complete.png`});
  await tap((await state()).result[0]);
  await wait(stage===2?()=>window.__dbwQA?.screen==='ending':()=>window.__dbwQA?.screen==='briefing');
 }
 let q=await state();assert(q.unlocked.includes(expectedEnding));
 await page.screenshot({path:`${out}/book-ending-desktop.png`});
 // Read every bounded page using actual arrows; no wheel or scrollbars.
 const prose=[];while(true){q=await state();assert.equal(q.scrollbars,0);assert(q.reader.fits);prose.push(q.reader.text);if(q.reader.page+1===q.reader.pages)break;await page.keyboard.press('ArrowRight');await page.waitForTimeout(180);}
 result.endingPages=q.reader.pages;assert(prose.join(' ').length>350);assert(prose.join(' ').includes('Eren mühürlü kaydı sakladı'),'Eren decision survives the third chapter and appears in actual epilogue');
 // Open gallery with native focus navigation.
 await page.keyboard.press('ArrowDown');await page.keyboard.press('Enter');await wait(()=>window.__dbwQA?.screen==='endings');
 q=await state();assert.equal(q.scrollbars,0);assert.equal(q.entries.length,13);assert.equal(q.entries.filter(e=>!e.disabled).length,1);
 await page.screenshot({path:`${out}/book-gallery-desktop.png`});
 await page.setViewportSize({width:390,height:844});await page.waitForTimeout(500);q=await state();
 assert(q.panel[0]>=0&&q.panel[1]>=0&&q.panel[0]+q.panel[2]<=q.view[0]&&q.panel[1]+q.panel[3]<=q.view[1]);
 await page.screenshot({path:`${out}/book-gallery-portrait.png`});
 const b=await page.locator('#canvas').boundingBox();const r=q.entries.find(e=>!e.disabled).rect;
 if(touch)await page.touchscreen.tap(b.x+(r[0]+r[2]/2)*b.width/q.view[0],b.y+(r[1]+r[3]/2)*b.height/q.view[1]);else await tap(r);await wait(()=>window.__dbwQA?.screen==='ending');
 q=await state();assert(q.reader.fits);assert.equal(q.scrollbars,0);await page.screenshot({path:`${out}/book-ending-portrait.png`});
 // Persisted completion survives a full page/engine reload.
 await page.reload();await wait(()=>window.__dbwQA?.screen==='title');await tap((await state()).endings);await wait(()=>window.__dbwQA?.screen==='endings');
 assert((await state()).unlocked.includes(expectedEnding));
 assert.deepEqual(result.errors,[]);result.status='PASS';result.reload='PASS';result.galleryTouch=touch?'PASS':'NOT TESTED: desktop pointer flow';
 console.log(JSON.stringify(result));
 }finally{fs.writeFileSync(`${out}/book-browser-results.json`,JSON.stringify(result,null,2)+'\n');await browser.close();}
})().catch(e=>{console.error(e);process.exitCode=1;});
