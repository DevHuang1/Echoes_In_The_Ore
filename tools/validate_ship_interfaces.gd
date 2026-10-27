extends Node
## Render/geometry/input coverage for the equipment redesign. Normal renderer.
const LEVEL := preload("res://scenes/ship/bare_ship_walkthrough.tscn")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
var level
var checks := 0
var failures: Array=[]
var captures: Array=[]
const OUTPUT := "res://.godot/ui_restyle_validation/"

func frames(n:=4) -> void:
	for i in range(n): await get_tree().process_frame

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT+"screenshots")
	get_tree().create_timer(240).timeout.connect(func(): push_error("Interface access validation timed out");get_tree().quit(2))
	run.call_deferred()

func check(ok: bool,label: String) -> void:
	checks+=1
	if not ok: failures.append(label);push_error(label)

func capture(label: String) -> void:
	await frames(8);await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OUTPUT+"screenshots/"+label+".png")
	captures.append(label)

func click(control: Control) -> void:
	await frames()
	check(control.is_visible_in_tree(),"Mouse target visible: "+str(control.name))
	var motion := InputEventMouseMotion.new();motion.position=control.get_global_rect().get_center();Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
		event.position=control.get_global_rect().get_center();event.pressed=pressed
		Input.parse_input_event(event);await frames(2)

func key(code: Key) -> void:
	for pressed in [true,false]:
		var event := InputEventKey.new();event.keycode=code;event.physical_keycode=code
		event.pressed=pressed;Input.parse_input_event(event);await frames(2)

func all_action_access() -> void:
	for context in ["outbound","return"]:
		if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
		level.ship_start_development_scenario(context);await frames()
		for prop in CATALOG.PROPS:
			await station(prop[1])
			var panel=level._ship_panel
			if not is_instance_valid(panel): continue
			for action in level._ship_state.actions(prop[1]):
				panel.reveal_action(action.id);await frames(1)
				check(panel._pages.has(panel._stage),"Stage listed for "+prop[1]+" / "+action.id)
				check(panel._controls[action.id].button.is_visible_in_tree(),"Action individually reachable "+context+" / "+prop[1]+" / "+action.id)
				if action.has("number"):
					var number: SpinBox=panel._controls[action.id].choice
					check(number.min_value==action.number.min and number.max_value==action.number.max and number.step==action.number.step,"Numeric operating range preserved "+prop[1])
				if not action.options.is_empty():
					check(panel._controls[action.id].choice.item_count==action.options.size(),"All genuine options retained "+prop[1]+" / "+action.id)

func keyboard_refresh() -> void:
	await station("bridge.helm")
	var panel=level._ship_panel
	panel.reveal_action("correction");await frames()
	var number: SpinBox=panel._controls.correction.choice
	number.value=-3.5;number.get_line_edit().grab_focus()
	level._ship_state.changed.emit();await frames()
	check(panel._controls.correction.choice.value==-3.5,"Pending numeric input survives live refresh")
	check(panel._root.get_viewport().gui_get_focus_owner()!=null,"Keyboard focus survives refresh")
	check(level._ship_state.systems.navigation.correction==0.0,"Pending control never overrides model before commit")
	var records: Button=panel._tabs.get_children()[-1]
	records.grab_focus();await key(KEY_SPACE)
	check(panel._stage=="RECORDS","Keyboard opens records stage")
	await key(KEY_TAB)
	check(panel._root.get_viewport().gui_get_focus_owner()!=null,"Tab navigation retains a visible focus owner")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(level._ship_panel) and level.player.is_physics_processing(),"Escape closes and restores movement")
	await station("bridge.helm")
	check(level._ship_panel._controls.correction.choice.value==0.0,"Reopened controls initialize from saved model")
	await station("power.breaker")
	panel=level._ship_panel;panel.reveal_action("diagnose");await frames()
	var dropdown: OptionButton=panel._controls.diagnose.choice
	dropdown.grab_focus();await key(KEY_SPACE)
	check(dropdown.get_popup().visible,"Keyboard opens labelled option menu")
	await key(KEY_DOWN);await key(KEY_ENTER)
	check(dropdown.selected==1 and not dropdown.get_popup().visible,"Keyboard chooses actual second operating option")
	await key(KEY_ESCAPE)
	check(not is_instance_valid(level._ship_panel),"Escape closes after option-menu navigation")

