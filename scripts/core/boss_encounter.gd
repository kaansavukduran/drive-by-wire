extends RefCounted
## Deterministic road encounters; drawing and cosmetic RNG never affect attacks.
const NAMES: Array[String]=["Mühür-01","Yankı-02","Tasnif-13"]
const IDS: Array[String]=["muhur","yanki","tasnif"]
const INTRO: Array[String]=["APTAL! HAHAHA! Geçiş iznin iptal. İçindeki sesi teslim et.","Duyduğun her sesi ben saklıyorum. Bakalım hangisine ateş edeceksin?","Omega-3 bir yol arkadaşı değil, benim silme yetkimdi. Neden sana söylemedi?"]
const PHASE: Array[String]=["İlk kapıyı açmak kolaydı. Şimdi iki namluya bak!","Arkana bak. Kaybettiğin sesler hep arkandan gelir.","Yetkisi ne olursa olsun, şimdi neyi seçtiği önemli."]
const VICTORY: Array[String]=["omer: Bu makine kapıyı korumuyordu; kimin geri dönemeyeceğine karar veriyordu. İmza senin eski geçiş kartın.","emre: Kayıttaki son söz bana ait. Ama nefes alan hâlim hâlâ burada. Beni kayda değişmedin, teşekkür ederim.","omega: Evet, o kapıları kapattım. Bunu saklamak seni korumadı. Bundan sonra kalıp hesap vereceğim; beni bağışlamak zorunda değilsin."]
var stage:=0
var active:=false
var started:=false
var defeated:=false
var hp:=0.0
var max_hp:=0.0
var position:=Vector2(320,-60)
var clock:=0.0
var phase:=1
var warning_left:=0.0
var cooldown:=1.5
var targets: Array[Vector2]=[]
var casts:=0
var flash:=0.0
var rear:=false
var messages: Array[String]=[]
func start(index: int) -> void:
 stage=clampi(index,0,2);active=true;started=true;defeated=false
 max_hp=[200.0,260.0,340.0][stage];hp=max_hp;clock=0;phase=1;cooldown=2.2;warning_left=0;casts=0;targets.clear();rear=false
 position=Vector2(320,-60);messages.append(IDS[stage]+": "+INTRO[stage])
func hit(amount: float) -> bool:
 if not active or amount<=0: return false
 hp=maxf(0,hp-amount);flash=0.12
 if hp<=0:
  active=false;defeated=true;targets.clear();messages.append(VICTORY[stage]);return true
 return false
func rect() -> Rect2:
 return Rect2(position-Vector2(45,30),Vector2(90,60))
func step(delta: float,player: Vector2) -> Array[Dictionary]:
 var shots: Array[Dictionary]=[]
 if not active: return shots
 clock+=delta;flash=maxf(0,flash-delta)
 if phase==1 and hp<=max_hp/2:
  phase=2;messages.append(("aion" if stage==2 else IDS[stage])+": "+PHASE[stage]);cooldown=maxf(cooldown,1.2)
 rear=stage>0 and phase==2 and fmod(clock,12.0)>6.0
 var destination:=Vector2(320+sin(clock*0.65)*46,430 if rear else 150)
 # Shift outside the road before changing front/rear; never fly through the player.
 if (rear and position.y<400) or (not rear and position.y>190):
  position.x=move_toward(position.x,480,160*delta)
  if position.x>=479: position.y=move_toward(position.y,destination.y,200*delta)
 else: position=position.move_toward(destination,95*delta)
 if clock<2.2 or (rear and position.y<400) or (not rear and position.y>190): return shots
 if warning_left>0:
  warning_left=maxf(0,warning_left-delta)
  if warning_left==0:
   for target in targets:
    shots.append({"pos":position,"vel":(target-position).normalized()*(155+stage*20),"dmg":8.0+stage*2,"near":false,"passed":false})
   casts+=1;targets.clear();cooldown=1.7 if phase==2 else 2.2
 else:
  cooldown-=delta
  if cooldown<=0:
   warning_left=1.05
   if casts%3==0: targets.assign([player])
   elif casts%3==1:
    var safe:=posmod(casts+stage,3)
    for lane in 3:
     if lane!=safe: targets.append(Vector2(256+lane*64,player.y))
   else:
    targets.assign([Vector2(clampf(player.x-42,235,405),player.y),Vector2(clampf(player.x+42,235,405),player.y)])
 return shots
func take_messages() -> Array[String]:
 var output:=messages.duplicate();messages.clear();return output
func snapshot() -> Dictionary:
 return {"active":active,"started":started,"defeated":defeated,"stage":stage,"name":NAMES[stage],"hp":hp,"max_hp":max_hp,"phase":phase,"position":[position.x,position.y],"rear":rear,"warning":warning_left,"targets":targets.map(func(p):return [p.x,p.y]),"casts":casts}
