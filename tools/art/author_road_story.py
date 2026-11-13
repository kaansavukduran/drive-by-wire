# Original local pixel drawings. No external service or private-reference upload.
from PIL import Image, ImageDraw
from pathlib import Path
import json,hashlib
root=Path(__file__).resolve().parents[2]; dest=root/'assets/sprites'
ink='#172331'; rim='#507582'
def vehicle(kind,frame):
 im=Image.new('RGBA',(64,96));d=ImageDraw.Draw(im)
 # Equal cell and fixed physical pivot: (32,43.5). Different body silhouettes.
 if kind=='courier':
  d.rectangle((12,13,51,77),fill=ink);d.rectangle((16,9,47,83),fill=ink)
  d.rectangle((16,13,47,79),fill='#bd7747');d.rectangle((19,11,44,78),fill='#e5b777')
  d.rectangle((18,58,45,76),fill='#3a5663');d.rectangle((21,61,42,72),fill='#253844')
  for x in [24,31,38]: d.line((x,61,x,72),fill='#71939b')
  d.rectangle((14,18,18,72),fill='#906345');d.rectangle((45,18,49,72),fill='#906345')
 else:
  d.polygon([(24,8),(39,8),(48,18),(48,71),(41,83),(22,83),(15,71),(15,18)],fill=ink)
  d.polygon([(24,12),(39,12),(44,20),(44,69),(38,78),(25,78),(19,69),(19,20)],fill='#ac557e')
  d.rectangle((24,14,39,25),fill='#e594b2');d.rectangle((25,15,29,25),fill='#ffe0af')
  d.rectangle((20,61,43,68),fill='#713f62');d.rectangle((24,72,39,77),fill='#e594b2')
 for x in [11 if kind=='courier' else 13,47]:
  for y in [21,62]:
   d.rectangle((x,y,x+5,y+12),fill=ink);d.line((x+1,y+2+frame%2,x+1,y+10),fill='#60818a')
 d.rectangle((18,28,45,56),fill=ink);d.rectangle((20,30,43,54),fill='#395d69')
 d.line((21,31,42,31),fill='#a2e1db');d.rectangle((26,20,37,25),fill='#253c49')
 for x in [19,40]:d.rectangle((x,13,x+4,17),fill='#fff1ad' if frame%2==0 else '#ffe0af')
 for x in [20,40]:d.rectangle((x,75,x+3,78),fill='#fa8290')
 if frame in [4,5]:
  for x in [23,38]:d.polygon([(x-3,82),(x+4,82),(x+1,92 if frame==4 else 89)],fill='#72d5ee');d.line((x,83,x,88),fill='#fff1ad',width=2)
 if frame==6:d.polygon([(32,0),(27,6),(29,10),(35,10),(37,6)],fill='#ffd78b')
 if frame==7:d.line((16,18,47,74),fill='#fff2db',width=2)
 return im