func loaded_view() -> void:
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	check(level.ship_save_game().begins_with("Ship-side mission"),"UI probe saves in isolated namespace")
	level._ship_state.reset("return");await frames()
	check(level.ship_load_game().begins_with("Ship-side progress restored."),"UI probe reloads actual mission save")
	await station("power.breaker")
	check(level._ship_state.phase=="outbound" and level._ship_panel._condition.caption.text=="VERIFIED","Reloaded interface restores watch and verified condition")
	check(level._ship_panel._metrics[1].reading.text=="10 UNITS","Reloaded allocation readout uses actual saved science units")

func service_capture(console: Node,label: String) -> void:
	for dims in [Vector2i(1280,720),Vector2i(1024,576)]:
		get_window().size=dims;get_window().content_scale_size=dims;await frames(5)
		for control in console._root.find_children("*","Control",true,false):
			if control.is_visible_in_tree() and (control is Button or control is HSlider):
				check(Rect2(Vector2.ZERO,Vector2(dims)).encloses(control.get_global_rect()),"Reviewed service control fits "+label+str(dims)+str(control.name))
		await capture("reviewed_"+label+"_%dx%d" % [dims.x,dims.y])

func service_visuals() -> void:
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	# Focused presentation check of the actual original game Controls. Full owner
	# progression/consumption is covered separately by the unchanged state test
	# and inherited walkthrough rollout, not claimed by this local UI fixture.
	for task in [&"auxiliary_power",&"air_filter",&"nutrient_flow"]:
		var console := ServiceTaskConsole.new();console.setup(task,0,3);add_child(console)
		await get_tree().create_timer(0.3).timeout
		await service_capture(console,str(task)+"_active")
		if task==&"auxiliary_power":
			for i in range(3): console._power_sliders[i].value=[67,43,77][i]
			await click(console._power_sync_button)
		elif task==&"air_filter":
			await click(console._filter_release_button)
			await service_capture(console,"filter_released")
			var row: HBoxContainer=console._filter_stage_controls.get_child(0)
			await click(row.get_child(0));await click(row.get_child(0));await click(row.get_child(1))
			await service_capture(console,"filter_regulation")
			console._filter_pressure_slider.value=67;await click(console._filter_pressure_button)
		else:
			for i in range(3):
				while console._nutrient_rotations[i]!=[1,3,2][i]: await click(console._nutrient_rotate_buttons[i])
			await click(console._nutrient_restore_button)
		check(console._task_complete,"Reviewed service finishes with actual mouse controls: "+str(task))
		await service_capture(console,str(task)+"_complete")
		await click(console._close_button);await get_tree().create_timer(0.3).timeout
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)

func completed_room_review() -> void:
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	# Reload the actual completed return save produced by the full walkthrough
	# run. These screenshots do not invent successful measurements as fixtures.
	level.ship_mission_save_path="res://.godot/mission_validation/rendered_return.json"
	check(level.ship_load_game().begins_with("Ship-side progress restored."),"Final visual review loads completed walkthrough trace")
	if level._ship_state.completed.size()!=8:
		check(false,"Completed walkthrough trace includes eight duties");return
	var cases := [["power.breaker","power","VERIFY"],["cargo.scale","cargo","DISPOSITION"],
		["engine.pump.1","engine","VERIFY"],["life.filter","life","VERIFY"],
		["hydro.console","hydro","VERIFY"],["quarters.desk","crew","ROSTER"],
		["bridge.planning","planning","SIGN-OFF"],["bridge.helm","navigation","CORRECT"],
		["bridge.comms.upper","communications","TRANSMIT"],["quarters.drawer.1","storage","SUPPLIES"],
		["bridge.planning","records","RECORDS"],["bridge.comms.upper","report","REPORT"]]
	for entry in cases:
		await station(entry[0]);level._ship_panel._select_stage(entry[2])
		var panel=level._ship_panel
		if entry[1]=="cargo": check(panel._controls.cargo_decide.choice.selected==1,"Reloaded custody selector shows actual quarantine decision")
		if entry[1]=="crew":
			check(panel._controls.crew_compare.choice.selected==1,"Reloaded crew selector shows supported unconfirmed conclusion")
			check(panel._condition.caption.text=="VERIFIED","Crew station condition uses crew duty ID, independently of quarters room ID")
		if entry[1]=="communications": check(panel._controls.channel.choice.selected==1,"Reloaded protocol selector shows actual repeated packet mode")
		if entry[1]=="records": level._ship_panel._select_record("EVIDENCE")
		for dims in [Vector2i(1280,720),Vector2i(1024,576)]:
			get_window().size=dims;get_window().content_scale_size=dims
			await capture("final_"+entry[1]+"_%dx%d" % [dims.x,dims.y])
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)

