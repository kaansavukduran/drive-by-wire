// Real first story stage and result navigation via browser Gamepad API only.
// The test writes emulated device inputs, never gameplay or save state.
const {chromium}=require('playwright');const fs=require('node:fs');const assert=require('node:assert/strict');
const base=process.env.DBW_URL||'http://127.0.0.1:8877',out=process.env.DBW_EVIDENCE_DIR||'work/evidence-v073-pad';fs.mkdirSync(out,{recursive:true});
const sleep=ms=>new Promise(r=>setTimeout(r,ms));
(async()=>{const browser=await chromium.launch({executablePath:'/usr/bin/chromium',headless:true,args:['--no-sandbox','--use-gl=angle','--use-angle=swiftshader','--enable-unsafe-swiftshader']});const result={status:'FAIL',errors:[]};try{
 const context=await browser.newContext({viewport:{width:1280,height:720}});const page=await context.newPage();
 page.on('pageerror',e=>result.errors.push(e.message));page.on('console',m=>{if(m.type()==='error')result.errors.push(m.text());});
 await page.addInitScript(()=>{const p={id:'Xbox 360 Controller (XInput STANDARD GAMEPAD)',index:0,connected:true,mapping:'standard',timestamp:0,axes:[0,0,0,0],buttons:Array.from({length:17},()=>({pressed:false,touched:false,value:0}))};window.__pad=p;Object.defineProperty(navigator,'getGamepads',{value:()=>{p.timestamp=performance.now();return[p];}});});
 const state=()=>page.evaluate(()=>window.__dbwQA),wait=fn=>page.waitForFunction(fn,null,{timeout:15000});
 const button=async(i,on)=>page.evaluate(({i,on})=>window.__pad.buttons[i]={pressed:on,touched:on,value:on?1:0},{i,on});
 const tap=async i=>{await button(i,true);await sleep(110);await button(i,false);await sleep(150);};
 const axis=async value=>page.evaluate(v=>window.__pad.axes[0]=v,value);
 await page.goto(base+'/?qa&qa_render=low');await wait(()=>window.__dbwQA?.screen==='title');
 await page.evaluate(()=>{const e=new Event('gamepadconnected');Object.defineProperty(e,'gamepad',{value:window.__pad});dispatchEvent(e);});
 await tap(0);await wait(()=>window.__dbwQA?.screen==='briefing');await tap(0);await wait(()=>window.__dbwQA?.screen==='run');
 await button(7,true);await tap(3);let held=0,lastMine=0,lastPulse=Date.now();const started=Date.now();
 while(true){
  const q=await state();assert.equal(q.screen,'run');if(q.over){result.leg={distance:q.distance,hp:q.hp,kills:q.kills,collected:q.collected};assert(q.ending_text.includes('ETAP TAMAMLANDI'),'must complete a real 400m stage');break;}
  assert(Date.now()-started<100000,'actual stage timed out');const px=q.player[0],py=q.player[1];let best=q.lane,costBest=Infinity;
  for(let lane=0;lane<3;lane++){let cost=Math.abs(256+lane*64-px)*.04;for(const e of q.traffic){const gap=Math.abs(e.y-py);if(e.lane===lane&&gap<165)cost+=(165-gap)*2;}for(const o of q.hazards)if(Math.abs(o.x-(256+lane*64))<25&&Math.abs(o.y-py)<150)cost+=250;if(q.pickup_targets.some(p=>p.lane===lane&&p.y>130&&p.y<py))cost-=30;if(cost<costBest){costBest=cost;best=lane;}}
  const desired=256+best*64,next=Math.abs(desired-px)<8?0:desired<px?-.9:.9;if(next!==held){held=next;await axis(next);}
  if(q.traffic.some(e=>Math.abs(e.x-px)<25&&e.y>py+25&&e.y<py+140)&&Date.now()-lastMine>800){await tap(2);lastMine=Date.now();}
  if(q.traffic.some(e=>Math.abs(e.x-px)<28&&Math.abs(e.y-py)<60)&&q.dodge<=0)await tap(4);
  if(Date.now()-lastPulse>8200){await tap(3);lastPulse=Date.now();}
  await sleep(110);
 }
 await button(7,false);await axis(0);await sleep(250);assert.equal((await state()).result_focus,0);
 await axis(.85);await wait(()=>window.__dbwQA.result_focus===1);await axis(0);await sleep(100);await axis(-.85);await wait(()=>window.__dbwQA.result_focus===0);await axis(0);await sleep(100);
 await tap(15);assert.equal((await state()).result_focus,1);await tap(14);assert.equal((await state()).result_focus,0);
 await page.screenshot({path:out+'/actual-pad-stage-complete.png'});await tap(0);await wait(()=>window.__dbwQA?.screen==='briefing');assert.equal((await state()).stage,1);
 await page.screenshot({path:out+'/actual-pad-next-chapter.png'});assert.deepEqual(result.errors,[]);result.status='PASS';result.flow='Gamepad-only title, route, actual 400m combat, analog left/right, D-pad left/right, A confirms next chapter; no mouse or gameplay setters';console.log(JSON.stringify(result));
 }catch(e){result.error=String(e);throw e;}finally{fs.writeFileSync(out+'/result-pad.json',JSON.stringify(result,null,2)+'\n');await browser.close();}})().catch(e=>{console.error(e);process.exitCode=1;});
