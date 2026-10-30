extends SceneTree
## Renders the restyled screens for review.
## godot --path . --script res://tools/gui_preview.gd -- <kind> <out.png> [arg]
## kinds: landing, intro, briefing, hud, inventory, map, settings, dev, station <prop>, service <task>
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")

var out := ""
var kind := ""
var arg := ""

func _initialize() -> void:
	var a := OS.get_cmdline_user_args()
	kind = a[0]; out = a[1]; arg = a[2] if a.size() > 2 else ""
	_run.call_deferred()

func _frames(n := 4) -> void:
	for i in range(n): await process_frame

func _shot() -> void:
	await _frames(6)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out)
	print("saved ", out)

func _key(code: Key) -> void:
	for pressed in [true, false]:
		var e := InputEventKey.new(); e.keycode = code; e.physical_keycode = code; e.pressed = pressed
		root.push_input(e, true); await _frames(2)

func _run() -> void:
	match kind:
		"landing":
			var s: Node = load("res://scenes/ui/landing_screen.tscn").instantiate(); root.add_child(s)
			await create_timer(0.5).timeout
		"intro":
			Engine.set_meta("ship_maintenance_entry", true)
			var s: Node = load("res://scenes/ui/earth_years_montage.tscn").instantiate(); root.add_child(s)
			await create_timer(1.2).timeout
			var idx := int(arg) if not arg.is_empty() else 0
			if idx > 0: s.call("_show_frame", idx)
			await create_timer(0.3).timeout
			s.call("_finish_subtitle")
		"briefing", "hud", "inventory", "map", "settings", "dev", "station", "service", "prompt":
			var level: Node = LEVEL.instantiate(); root.add_child(level)
			await create_timer(0.8).timeout
			if kind != "briefing":
				await _key(KEY_ENTER); await create_timer(0.5).timeout
			var hud = level.get("_walk_hud")
			match kind:
				"inventory": hud.call("_open_inventory")
				"map": hud.call("_open_map")
				"settings": hud.call("_open_settings")
				"dev": hud.call("_toggle_dev_menu")
				"prompt": hud.call("set_interaction_prompt", "[E]   /   MISSION PLANNING TABLE   /   ACCESS", true)
				"station":
					var p: Dictionary = level.get("_ship_points")[arg]
					level.get("player").global_position = p.marker.global_position
					await _frames(3)
					level.call("ship_open_procedure", arg)
				"service":
					level.call("_open_room_task_console", StringName(arg))
			await create_timer(0.6).timeout
	await _shot()
	quit()