for kind in ['courier','comet']:
 sheet=Image.new('RGBA',(256,192))
 for frame in range(8):sheet.alpha_composite(vehicle(kind,frame),((frame%4)*64,(frame//4)*96))
 sheet.save(dest/f'{kind}_body.png')
# Eight authored trap frames. Body anchor never moves when geometry deforms.
crash=Image.new('RGBA',(256,192))
for f in range(8):
 im=vehicle('courier',0);d=ImageDraw.Draw(im)
 if f>=1:
  d.line((22,30,36,39,27,50,40,54),fill='#fff1ba',width=1)
 if f>=2:
  d.polygon([(20,58),(28,55),(34,61),(43,56),(45,75),(21,75)],fill='#674c48')
  for x,y in [(24,63),(33,59),(40,68)]:d.rectangle((x,y,x+3,y+6),fill='#273744')
 if 2<=f<=5:
  flame=9+(f%3)*5
  d.polygon([(22,65),(19,51),(25,57),(29,65-flame),(34,56),(41,52),(39,68)],fill='#e98b4c')
  d.polygon([(25,65),(29,54),(33,60),(36,56),(35,67)],fill='#ffda85')
 if f>=5:
  d.rectangle((19,15,44,25),fill='#62534e');d.rectangle((25,18,38,25),fill='#303d46')
  d.line((18,28,22,25,26,31,32,27,44,30),fill='#334650',width=2)
 for n in range(max(0,f-2)):
  x=21+(n*13)%23;y=8+(n*17+f*5)%45
  d.rectangle((x,y,x+5,y+9),fill='#516068')
 crash.alpha_composite(im,((f%4)*64,(f//4)*96))
crash.save(dest/'emre_trap.png')
# Emre aftermath: six hand-authored poses, 128x80, shared ground baseline y=72.
# Ears, face, hand and chest vary; torso/feet retain the same floor anchor.
sheet=Image.new('RGBA',(768,80))
for f in range(6):
 im=Image.new('RGBA',(128,80));d=ImageDraw.Draw(im);rise=[0,0,1,1,0,0][f]
 # Legs and shoes, lying on right hip. Furred feet always touch y=71.
 d.polygon([(61,46),(81,47),(87,56),(107,58),(111,68),(86,70),(72,61),(62,61)],fill=ink)
 d.polygon([(64,49),(79,50),(84,59),(103,61),(104,66),(85,66),(72,57),(65,57)],fill='#42445d')
 d.polygon([(89,66),(109,64),(118,67),(119,71),(91,71)],fill=ink)
 d.rectangle((94,67,116,70),fill='#dca887');d.line((108,68,108,70),fill='#a86e55')
 d.polygon([(61,58),(77,59),(85,69),(85,72),(69,72),(61,66)],fill=ink)
 d.polygon([(65,60),(74,61),(80,68),(80,70),(71,70),(65,66)],fill='#dca887')
 # Light blue shirt and dark belt, red tie.
 d.polygon([(43,40-rise),(58,39-rise),(71,47),(69,62),(56,68),(41,61)],fill=ink)
 d.polygon([(44,43-rise),(57,42-rise),(66,48),(65,59),(55,64),(43,59)],fill='#84a6ce')
 d.polygon([(45,45-rise),(54,44-rise),(61,50),(58,60),(47,58)],fill='#b9d6ec')
 d.polygon([(49,43-rise),(52,46-rise),(56,55),(52,59),(49,54)],fill='#bf454f')
 d.line((65,49,66,60),fill='#685466',width=3)
 # Long ears lie back; same head origin, no alpha-bound centering.
 for pts in [[(27,34),(12,25),(5,13),(9,9),(22,20),(34,29)],[(34,29),(28,15),(27,5),(32,3),(39,18),(40,30)]]:
  d.polygon(pts,fill=ink)
 d.polygon([(28,29),(14,23),(9,15),(11,13),(22,23),(32,29)],fill='#dda482')
 d.line((12,16,27,29),fill='#ecaaa5',width=3)
 d.polygon([(35,27),(31,15),(31,7),(33,7),(36,18),(38,28)],fill='#e5b28f')
 d.line((33,10,36,26),fill='#e9a2a0',width=2)
 d.polygon([(23,30),(36,25),(48,31),(53,41),(49,52),(39,58),(27,54),(19,44)],fill=ink)
 d.polygon([(24,32),(35,28),(46,33),(49,41),(46,49),(38,54),(28,51),(22,43)],fill='#c08e73')
 d.polygon([(25,39),(30,33),(39,32),(45,36),(46,44),(41,51),(30,50),(24,45)],fill='#f0ccb0')
 d.polygon([(27,44),(35,41),(45,43),(44,48),(36,52),(29,48)],fill='#ffe0c1')
 # Green eye half-open except a deliberate blink, not a reused still.
 if f==3:d.line((31,39,38,40),fill=ink,width=2)
 else:
  d.rectangle((30,36,38,41),fill=ink);d.rectangle((32,37,36,40),fill='#7a9b59');d.rectangle((35,37,36,40),fill=ink);d.point((33,37),fill='#fff4dd')
 d.polygon([(41,41),(46,42),(43,45)],fill='#a55c63');d.line((38,47,42,48 if f in [1,2,4] else 47),fill='#986356')
 d.line((24,34,32,30),fill='#ffe0c1');d.line((26,31,31,28),fill='#c08e73',width=2)
 # Reaching hand changes articulation. Left elbow remains planted at (46,67).
 reach=[0,2,4,5,3,1][f]
 d.polygon([(43,53),(47,55),(48,62),(58+reach,61-reach),(62+reach,65-reach),(58,69),(45,69),(40,62)],fill=ink)
 d.polygon([(43,56),(45,57),(45,65),(57+reach,64-reach),(59+reach,65-reach),(55,67),(44,66)],fill='#e4b393')
 d.line((50+reach,65-reach,57+reach,65-reach),fill='#ffdbc0')
 # Small non-graphic scorch marks; no blood/gore or canonical death.
 d.line((57,53,59,56),fill='#49647e');d.point((60,58),fill='#314859')
 sheet.alpha_composite(im,(f*128,0))
sheet.save(dest/'emre_aftermath.png')
meta={'status':'OYUN / TASLAK — user-requested event, not new canon approval','authoring':'Original locally authored pixel geometry; no external image generation or private asset upload. Existing Aion driver is composed at runtime, never repainted.','vehicles':{'frame':[64,96],'grid':[4,2],'pivot':[32,43.5],'ids':['roadster','courier','comet'],'hitbox_half':[11,26]},'trap':{'frame':[64,96],'frames':8,'fps':4,'pivot':[32,43.5],'animation':'cracked windshield, deformed cargo bed, fire, scorch and smoke'},'emre':{'frame':[128,80],'frames':6,'fps':5,'pivot':[64,72],'ground_y':72,'animation':'restrained breathing, blink and reaching hand; alive and injured','identity':'Tavşan Emre: beige fur, green eyes, blue shirt, red tie, dark trousers; not Tavşan Eren'},'hashes':{}}
for f in ['courier_body.png','comet_body.png','emre_aftermath.png','emre_trap.png']:meta['hashes'][f]=hashlib.sha256((dest/f).read_bytes()).hexdigest()
(root/'assets/sources/ROAD_STORY_ART.json').write_text(json.dumps(meta,ensure_ascii=False,indent=2)+'\n')
