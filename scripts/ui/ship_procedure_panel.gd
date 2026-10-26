extends CanvasLayer
## A view/controller for the walkthrough's mission state. No inventory or task
## state lives here, so closing it never consumes supplies or resets a procedure.
const SKIN := preload("res://scripts/ui/pixel_ui.gd")
const CATALOG := preload("res://scripts/ship/ship_mission_catalog.gd")
signal action_requested(action_id: String, value: Variant)
signal save_requested
signal load_requested
signal closed
var state: Object
var prop_id := ""
var display_title := "SHIP PROCEDURE"
var _readout: RichTextLabel
var _status: RichTextLabel
var _actions: VBoxContainer
var _controls := {}
var _poll := 0.0
var _closing := false
var _rebuild_pending := false
var _root: Control

func setup(model: Object, id: String, title: String) -> void:
	state=model;prop_id=id;display_title=title

func _ready() -> void:
	layer=21
	_root=Control.new();_root.name="ShipProcedure";SKIN.apply(_root)
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);add_child(_root)
	var dim := ColorRect.new();dim.color=Color(0.005,0.015,0.025,0.86)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);_root.add_child(dim)
	var frame := PanelContainer.new();frame.name="ProcedureFrame"
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.offset_left=24;frame.offset_top=24;frame.offset_right=-24;frame.offset_bottom=-24
	frame.add_theme_stylebox_override("panel",SKIN.panel(18));_root.add_child(frame)
	var content := VBoxContainer.new();content.add_theme_constant_override("separation",12);frame.add_child(content)
	var header := HBoxContainer.new();content.add_child(header)
	var heading := Label.new();heading.text=display_title.to_upper()+"  /  "+state.phase.to_upper()
	heading.size_flags_horizontal=Control.SIZE_EXPAND_FILL;heading.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_font_size_override("font_size",20);heading.modulate=SKIN.IVORY;header.add_child(heading)
	if prop_id=="bridge.planning":
		for setting in ["SAVE","LOAD"]:
			var button := Button.new();button.text=setting;button.custom_minimum_size=Vector2(76,42)
			if setting=="SAVE": button.pressed.connect(func(): save_requested.emit())
			else: button.pressed.connect(func(): load_requested.emit())
			header.add_child(button)
	var close := Button.new();close.name="Close";SKIN.close_button(close);close.pressed.connect(close_panel);header.add_child(close)
	content.add_child(HSeparator.new())
	var body := HBoxContainer.new();body.size_flags_vertical=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",14);content.add_child(body)
	_readout=RichTextLabel.new();_readout.name="ReadingsAndEvidence";_readout.bbcode_enabled=false
	_readout.size_flags_horizontal=Control.SIZE_EXPAND_FILL;_readout.size_flags_vertical=Control.SIZE_EXPAND_FILL
	_readout.add_theme_font_size_override("normal_font_size",14);_readout.custom_minimum_size.x=300
	body.add_child(_readout)
	var scroll := ScrollContainer.new();scroll.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL;scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	_actions=VBoxContainer.new();_actions.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	_actions.add_theme_constant_override("separation",7);scroll.add_child(_actions)
	_status=RichTextLabel.new();_status.name="ProcedureFeedback";_status.bbcode_enabled=false
	_status.custom_minimum_size.y=72;_status.fit_content=false
	_status.text="Read the measurements and operating ranges. Actions and supplies remain recorded if you close this panel."
	content.add_child(_status)
	var footer := Label.new();footer.text="E operates at stations  /  ESC closes  /  Values are simulated gameplay readings"
	footer.add_theme_font_size_override("font_size",10);footer.modulate=SKIN.MUTED;content.add_child(footer)
	state.changed.connect(_schedule_rebuild)
	_rebuild()
	close.grab_focus()

func _schedule_rebuild() -> void:
	if _rebuild_pending or _closing: return
	_rebuild_pending=true
	_rebuild.call_deferred()

func _rebuild() -> void:
	_rebuild_pending=false
	if _closing or not is_instance_valid(_actions): return
	for child in _actions.get_children(): _actions.remove_child(child);child.queue_free()
	_controls.clear()
	for action in state.actions(prop_id):
		var choice: Control
		if not action.options.is_empty():
			var dropdown := OptionButton.new();dropdown.name=action.id.replace(":","_")+"Choice"
			dropdown.clip_text=true;dropdown.fit_to_longest_item=false;dropdown.custom_minimum_size.y=36
			for option in action.options: dropdown.add_item(option[1])
			_actions.add_child(dropdown);choice=dropdown
		elif action.has("number"):
			var number := SpinBox.new();number.name=action.id+"Value"
			number.min_value=action.number.min;number.max_value=action.number.max;number.step=action.number.step
			number.value=action.number.value;number.suffix=action.number.suffix
			_actions.add_child(number);choice=number
		var button := Button.new();button.name=action.id.replace(":","_")
		button.text=action.title;button.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		button.custom_minimum_size.y=44;button.disabled=not action.enabled
		button.pressed.connect(_dispatch.bind(action,choice));_actions.add_child(button)
		var explanation := Label.new();explanation.text=action.reason
		explanation.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;explanation.modulate=SKIN.MUTED
		explanation.add_theme_font_size_override("font_size",11);_actions.add_child(explanation)
		_controls[action.id]={"button":button,"reason":explanation}
	_update_readings()

func _dispatch(action: Dictionary, control: Control) -> void:
	var value: Variant=null
	if control is OptionButton: value=action.options[control.selected][0]
	elif control is SpinBox: value=control.value
	action_requested.emit(action.id,value)

func feedback(message: String, success := true) -> void:
	_status.text=message;_status.modulate=Color(0.6,0.94,0.8) if success else Color(1,0.77,0.34)

func _process(delta: float) -> void:
	_poll+=delta
	if _poll<0.2 or _closing: return
	_poll=0.0;_update_readings()
	for action in state.actions(prop_id):
		if _controls.has(action.id):
			_controls[action.id].button.disabled=not action.enabled
			_controls[action.id].reason.text=action.reason

func _update_readings() -> void:
	var definition: Dictionary=CATALOG.definition(prop_id)
	var text: String=state.readings(definition.get("room","bridge"))+"\n\nCREW / SYSTEM RECORD\n"+state.narrative(definition.get("room","bridge"))
	if prop_id=="bridge.planning":
		text="SHIP-SIDE DUTIES / "+state.phase.to_upper()+"\n\n"
		for objective in CATALOG.OBJECTIVES:
			text+=("[VERIFIED] " if state.completed.has(objective[0]) else "[OPEN] ")+objective[1]+"\n"+state.next_step(objective[0])+"\n\n"
		text+="RECORDED EVIDENCE\n"
		for entry in state.evidence.values(): text+=str(entry)+"\n\n"
		text+="RECENT LOG\n"
		for entry in state.journal.slice(maxi(0,state.journal.size()-8)): text+=str(entry.text)+"\n"
	_readout.text=text

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		get_viewport().set_input_as_handled();close_panel()

func close_panel() -> void:
	if _closing: return
	_closing=true;closed.emit();queue_free()
