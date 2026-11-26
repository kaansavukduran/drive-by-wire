extends RefCounted
## Deterministic road encounters; drawing and cosmetic RNG never affect attacks.
const NAMES: Array[String]=["Mühür-01","Yankı-02","Tasnif-13"]
const IDS: Array[String]=["muhur","yanki","tasnif"]
const INTRO: Array[String]=["Geçiş mührü kilitli. Omega-3’ü teslim et, kapı açılsın.","Duyduğun her sesi ben saklıyorum. Bakalım hangisine ateş edeceksin?","Omega-3 bir yol arkadaşı değil, benim silme yetkimdi. Neden sana söylemedi?"]
const PHASE: Array[String]=["İlk mührü kırdın. Şimdi iki namlu yolu tutacak.","Arkana bak. Kaybettiğin sesler hep arkandan gelir.","Yetkisi ne olursa olsun, şimdi neyi seçtiği önemli."]
const VICTORY: Array[String]=["omer: Bu makine kapıyı korumuyordu; kimin geri dönemeyeceğine karar veriyordu. İmza senin eski geçiş kartın.","kurt: Sinyal sustu. Kuzey yolunda köprü görünmüyor. Aion, yavaşla; sana geliyorum.","omega: Evet, o kapıları kapattım. Bunu saklamak seni korumadı. Bundan sonra kalıp hesap vereceğim; beni bağışlamak zorunda değilsin."]
const WARNING_DURATION:=1.05
const RECOVER_DURATION:=1.8
const CAST_RECOIL:=0.24
const SCALE: Array[float]=[1.35,1.45,1.0]
const BODY: Array[Vector2]=[Vector2(108,66),Vector2(114,65),Vector2(90,60)]
const FRONT_Y:=156.0
const REAR_Y:=379.0
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
var act_state:="idle"
var fire_recoil:=0.0
var phase_burst:=0.0
var messages: Array[String]=[]
var cues: Array[String]=[]
var phase_casts:=0
var positioning_step:=0
var state_time:=0.0
var aim_origins: Array[Vector2]=[]
var aim_velocities: Array[Vector2]=[]
func start(index: int) -> void:
 stage=clampi(index,0,2);active=true;started=true;defeated=false
 max_hp=[200.0,260.0,340.0][stage];hp=max_hp;clock=0;phase=1;cooldown=.45
 warning_left=0;casts=0;phase_casts=0;positioning_step=0;rear=false;flash=0.0
 act_state="entering";state_time=0.0;fire_recoil=0.0;phase_burst=0.0
 targets.clear();aim_origins.clear();aim_velocities.clear();messages.clear();cues.clear()
 position=Vector2(320,-70);messages.append(IDS[stage]+": "+INTRO[stage])
func vulnerable() -> bool:
 return active and act_state=="recover" and phase_casts>0
func settled() -> bool:
 return active and act_state not in ["entering","phase_shift"]
func hit(amount: float) -> bool:
 if not vulnerable() or amount<=0:return false
 var floor_hp:=max_hp*.5 if phase==1 else 0.0
 hp=maxf(floor_hp,hp-amount);flash=0.12
 if phase==1 and hp<=floor_hp:
  _begin_phase()
 if hp>0:return false
 active=false;defeated=true;warning_left=0.0;fire_recoil=0.0
 _state("defeated");targets.clear()
 messages.append(VICTORY[stage]);cues.append("boss_defeat")
 return true
func _begin_phase() -> void:
 phase=2;phase_casts=0;phase_burst=.75;cooldown=.65
 positioning_step=0;rear=stage>0
 _state("phase_shift")
 cues.append("boss_phase")
 messages.append(("aion" if stage==2 else IDS[stage])+": "+PHASE[stage])
func rect() -> Rect2:
 return Rect2(position-BODY[stage]*.5,BODY[stage])
func warning_progress() -> float:
 return clampf(1.0-warning_left/WARNING_DURATION,0.0,1.0) if warning_left>0.0 else 0.0
func recover_ratio() -> float:
 return clampf(cooldown/RECOVER_DURATION,0.0,1.0) if vulnerable() else 0.0
func muzzle(index: int) -> Vector2:
 return position+Vector2(-24.0 if index==0 else 24.0,-21.0 if rear else 21.0)*SCALE[stage]
func _state(next: String) -> void:
 act_state=next
 state_time=0.0
func _position(delta: float) -> bool:
 var destination:=Vector2(320.0,REAR_Y if rear else FRONT_Y)
 if rear and positioning_step<2:
  destination=Vector2(515.0,position.y if positioning_step==0 else REAR_Y)
  position=position.move_toward(destination,210.0*delta)
  if position.distance_squared_to(destination)<.01:positioning_step+=1
  return false
 position=position.move_toward(destination,175.0*delta)
 return position==destination and phase_burst<=0.0
func _aim(player: Vector2) -> void:
 targets.clear();aim_origins.clear();aim_velocities.clear()
 var aim_y:=player.y
 if stage==0 and phase==1:
  targets.assign([player+Vector2(-10,0),player+Vector2(10,0)])
 elif stage==1 and phase==1:
  targets.assign([Vector2(clampf(player.x+34,246,394),aim_y),Vector2(clampf(player.x-34,246,394),aim_y)])
 else:
  targets.assign([Vector2(256,aim_y),Vector2(384,aim_y)])
 for i in targets.size():
  var origin:=muzzle(i)
  aim_origins.append(origin)
  aim_velocities.append((targets[i]-origin).normalized()*(155.0+stage*16.0))
 warning_left=WARNING_DURATION
 _state("telegraph")
 cues.append("boss_warn")
func step(delta: float,player: Vector2) -> Array[Dictionary]:
 var shots: Array[Dictionary]=[]
 if not active:return shots
 clock+=delta;state_time+=delta;flash=maxf(0,flash-delta)
 phase_burst=maxf(0,phase_burst-delta)
 fire_recoil=maxf(0,fire_recoil-delta)
 match act_state:
  "entering","phase_shift":
   if not _position(delta):return shots
   cooldown-=delta
   if cooldown<=0.0:_aim(player)
  "telegraph":
   warning_left=maxf(0,warning_left-delta)
   if warning_left>0:return shots
   for i in targets.size():
    shots.append({"pos":aim_origins[i],"vel":aim_velocities[i],"dmg":8.0+stage*2,"near":false,"passed":false})
   casts+=1;phase_casts+=1;targets.clear();fire_recoil=CAST_RECOIL
   _state("firing");cues.append("boss_fire")
  "firing":
   if fire_recoil<=0.0:
    cooldown=RECOVER_DURATION
    _state("recover")
  "recover":
   cooldown-=delta
   if cooldown<=0.0:_aim(player)
 return shots
func take_messages() -> Array[String]:
 var output:=messages.duplicate();messages.clear();return output
func take_cues() -> Array[String]:
 var output:=cues.duplicate();cues.clear();return output
func snapshot() -> Dictionary:
 return {"active":active,"started":started,"defeated":defeated,"stage":stage,"name":NAMES[stage],"hp":hp,"max_hp":max_hp,"phase":phase,"position":[position.x,position.y],"rear":rear,"warning":warning_left,"warning_progress":warning_progress(),"act_state":act_state,"targets":targets.map(func(p):return [p.x,p.y]),"casts":casts,"phase_casts":phase_casts,"vulnerable":vulnerable(),"scale":SCALE[stage]}