func operate(id: String,value: Variant=null) -> void:
	var panel=level._ship_panel
	panel.reveal_action(id);await frames()
	var entry: Dictionary=panel._controls[id]
	check(not entry.button.disabled,"Control enabled: "+id)
	if entry.button.disabled: return
	var choice: Variant=entry.get("choice")
	if choice is OptionButton:
		for action in level._ship_state.actions(panel.prop_id):
			if action.id==id:
				for i in range(action.options.size()):
					if action.options[i][0]==value: choice.select(i)
	elif choice is SpinBox: choice.value=float(value)
	await click(entry.button);await frames()

func station(id: String) -> void:
	if is_instance_valid(level._ship_panel): level._ship_panel.close_panel();await frames()
	level.player.global_position=level._ship_points[id].marker.global_position
	check(level.ship_open_procedure(id),"Open "+id);await frames()

func run() -> void:
	level=LEVEL.instantiate();level.ship_story_enabled=false;get_tree().root.add_child(level)
	while not level._ship_points_ready: await get_tree().process_frame
	level.ship_mission_save_path="res://.godot/mission_validation/interface_isolated.json"
	level._on_arrival_briefing_dismissed()
	for child in level.get_children():
		if child is CanvasLayer and child!=level._walk_hud: child.hide()
	await station("power.breaker")
	await capture("power_breaker_first_1280x720")
	level._ship_panel._select_stage("SERVICE");await capture("power_breaker_service_1280x720")
	get_window().size=Vector2i(1024,576);get_window().content_scale_size=Vector2i(1024,576)
	await capture("power_breaker_service_1024x576")
	# Focused fixture unlocks cargo prerequisites only. The real circuit actions,
	# original bank controls and live observation still execute through the owner.
	level._ship_state.flags.assigned=true
	level._ship_state.completed={"crew":true,"cargo":true}
	level._ship_state.changed.emit();await frames()
	await operate("observe");await operate("diagnose","cell")
	await operate("isolate");await operate("allocation","reserve")
	check(level._ship_state.systems.power.isolated and level._ship_state.systems.power.reserve==20,"Breaker mouse controls change authoritative circuit")
	await capture("power_breaker_isolated_1024x576")
	await station("power.cell");await operate("legacy:auxiliary_power")
	await frames();var console=level._ship_service_console
	check(is_instance_valid(console),"Original bank game opens")
	if is_instance_valid(console):
		await capture("power_bank_active_1024x576")
		for i in range(3): console._power_sliders[i].value=[67,43,77][i]
		await click(console._power_sync_button)
		check(console._task_complete,"Original bank game completion")
		await capture("power_bank_complete_1024x576")
		console._close_console();await get_tree().create_timer(0.3).timeout
	await station("power.breaker");await operate("restore")
	while float(level._ship_state.verification.get("power",0))<6.0: await get_tree().process_frame
	await get_tree().create_timer(0.25).timeout;await operate("verify")
	check(level._ship_state.completed.has("power"),"Complete power duty through new controls")
	await capture("power_breaker_verified_1024x576")
	get_window().size=Vector2i(1280,720);get_window().content_scale_size=Vector2i(1280,720)
	await capture("power_breaker_verified_1280x720")
	await loaded_view()
	await service_visuals()
	await all_action_access()
	await keyboard_refresh()
	await completed_room_review()
	var file := FileAccess.open(OUTPUT+"interface_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"captures":captures},"\t"));file.close()
	print("SHIP INTERFACE VALIDATION: ",checks," checks / ",failures.size()," failures")
	get_tree().quit(0 if failures.is_empty() else 1)
