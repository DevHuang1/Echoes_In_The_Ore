extends CanvasLayer
## Equipment view/controller. Authoritative readings/actions stay in mission state.
const UI := preload("res://scripts/ui/equipment_ui.gd")
const DIAGRAM := preload("res://scripts/ui/ship_equipment_diagram.gd")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
const PRESENT := preload("res://scripts/ui/ship_station_presentation.gd")
signal action_requested(action_id: String, value: Variant)
signal save_requested
signal load_requested
signal closed
var state: Object
var prop_id := ""
var display_title := "SHIP EQUIPMENT"
var _controls := {}
var _root: Control
var _actions: GridContainer
var _readout: RichTextLabel
var _status: Label
var _diagram: Control
var _metrics: Array=[]
var _condition: UI.Lamp
var _stage_label: Label
var _interlock: Label
var _timer: UI.SegmentedMeter
var _observation: Label
var _tabs: HBoxContainer
var _records: Control
var _record_tabs: HBoxContainer
var _workspace: Control
var _stage := "INSPECT"
var _definition := {}
var _pages := ["INSPECT","SERVICE","VERIFY","RECORDS"]
var _poll := 0.0
var _closing := false
var _rebuild_pending := false
var _saved_choices := {}
var _last_feedback := ""
var _record_page := "PROCEDURE"
var _stock_page := 0
var _paging: HBoxContainer
var _page_caption: Label
var _report_preview: RichTextLabel
var _empty_state: Label
var _explanation_id := ""

func setup(model: Object, id: String, title: String) -> void:
	state=model;prop_id=id;display_title=title;_definition=CATALOG.definition(id)
	_pages=PRESENT.pages(_definition);_stage=PRESENT.suggested_page(state,_definition)
	# Some shared storage hosts also offer their room's existing system actions.
	# Every action exposed by the model must retain an accessible stage.
	for action in state.actions(id):
		var page: String=_action_page(action.id)
		if not _pages.has(page): _pages.insert(_pages.size()-1,page)

