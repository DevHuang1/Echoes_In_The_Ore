class_name CrewDialogue
extends CanvasLayer
## Conversations in the redesigned dialogue frame. Keeps the original contract
## (start_dialogue / cancel_dialogue / dialogue_finished / conversation_finished /
## conversation_id) so the walkthrough's story code is unchanged. People on the
## ship terminal (Maya, Leila) talk through the comms device; Amara in person.

const SCREEN := preload("res://scripts/ui/eito/dialogue_screen.gd")

signal dialogue_finished(accepted_tasks: bool)
signal conversation_finished(conversation_id: String, result_id: String)

const CHARS_PER_SECOND := 2.0 / 0.022
const ECHO_PERSON := 1.0
const ECHO_COMMS := 0.65

var conversation_id := ""
var mode := "person"        # person | comms | ribbon
var who := "amara"
var display_name := "Amara"
var tag := "HYDROPONICS"
var objective := ""
var speaking := "them"      # them | me
var phase := "idle"         # typing | wait | choose | end | echo | idle
var choices: Array = []
var transcript: Array = []
var ribbon_text := ""
var ribbon_t := 0.0

var _lines: Array[String] = []
var _index := 0
var _typed := 0.0
var _offer := false
var _active := false
var _echo_text := ""
var _echo_result := ""
var _echo_left := 0.0
var _generation := 0
var _last_finish_ms := -100000
var _ribbon_left := 0.0
var _root: Control
var _screen: Control

func _init() -> void:
	layer = 20
	_root = _Dim.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	_screen = SCREEN.new()
	_screen.name = "DialogueScreen"
	add_child(_screen)
	_screen.setup(self)
	_set_shown(false)

func _ready() -> void:
	get_viewport().size_changed.connect(_layout)
	_layout()

func _layout() -> void:
	if not is_inside_tree(): return
	var vs := get_viewport().get_visible_rect().size
	var s := minf(1.0, minf(vs.x / 1280.0, vs.y / 720.0))
	_screen.scale = Vector2(s, s)
	_screen.position = ((vs - Vector2(1280, 720) * s) * 0.5).floor()

func _set_shown(on: bool, ribbon_only := false) -> void:
	_root.visible = on and not ribbon_only
	_screen.visible = on
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE if ribbon_only else Control.MOUSE_FILTER_STOP
	_screen.set_process(on)

# ------------------------------------------------------------ public API
func start_dialogue(lines: Array[String], offer_enabled: bool = false, context: Dictionary = {}) -> void:
	if lines.is_empty(): return
	var speaker := str(context.get("speaker", "AMARA OKOYE / MED / HYDROPONICS"))
	var parts := speaker.split("/")
	var first := parts[0].strip_edges().split(" ")[0].to_lower()
	var next_mode := "comms" if speaker.contains("TERMINAL") else "person"
	var continuing := next_mode == "comms" and mode == "comms" and who == first and Time.get_ticks_msec() - _last_finish_ms < 400
	who = first if first in ["amara", "maya", "leila"] else ("maya" if next_mode == "comms" else "amara")
	display_name = parts[0].strip_edges().split(" ")[0].capitalize()
	tag = parts[-1].strip_edges() if next_mode == "person" and parts.size() > 1 else ""
	mode = next_mode
	objective = str(context.get("objective", ""))
	if objective.is_empty(): objective = "Talk with " + display_name
	conversation_id = str(context.get("id", ""))
	_generation += 1
	_offer = offer_enabled
	choices = []
	for c in context.get("choices", []): choices.append({"id":str(c.id), "label":str(c.label)})
	if choices.is_empty() and _offer:
		choices = [{"id":"accept", "label":"I'll take both jobs"}, {"id":"decline", "label":"Maybe later"}]
	_lines = lines.duplicate()
	_index = 0
	if not continuing: transcript = []
	_active = true
	_ribbon_left = 0.0
	_set_shown(true)
	_begin_line()

func cancel_dialogue() -> void:
	if not _active: return
	if phase == "echo": return
	if conversation_id.is_empty(): _finish_legacy(false)
	else: _choose("cancelled")

## Briefly shows the design's NEW OBJECTIVE ribbon over the game.
func flash_objective(text: String) -> void:
	if _active or text.is_empty(): return
	ribbon_text = text; ribbon_t = _screen.now; _ribbon_left = 3.0
	mode = "ribbon"
	_set_shown(true, true)

# ------------------------------------------------------------ view helpers
func full_text() -> String:
	if phase == "echo" and mode == "person": return _echo_text
	return _lines[_index] if _index < _lines.size() else ""

func visible_text() -> String:
	var t := full_text()
	if phase == "typing": return t.substr(0, int(_typed))
	return t

## Replies that will appear once the current line finishes, so the frame can
## make room for them up front instead of jumping when they arrive.
func reserved_choices() -> int:
	if phase == "choose": return choices.size()
	if phase in ["typing", "wait", "end"] and _index == _lines.size() - 1 and not _continue_choice: return choices.size()
	return 0

func show_more() -> bool:
	return mode == "person" and phase in ["typing", "wait", "end"]

