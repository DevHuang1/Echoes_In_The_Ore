extends "res://tools/validate_ship_missions_rendered.gd"
## Inherits every original rendered assertion, adds real stage navigation,
## pointer activation, compact geometry and two-size captures of live states.
const DEST := "res://.godot/ui_restyle_validation/"
var reviewed_states: Array=[]

func pair(label: String,page := "") -> void:
	if not is_instance_valid(level._ship_panel): return
	var panel=level._ship_panel
	if not page.is_empty(): panel._select_stage(page)
	var old_size: Vector2i=get_window().size
	var old_scale: Vector2i=get_window().content_scale_size
	for dims in [Vector2i(1280,720),Vector2i(1024,576)]:
		get_window().size=dims;get_window().content_scale_size=dims;await frames(5)
		var viewport := Rect2(Vector2.ZERO,Vector2(dims))
		var frame: Control=panel._root.find_child("ProcedureFrame",true,false)
		check(viewport.encloses(frame.get_global_rect()),"Frame fits "+label+str(dims))
		for control in panel._root.find_children("*","Control",true,false):
			if control.is_visible_in_tree() and (control is Button or control is OptionButton or control is SpinBox):
				check(frame.get_global_rect().grow(1).encloses(control.get_global_rect()),"Control fits "+label+" / "+str(control.name)+str(dims))
		await RenderingServer.frame_post_draw
		var capture_id: String=label+"_%dx%d" % [dims.x,dims.y]
		get_viewport().get_texture().get_image().save_png(DEST+"screenshots/"+capture_id+".png")
		reviewed_states.append({"capture":capture_id,"station":panel.prop_id,"page":panel._stage,"phase":level._ship_state.phase})
	get_window().size=old_size;get_window().content_scale_size=old_scale;await frames(4)

func capture(capture_name: String) -> void:
	await super.capture(capture_name)
	if is_instance_valid(level) and is_instance_valid(level._ship_panel):
		var page := ""
		if capture_name.ends_with("_quarters"): page="ROSTER"
		await pair(capture_name,page)
	elif is_instance_valid(level) and is_instance_valid(level._ship_service_console):
		await service_pair(capture_name)

func service_pair(label: String) -> void:
	var console=level._ship_service_console
	if not is_instance_valid(console): return
	var old_size: Vector2i=get_window().size;var old_scale: Vector2i=get_window().content_scale_size
	for dims in [Vector2i(1280,720),Vector2i(1024,576)]:
		get_window().size=dims;get_window().content_scale_size=dims;await frames(6)
		var viewport := Rect2(Vector2.ZERO,Vector2(dims))
		for control in console._root.find_children("*","Control",true,false):
			if control.is_visible_in_tree() and (control is Button or control is HSlider):
				check(viewport.encloses(control.get_global_rect()),"Service control fits "+label+" / "+str(control.name)+str(dims))
		await RenderingServer.frame_post_draw
		var capture_id: String=label+"_%dx%d" % [dims.x,dims.y]
		get_viewport().get_texture().get_image().save_png(DEST+"screenshots/"+capture_id+".png")
		reviewed_states.append({"capture":capture_id,"station":str(console._task_id),"page":"SERVICE","phase":level._ship_state.phase})
	get_window().size=old_size;get_window().content_scale_size=old_scale;await frames(3)

func play_legacy(prop: String,task: String) -> void:
	await operate(prop,"legacy:"+task)
	var console=level._ship_service_console
	check(is_instance_valid(console),"Original service controls rendered: "+task)
	if not is_instance_valid(console): return
	await capture("legacy_"+task)
	match task:
		"auxiliary_power":
			for i in range(3): console._power_sliders[i].value=[67,43,77][i]
			console._power_sync_button.pressed.emit()
		"air_filter":
			console._filter_release_button.pressed.emit()
			await service_pair("legacy_filter_released")
			console._on_filter_rotate_pressed();console._on_filter_rotate_pressed();console._on_filter_seat_pressed()
			await service_pair("legacy_filter_regulation")
			console._filter_pressure_slider.value=67;console._filter_pressure_button.pressed.emit()
		"nutrient_flow":
			for i in range(3):
				while console._nutrient_rotations[i]!=[1,3,2][i]: console._nutrient_rotate_buttons[i].pressed.emit()
			console._nutrient_restore_button.pressed.emit()
	check(console._task_complete,"Original controls finish in rendered runtime: "+task)
	await service_pair("legacy_"+task+"_completed")
	console._close_button.pressed.emit();await get_tree().create_timer(0.3).timeout

func operate(prop: String, action_id: String, value: Variant=null) -> void:
	if not is_instance_valid(level._ship_panel) or level._ship_panel.prop_id!=prop:
		if not await station(prop): return
	await frames(2)
	var panel=level._ship_panel
	if not panel._controls.has(action_id): check(false,"Missing rendered action: "+prop+"/"+action_id);return
	panel.reveal_action(action_id);await frames(3)
	var button: Button=panel._controls[action_id].button
	if button.disabled: await get_tree().create_timer(0.25).timeout
	check(not button.disabled,"Rendered action enabled: "+prop+"/"+action_id)
	check(button.is_visible_in_tree(),"Stage exposes control: "+prop+"/"+action_id)
	if button.disabled or not button.is_visible_in_tree(): return
	var choice := panel.find_child(action_id.replace(":","_")+"Choice",true,false) as OptionButton
	if choice!=null:
		for action in level._ship_state.actions(prop):
			if action.id==action_id:
				for index in range(action.options.size()):
					if action.options[index][0]==value: choice.select(index)
	var number := panel.find_child(action_id+"Value",true,false) as SpinBox
	if number!=null: number.value=float(value)
	var motion := InputEventMouseMotion.new();motion.position=button.get_global_rect().get_center();Input.parse_input_event(motion)
	for pressed in [true,false]:
		var event := InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT
		event.position=button.get_global_rect().get_center();event.pressed=pressed;Input.parse_input_event(event);await frames(2)
	await frames(3)
	if action_id=="isolate": await pair(level._ship_state.phase+"_"+prop.replace(".","_")+"_isolated")
	if action_id.begins_with("take:"): await pair(level._ship_state.phase+"_"+prop.replace(".","_")+"_supply")

func sequence(context: String) -> void:
	if context=="outbound":
		for prop in ["bridge.planning","bridge.helm","bridge.comms.upper","quarters.desk","cargo.scale","engine.pump.1","power.breaker","life.filter","hydro.console"]:
			await station(prop);await pair("blocked_"+prop.replace(".","_"))
	await super.sequence(context)
	# Use the actual completed state from the whole sequence, not successful
	# readings invented for a screenshot fixture.
	for prop in ["quarters.desk","cargo.scale","power.breaker","life.filter","hydro.console","engine.pump.1","bridge.helm","bridge.comms.upper"]:
		await station(prop);await pair(context+"_verified_"+prop.replace(".","_"))
	await station("quarters.drawer.1");await pair(context+"_storage","SUPPLIES")
	await station("quarters.bed.1");await pair(context+"_rest","ACCESS")
	await station("bridge.planning");level._ship_panel._select_record("EVIDENCE")
	await pair(context+"_evidence","RECORDS")

func run() -> void:
	DirAccess.make_dir_recursive_absolute(DEST+"screenshots")
	await super.run()
	var file := FileAccess.open(DEST+"rollout_report.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"states":reviewed_states},"\t"));file.close()