func _ready() -> void:
	layer=21
	_root=Control.new();_root.name="ShipProcedure";UI.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(_root)
	var dim := ColorRect.new();dim.color=Color(0.005,0.012,0.018,0.93)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_root.add_child(dim)
	var frame := UI.panel(16,true);frame.name="ProcedureFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left=16;frame.offset_top=16;frame.offset_right=-16;frame.offset_bottom=-16;_root.add_child(frame)
	var content := UI.stack(frame,8)
	var header := HBoxContainer.new();header.add_theme_constant_override("separation",12);content.add_child(header)
	var identity := UI.stack(header,2)
	identity.add_child(UI.label("ASTERIA-1 / "+str(_definition.get("room","ship")).to_upper()+" / LOCAL INSTRUMENT",12,UI.WELL))
	var heading := UI.label(display_title.to_upper(),20,UI.WELL);heading.name="EquipmentTitle";identity.add_child(heading)
	var condition_frame := UI.panel(8);condition_frame.size_flags_vertical=Control.SIZE_SHRINK_CENTER
	header.add_child(condition_frame);_condition=UI.Lamp.new();condition_frame.add_child(_condition)
	if prop_id=="bridge.planning":
		for setting in ["SAVE","LOAD"]:
			var b := UI.button(setting,_save_or_load.bind(setting))
			b.name=setting;header.add_child(b)
	var close := UI.button("X",close_panel,"Close equipment panel (Esc)");close.name="Close"
	close.custom_minimum_size=Vector2(42,42);header.add_child(close)
	_tabs=HBoxContainer.new();_tabs.add_theme_constant_override("separation",4);content.add_child(_tabs)
	for page in _pages:
		var tab := UI.button(page,_select_stage.bind(page));tab.name=page+"Tab";tab.toggle_mode=true
		tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_tabs.add_child(tab)
	var center := UI.panel(10);center.size_flags_vertical=Control.SIZE_EXPAND_FILL;content.add_child(center)
	var deck := Control.new();deck.size_flags_vertical=Control.SIZE_EXPAND_FILL
	deck.custom_minimum_size.y=280;center.add_child(deck)
	_workspace=HBoxContainer.new();_workspace.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_workspace.add_theme_constant_override("separation",12);deck.add_child(_workspace)
	var instrument := UI.stack(_workspace,8);instrument.size_flags_stretch_ratio=1.6
	var metrics := HBoxContainer.new();metrics.add_theme_constant_override("separation",6);instrument.add_child(metrics)
	for i in range(3):
		var meter := UI.Readout.new();metrics.add_child(meter);_metrics.append(meter)
	_diagram=DIAGRAM.new();_diagram.bind(state,_definition);instrument.add_child(_diagram)
	_report_preview=RichTextLabel.new();_report_preview.name="PreparedReportPreview"
	_report_preview.focus_mode=Control.FOCUS_ALL;_report_preview.selection_enabled=true
	_report_preview.size_flags_vertical=Control.SIZE_EXPAND_FILL;_report_preview.visible=false
	instrument.add_child(_report_preview)
	_observation=UI.label("",12,UI.MUTED);instrument.add_child(_observation)
	_timer=UI.SegmentedMeter.new();instrument.add_child(_timer)
	var rack := UI.stack(_workspace,8);rack.custom_minimum_size.x=310
	_stage_label=UI.label("",18,UI.AMBER);rack.add_child(_stage_label)
	_actions=GridContainer.new();_actions.columns=2
	_actions.add_theme_constant_override("h_separation",8);_actions.add_theme_constant_override("v_separation",8)
	rack.add_child(_actions)
	_empty_state=UI.label("",14,UI.MUTED);_empty_state.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	rack.add_child(_empty_state)
	_paging=HBoxContainer.new();rack.add_child(_paging)
	_paging.add_child(UI.button("<",_page_stock.bind(-1),"Previous stock page"))
	_page_caption=UI.label("",12,UI.MUTED);_page_caption.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_page_caption.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;_paging.add_child(_page_caption)
	_paging.add_child(UI.button(">",_page_stock.bind(1),"Next stock page"))
	_interlock=UI.label("",12,UI.MUTED);_interlock.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_interlock.size_flags_vertical=Control.SIZE_EXPAND_FILL;rack.add_child(_interlock)
	_records=VBoxContainer.new();_records.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);deck.add_child(_records)
	_record_tabs=HBoxContainer.new();_record_tabs.add_theme_constant_override("separation",6);_records.add_child(_record_tabs)
	for record_name in ["PROCEDURE","CREW NOTE","EVIDENCE","HISTORY","REPORT"]:
		var tab := UI.button(record_name,_select_record.bind(record_name));tab.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		tab.toggle_mode=true;tab.set_pressed_no_signal(record_name==_record_page)
		_record_tabs.add_child(tab)
	_readout=RichTextLabel.new();_readout.name="ReadingsAndEvidence";_readout.bbcode_enabled=false
	_readout.focus_mode=Control.FOCUS_ALL;_readout.selection_enabled=true
	_readout.size_flags_vertical=Control.SIZE_EXPAND_FILL;_readout.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_records.add_child(_readout)
	var record := UI.button("RECORD PHASE NOTE",func(): action_requested.emit("record",null))
	record.name="record";_records.add_child(record);_controls.record={"button":record,"reason":_interlock}
	var feedback_panel := UI.panel(8);content.add_child(feedback_panel)
	_status=UI.label("Select a procedure stage. Read interlocks before operating.",14)
	_status.name="ProcedureFeedback";_status.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size.y=32;feedback_panel.add_child(_status)
	var footer := UI.label(("RETURN WATCH" if state.phase=="return" else "OUTBOUND WATCH")+"   /   TAB selects controls   /   ESC closes   /   SIMULATED INSTRUMENTS",12,UI.WELL)
	content.add_child(footer)
	var housing := UI.Chassis.new();housing.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);frame.add_child(housing)
	state.changed.connect(_schedule_rebuild);_rebuild();close.grab_focus()

func _select_stage(page: String) -> void:
	_stage=page;_stock_page=0;_apply_stage()

func _select_record(page: String) -> void:
	_record_page=page
	for tab in _record_tabs.get_children(): tab.set_pressed_no_signal(tab.text==page)
	_update_readings()

func _page_stock(step: int) -> void:
	_stock_page=maxi(0,_stock_page+step);_apply_stage()

func _save_or_load(setting: String) -> void:
	if setting=="SAVE": save_requested.emit()
	else: load_requested.emit()

func _action_page(id: String) -> String:
	return PRESENT.action_page(id,_definition)

func _short_label(id: String,title: String) -> String:
	return PRESENT.action_label(id,title)

func _schedule_rebuild() -> void:
	if _rebuild_pending or _closing: return
	_rebuild_pending=true;_rebuild.call_deferred()