# ------------------------------------------------------------ flow
func _begin_line() -> void:
	speaking = "them"
	_typed = 0.0
	phase = "typing"
	if mode == "comms":
		transcript.append({"who":"them", "name":display_name.to_upper(), "text":_lines[_index], "shown":0, "t0":_screen.now})
		while transcript.size() > 4: transcript.pop_front()

func _line_done() -> void:
	if mode == "comms" and not transcript.is_empty(): transcript[-1].shown = str(transcript[-1].text).length()
	if _index < _lines.size() - 1:
		phase = "wait"
		if mode == "comms": choices_for_continue()
	elif not choices.is_empty(): phase = "choose"
	else:
		phase = "end"
		if mode == "comms": choices_for_continue(true)

var _continue_choice := false
func choices_for_continue(close := false) -> void:
	# The comms device has no click-to-continue box; a single reply row stands in.
	_continue_choice = true
	_saved_choices = choices
	choices = [{"id":"__next", "label":"Close channel" if close else "Continue", "key":"E"}]
	phase = "choose"

var _saved_choices: Array = []

func advance() -> void:
	if not _active: return
	match phase:
		"typing":
			_typed = float(full_text().length()); _line_done()
		"wait":
			_index += 1; _begin_line()
		"end":
			_close_without_choice()
		"choose":
			if _continue_choice: pick(0)

func pick(i: int) -> void:
	if not _active or phase != "choose" or i < 0 or i >= choices.size(): return
	if _continue_choice:
		_continue_choice = false
		choices = _saved_choices
		if _index < _lines.size() - 1:
			_index += 1; _begin_line()
		else:
			_close_without_choice()
		return
	var c: Dictionary = choices[i]
	if _offer and conversation_id.is_empty():
		_finish_legacy(c.id == "accept"); return
	_echo_text = str(c.label); _echo_result = str(c.id)
	speaking = "me"; phase = "echo"
	if mode == "comms":
		transcript.append({"who":"me", "name":"THURA", "text":_echo_text, "shown":_echo_text.length(), "t0":_screen.now})
		while transcript.size() > 4: transcript.pop_front()
		_echo_left = ECHO_COMMS
	else:
		_echo_left = ECHO_PERSON

func _close_without_choice() -> void:
	if conversation_id.is_empty(): _finish_legacy(false)
	else: _choose("closed")

func _finish_legacy(accepted: bool) -> void:
	_active = false; phase = "idle"
	_last_finish_ms = Time.get_ticks_msec()
	_set_shown(false)
	dialogue_finished.emit(accepted)

func _choose(result: String) -> void:
	if not _active: return
	_active = false; phase = "idle"
	_last_finish_ms = Time.get_ticks_msec()
	_set_shown(false)
	conversation_finished.emit(conversation_id, result)

func _process(delta: float) -> void:
	if _ribbon_left > 0.0:
		_ribbon_left -= delta
		if _ribbon_left <= 0.0 and not _active:
			mode = "person"; ribbon_text = ""; _set_shown(false)
	if not _active: return
	if phase == "typing":
		_typed += delta * CHARS_PER_SECOND
		if mode == "comms" and not transcript.is_empty(): transcript[-1].shown = int(_typed)
		if _typed >= full_text().length(): _line_done()
	elif phase == "echo":
		_echo_left -= delta
		if _echo_left <= 0.0:
			var gen := _generation
			if _offer and conversation_id.is_empty(): _finish_legacy(_echo_result == "accept")
			elif gen == _generation: _choose(_echo_result)

func _input(event: InputEvent) -> void:
	if not _active: return
	var ke := event as InputEventKey
	var interact := event.is_action_pressed(&"interact")
	if ke == null:
		# Gamepad / action events: interact advances or takes the first reply.
		if not interact: return
		if phase == "choose" and not _continue_choice and not choices.is_empty(): pick(0)
		else: advance()
		get_viewport().set_input_as_handled(); return
	if not ke.pressed or ke.echo: return
	var k: int = ke.keycode
	var handled := true
	if k == KEY_ESCAPE: cancel_dialogue()
	elif interact or k in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if phase == "choose" and not _continue_choice and not choices.is_empty(): pick(0)
		else: advance()
	elif k == KEY_Q and phase == "choose" and not _continue_choice and not choices.is_empty():
		pick(choices.size() - 1)
	elif k >= KEY_1 and k <= KEY_9 and phase == "choose" and not _continue_choice:
		pick(k - KEY_1)
	elif k == KEY_TAB:
		_screen.key(event)
	else:
		handled = false
	if handled: get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	cancel_dialogue()

## Dims the ship behind the conversation like the design's scene wash.
class _Dim extends Control:
	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0, 0, 0, 0.28))
		# The design's HUD row sits on a dark wall; over the bright ship it needs
		# a little shade to stay readable.
		var top := Color(0.02, 0.03, 0.04, 0.72); var clear := Color(0.02, 0.03, 0.04, 0.0)
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(size.x, 0), Vector2(size.x, 72), Vector2(0, 72)]), PackedColorArray([top, top, clear, clear]))
	func _notification(what: int) -> void:
		if what == NOTIFICATION_RESIZED: queue_redraw()
