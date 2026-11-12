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
	for i in bar.tab_count:
		var r := bar.get_tab_rect(i)
		r.position+=bar.get_global_position()
		targets.append([r.position.x,r.position.y,r.size.x,r.size.y])
	return {"visible":panel.visible,"box":rect(panel),"back":rect(panel.back),"page":rect(panel.tabs.get_current_tab_control()),"low_power":rect(panel.options["low_power"]),"tabs":targets,"reset":rect(panel.reset_button),"confirm":panel.reset_dialog.visible}