func _remember_controls() -> void:
	for id in _controls:
		var choice: Variant=_controls[id].get("choice")
		if choice is OptionButton: _saved_choices[id]=choice.selected
		elif choice is SpinBox: _saved_choices[id]=choice.value

func _rebuild() -> void:
	_rebuild_pending=false
	if _closing or not is_instance_valid(_actions): return
	_remember_controls()
	var focus := _root.get_viewport().gui_get_focus_owner()
	var focused_name: String=str(focus.name) if focus!=null else ""
	var focused_action := ""
	var focus_part := ""
	for id in _controls:
		var previous: Dictionary=_controls[id]
		var input: Control=previous.get("choice")
		if focus!=null and input!=null and (focus==input or input.is_ancestor_of(focus)):
			focused_action=id;focus_part="input";break
		if focus!=null and previous.button==focus:
			focused_action=id;focus_part="button";break
	for child in _actions.get_children(): _actions.remove_child(child);child.queue_free()
	var record: Dictionary=_controls.record
	_controls={"record":record}
	for action in state.actions(prop_id):
		if action.id=="record": continue
		var card := UI.panel(8);card.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		card.set_meta("page",_action_page(action.id));_actions.add_child(card)
		var v := UI.stack(card,5)
		var choice: Control
		if action.id in ["cargo_decide","file_report"]:
			var confirmation := UI.Confirmation.new()
			confirmation.show_review("REVIEW / RECORD DECISION","Compare mass and seal before committing custody." if action.id=="cargo_decide" else "File all eight verified duties and the relay acknowledgement.")
			v.add_child(confirmation)
		if not action.options.is_empty() or action.has("number"):
			var caption: String={"diagnose":"FAULT SOURCE","allocation":"ESS / SCI / RES","crew_compare":"RECORD CONCLUSION","cargo_decide":"DISPOSITION","move_load":"DESTINATION","channel":"RELAY PROTOCOL","cylinder":"CYLINDER ID","dose":"BUFFER-A DOSE","correction":"SIGNED OFFSET"}.get(action.id,"SELECT SETTING")
			v.add_child(UI.label(caption,12,UI.MUTED))
		if action.id.begins_with("take:") or action.id.begins_with("store:"):
			var item: String=action.id.get_slice(":",1)
			v.add_child(UI.label("STOCK %d / CARRIED %d" % [state.stocks.get(prop_id,{}).get(item,0),state.inventory.inventory_count(StringName(item))],12,UI.MUTED))
		if not action.options.is_empty():
			var dropdown := OptionButton.new();dropdown.name=action.id.replace(":","_")+"Choice"
			dropdown.clip_text=true;dropdown.fit_to_longest_item=false;dropdown.custom_minimum_size.y=32
			for option in action.options: dropdown.add_item(PRESENT.option_label(action.id,option))
			dropdown.select(clampi(int(_saved_choices.get(action.id,PRESENT.option_index(state,_definition,action))),0,action.options.size()-1))
			v.add_child(dropdown);choice=dropdown
			dropdown.item_selected.connect(func(index: int): dropdown.tooltip_text=action.options[index][1])
			dropdown.tooltip_text=action.options[dropdown.selected][1]
		elif action.has("number"):
			var number := SpinBox.new();number.name=action.id+"Value"
			number.min_value=action.number.min;number.max_value=action.number.max;number.step=action.number.step
			number.value=_saved_choices.get(action.id,action.number.value);number.suffix=action.number.suffix
			v.add_child(number);choice=number
		var b := UI.button(_short_label(action.id,action.title),Callable(),PRESENT.clean(action.title))
		b.name=action.id.replace(":","_");b.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		if action.id in ["isolate","restore","verify"]:
			b.mechanism=action.id
			for style_name in ["normal","hover","pressed","disabled"]:
				var style: StyleBox=_root.theme.get_stylebox(style_name,"Button").duplicate()
				style.content_margin_left=26;b.add_theme_stylebox_override(style_name,style)
		b.disabled=not action.enabled;b.pressed.connect(_dispatch.bind(action,choice));v.add_child(b)
		b.mouse_entered.connect(_explain.bind(action.id));b.focus_entered.connect(_explain.bind(action.id))
		_controls[action.id]={"button":b,"reason":_interlock,"choice":choice,"card":card}
	_apply_stage();_update_readings()
	var replacement: Control=null
	if not focused_action.is_empty() and _controls.has(focused_action):
		if focus_part=="input":
			replacement=_controls[focused_action].get("choice")
			if replacement is SpinBox: replacement=replacement.get_line_edit()
		else: replacement=_controls[focused_action].button
	elif not focused_name.is_empty(): replacement=_root.find_child(focused_name,true,false) as Control
	if replacement!=null and replacement.is_visible_in_tree() and replacement.focus_mode!=Control.FOCUS_NONE: replacement.grab_focus()

