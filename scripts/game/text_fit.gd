extends RefCounted
## Measure the same Godot Label shaping, fallback font and line spacing used onscreen.
## Fixed text boxes never grow into adjacent controls; long prose is paged unchanged.
static func inner_size(label: Label) -> Vector2:
 var extent:=label.size
 if label.has_theme_stylebox("normal"):
  extent-=label.get_theme_stylebox("normal").get_minimum_size()
 return extent.max(Vector2.ONE)
static func probe_for(label: Label) -> Label:
 var probe:=Label.new()
 probe.theme=label.theme
 probe.add_theme_font_override("font",label.get_theme_font("font"))
 probe.add_theme_font_size_override("font_size",label.get_theme_font_size("font_size"))
 probe.add_theme_constant_override("line_spacing",label.get_theme_constant("line_spacing"))
 probe.autowrap_mode=label.autowrap_mode
 probe.clip_text=true
 probe.size=inner_size(label)
 return probe
static func height(probe: Label,text: String) -> float:
 if text.is_empty(): return 0.0
 var paragraph:=TextParagraph.new()
 paragraph.width=probe.size.x
 paragraph.break_flags=TextServer.BREAK_MANDATORY
 if probe.autowrap_mode==TextServer.AUTOWRAP_ARBITRARY: paragraph.break_flags|=TextServer.BREAK_GRAPHEME_BOUND
 elif probe.autowrap_mode==TextServer.AUTOWRAP_WORD: paragraph.break_flags|=TextServer.BREAK_WORD_BOUND
 elif probe.autowrap_mode==TextServer.AUTOWRAP_WORD_SMART: paragraph.break_flags|=TextServer.BREAK_WORD_BOUND|TextServer.BREAK_ADAPTIVE
 paragraph.add_string(text,probe.get_theme_font("font"),probe.get_theme_font_size("font_size"))
 var lines:=paragraph.get_line_count()
 var result:=0.0
 for i in lines: result+=paragraph.get_line_size(i).y
 return result+maxi(0,lines-1)*probe.get_theme_constant("line_spacing")

static func fits(label: Label,text: String="") -> bool:
 var probe:=probe_for(label)
 var value:=label.text if text.is_empty() else text
 var result:=height(probe,value)<=inner_size(label).y+0.5
 probe.free()
 return result
static func pages(text: String,label: Label) -> Array[String]:
 var probe:=probe_for(label)
 var available:=inner_size(label).y
 var output: Array[String]=[]
 var part: String=""
 for word in text.split(" "):
  var candidate:=part+(" " if not part.is_empty() else "")+word
  if height(probe,candidate)>available and not part.is_empty():
   output.append(part)
   part=""
  if part.is_empty() and height(probe,word)>available:
   # An unusually long word also stays inside the box; preserve every character.
   for letter in word:
    if height(probe,part+letter)>available and not part.is_empty():
     output.append(part)
     part=""
    part+=letter
  else: part+=(" " if not part.is_empty() else "")+word
 if not part.is_empty(): output.append(part)
 if output.is_empty(): output.append("")
 probe.free()
 return output

# Reading anchors count visible characters, so paragraph spacing never skips words.
static func reading_length(text: String) -> int:
 return text.replace(" ","").replace("\n","").replace("\r","").replace("\t","").length()
static func offset_at(parts: Array[String],index: int) -> int:
 var offset:=0
 for i in mini(maxi(0,index),parts.size()):offset+=reading_length(parts[i])
 return offset
static func page_at(parts: Array[String],offset: int) -> int:
 var end:=0
 for i in parts.size():
  end+=reading_length(parts[i])
  if offset<end:return i
 return maxi(0,parts.size()-1)
