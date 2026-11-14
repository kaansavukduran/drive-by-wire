extends RefCounted
## Read-only browser assertions, enabled only by the explicit ?qa query flag.
static var enabled := -1
static func rect(control: Control) -> Array:
	var r := control.get_global_rect()
	return [r.position.x,r.position.y,r.size.x,r.size.y]
static func active() -> bool:
	if enabled<0:
		enabled=int(OS.has_feature("web") and bool(JavaScriptBridge.eval("new URLSearchParams(location.search).has('qa')")))
	return enabled==1
static func publish(screen: String,state: Dictionary) -> void:
	if not active(): return
	state["screen"]=screen
	JavaScriptBridge.eval("globalThis.__dbwQA="+JSON.stringify(state))

static func settings(panel: Control) -> Dictionary:
	if not active(): return {}
	var bar: TabBar=panel.tabs.get_tab_bar()
	var targets := []
	var page: Control=panel.tabs.get_current_tab_control()
	for i in bar.tab_count:
		var r := bar.get_tab_rect(i)
		r.position+=bar.get_global_position()
		targets.append([r.position.x,r.position.y,r.size.x,r.size.y])
	return {"paging":{"index":page.page_index,"count":page.groups.size(),"previous":rect(page.previous),"next":rect(page.next),"items":page.column.get_children().filter(func(c):return c.visible).map(func(c):return rect(c))},"theme_visible":panel.theme_option.is_visible_in_tree(),"font_visible":panel.font_option.is_visible_in_tree(),"theme_popup":{"visible":panel.theme_option.get_popup().visible,"position":[panel.theme_option.get_popup().position.x,panel.theme_option.get_popup().position.y],"size":[panel.theme_option.get_popup().size.x,panel.theme_option.get_popup().size.y],"focused":panel.theme_option.get_popup().get_focused_item(),"selected":panel.theme_option.selected},"theme":preload("res://scripts/game/ui_skin.gd").resolved,"theme_preference":panel.settings["theme"],"font":preload("res://scripts/game/ui_skin.gd").font_status(),"theme_option":rect(panel.theme_option),"font_option":rect(panel.font_option),"tab_names":range(bar.tab_count).map(func(i): return bar.get_tab_title(i)),"visible":panel.visible,"box":rect(panel),"back":rect(panel.back),"page":rect(panel.tabs.get_current_tab_control()),"low_power":rect(panel.options["low_power"]),"tabs":targets,"reset":rect(panel.reset_button),"confirm":panel.reset_dialog.visible}