func _apply_stage() -> void:
	_workspace.visible=_stage!="RECORDS";_records.visible=_stage=="RECORDS"
	var cards: Array=[]
	for child in _actions.get_children():
		child.visible=false
		if child.get_meta("page")==_stage: cards.append(child)
	var page_count := maxi(1,int(ceilf(cards.size()/4.0)))
	_actions.columns=1 if cards.size()==1 else 2
	_stock_page=mini(_stock_page,page_count-1)
	for i in range(cards.size()): cards[i].visible=i>=_stock_page*4 and i<(_stock_page+1)*4
	_paging.visible=page_count>1;_page_caption.text="%d / %d" % [_stock_page+1,page_count]
	_empty_state.visible=cards.is_empty()
	_empty_state.text="No carried service items to return." if _stage=="RETURN" else "No supplies stored here. Return carried supplies or arrange a cargo transfer." if _stage=="SUPPLIES" else "Read the live instruments and station records."
	for tab in _tabs.get_children(): tab.set_pressed_no_signal(tab.text==_stage)
	_stage_label.text={"INSPECT":"DIAGNOSIS","SERVICE":"SERVICE CONTROLS","VERIFY":"RESTORE & VERIFY"}.get(_stage,_stage)
	var preview: bool=_definition.get("kind")=="communications" and _stage=="REPORT" and state.systems.communications.report_ready
	_diagram.visible=not preview;_report_preview.visible=preview
	_update_interlock()

func reveal_action(id: String) -> void:
	_select_stage(_action_page(id))
	var cards: Array=[]
	for child in _actions.get_children():
		if child.get_meta("page")==_stage: cards.append(child)
	if _controls.has(id) and cards.has(_controls[id].get("card")):
		_stock_page=int(cards.find(_controls[id].card)/4.0);_apply_stage()

func _explain(id: String) -> void:
	_explanation_id=id
	for action in state.actions(prop_id):
		if action.id==id: _interlock.text=PRESENT.clean(action.reason if not action.enabled else action.title)

func _update_interlock() -> void:
	_explanation_id=""
	var task: String=PRESENT.task(_definition)
	var prerequisite: String=state.prerequisite(task)
	var kind: String=_definition.get("kind","")
	if kind in ["storage","storage_hide","rest","chair","planning"]: prerequisite=""
	_interlock.text="INTERLOCK / "+prerequisite if not prerequisite.is_empty() else _stage_hint()
	for action in state.actions(prop_id):
		if _controls.has(action.id) and _controls[action.id].get("card")!=null:
			_controls[action.id].card.tooltip_text=PRESENT.clean(action.reason if not action.enabled else action.title)

func _stage_hint() -> String:
	var task: String=PRESENT.task(_definition)
	if _definition.get("kind") in ["storage","storage_hide"]: return "Transfers move one item between this station and your existing inventory. Stock and carried counts update together."
	if _definition.get("kind")=="rest":
		for action in state.actions(prop_id):
			if action.id=="rest": return action.reason if not action.enabled else "A short rest clears fatigue. Your recorded duties and unresolved check-ins remain active."
	if _definition.get("kind")=="chair": return "Inspect the operator space. Operate the adjacent equipment console while standing."
	if state.completed.has(task): return "VERIFIED / This duty is recorded. Readings remain live; safe restoration remains available."
	var id: String=str(_definition.get("id",""))
	if _stage=="SERVICE" and task=="engine": return "REQUEST 60% OUTPUT, then service pump 1 outbound or valve 2 on return at its own station. Restore its loop before verification."
	if _stage=="SERVICE" and task=="power" and id!="power.cell": return "Keep essential at 70. Bank synchronization is performed at the power-cell module after service isolation."
	if _stage=="VERIFY": return "Restore circulation/supply, then watch six stable seconds. Select a control to inspect its specific interlock."
	if _definition.get("kind") in ["storage","storage_hide"]: return "Transfers move one item between this station and your existing inventory. Stock and carried counts update together."
	return "Select a control for operating conditions. Full procedures, evidence and the latest command result are in RECORDS."

func _dispatch(action: Dictionary, control: Control) -> void:
	var value: Variant=null
	if control is OptionButton: value=action.options[control.selected][0]
	elif control is SpinBox: value=control.value
	action_requested.emit(action.id,value)

func feedback(message: String, success := true) -> void:
	message=PRESENT.clean(message)
	_last_feedback=message
	var first_line := message.get_slice("\n",0)
	_status.text=first_line if first_line.length()<150 else first_line.left(147)+"..."
	_status.tooltip_text=message;_status.add_theme_color_override("font_color",UI.CYAN if success else UI.AMBER)

func _process(delta: float) -> void:
	_poll+=delta
	if _poll<0.2 or _closing: return
	_poll=0;_update_readings()
	for action in state.actions(prop_id):
		if _controls.has(action.id):
			_controls[action.id].button.disabled=not action.enabled
			_controls[action.id].button.tooltip_text=PRESENT.clean(action.title+("\nINTERLOCK: "+action.reason if not action.enabled else ""))
	if not _explanation_id.is_empty(): _explain(_explanation_id)

func _update_readings() -> void:
	var room: String=str(_definition.get("room","bridge"))
	_update_records(room)
	var readings: Array=PRESENT.metrics(state,_definition)
	for i in range(_metrics.size()):
		_metrics[i].visible=i<readings.size()
		if i<readings.size(): _metrics[i].show_reading.callv(readings[i])
	var condition: String=PRESENT.condition(state,_definition)
	var color := UI.CYAN if condition in ["VERIFIED","ACCESS READY","REST READY","WATCH FILED","READY TO VERIFY"] else UI.RED if condition.begins_with("FAULT") else UI.AMBER
	_condition.set_status(condition,color)
	var task: String=PRESENT.task(_definition)
	var timed: bool=room in ["power","life","hydro","engine"] and _definition.get("kind")!="storage_hide"
	_observation.visible=timed;_timer.visible=timed
	_observation.text="STABLE OBSERVATION / %.1f OF 6.0 s" % minf(6,float(state.verification.get(task,0.0)))
	_timer.set_reading(float(state.verification.get(task,0.0)),6.0,UI.CYAN)
	_report_preview.text=PRESENT.clean(str(state.systems.communications.report_text))
	_diagram.queue_redraw()

func _update_records(room: String) -> void:
	var text := ""
	match _record_page:
		"PROCEDURE":
			if prop_id=="bridge.planning":
				for objective in CATALOG.OBJECTIVES:
					text+=("VERIFIED / " if state.completed.has(objective[0]) else "OPEN / ")+objective[1]+"\n"+state.next_step(objective[0])+"\n\n"
			elif _definition.get("kind") in ["storage","storage_hide"]:
				text="SHARED SERVICE STORE\nSUPPLIES retrieves one item. RETURN stores one carried service item. Station and carried counts update together. A full inventory leaves the stock here.\n\nFILTER-A: air filter\nSCRUB-A: scrubber medium\nCOOL-02: coolant service charge\nBUFFER-A: nutrient buffer\nO2-01: oxygen reserve\nN2-03: inert purge\n\n"
				if _definition.get("kind")=="storage_hide": text+="ACCESS offers the marked concealment space. Press E to exit; a blocked exit allows retry."
			else: text=state.next_step(PRESENT.task(_definition))+"\n\nOPERATING RANGES\n"+state.readings(room)
		"CREW NOTE": text=state.narrative(room)
		"EVIDENCE":
			for entry in state.evidence.values(): text+=str(entry)+"\n\n"
			if text.is_empty(): text="No phase notes recorded. Read CREW NOTE, then RECORD PHASE NOTE to retain it with the duty report."
		"HISTORY":
			text="LATEST CONTROL RESULT\n"+_last_feedback+"\n\nDUTY LOG\n"
			for entry in state.journal: text+=str(entry.text)+"\n\n"
		"REPORT": text=state.systems.communications.report_text if state.systems.communications.report_ready else "No report prepared. Verify the duties, then use the bridge flight-control station to prepare the measured report."
	text=PRESENT.clean(text)
	if _readout.text!=text: _readout.text=text

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled();close_panel()

func close_panel() -> void:
	if _closing: return
	_closing=true;closed.emit();queue_free()
