class_name ShipEquipmentUI
extends RefCounted
## Local instrument skin with clean, spaced small-font typography.
const FONT := preload("res://art/ui/pixel/ore_pixel_font.fnt")
const INK := Color("101f25")
const WELL := Color("0b171d")
const METAL := Color("89969a")
const EDGE := Color("a5b7bb")
const SHADOW := Color("303e43")
const TEXT := Color("eee7d3")
const MUTED := Color("a5b7bb")
const CYAN := Color("68dce5")
const AMBER := Color("edb953")
const RED := Color("f17c71")
const EXISTING := preload("res://themes/ship_pixel_theme.tres")

static func box(background: Color = INK, border: Color = SHADOW, padding := 10) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=background;s.border_color=border;s.set_border_width_all(2)
	s.border_width_bottom=4;s.set_content_margin_all(padding)
	s.corner_detail=1;s.corner_radius_top_left=3;s.corner_radius_bottom_right=3
	s.anti_aliasing=false
	return s

static func theme() -> Theme:
	var t := Theme.new();t.default_font=FONT;t.default_font_size=11
	for type in ["Label","RichTextLabel","Button","OptionButton","LineEdit","SpinBox","PopupMenu"]:
		t.set_color("font_color",type,TEXT)
	for type in ["Button","OptionButton"]:
		t.set_stylebox("normal",type,box(Color("35474d"),EDGE,8))
		t.set_stylebox("hover",type,box(Color("43585b"),AMBER,8))
		t.set_stylebox("pressed",type,box(INK,CYAN,8))
		t.set_stylebox("disabled",type,box(Color("253238"),Color("526268"),8))
		var focus := box(Color(0,0,0,0),AMBER,0);focus.draw_center=false
		t.set_stylebox("focus",type,focus)
		t.set_color("font_disabled_color",type,Color("94a3a7"))
		t.set_color("font_focus_color",type,TEXT)
		t.set_font_size("font_size",type,10)
	t.set_constant("line_spacing","Label",4)
	t.set_font_size("font_size","Label",11)
	t.set_stylebox("panel","PanelContainer",box())
	t.set_stylebox("panel","PopupMenu",box(WELL,EDGE,8))
	t.set_stylebox("hover","PopupMenu",box(SHADOW,AMBER,6))
	t.set_stylebox("normal","LineEdit",box(WELL,EDGE,6))
	t.set_stylebox("focus","LineEdit",box(WELL,AMBER,6))
	t.set_stylebox("normal","InventorySlot",box(WELL,SHADOW,6))
	t.set_stylebox("selected","InventorySlot",box(WELL,CYAN,6))
	for item in ["slider","grabber_area","grabber_area_highlight"]:
		t.set_stylebox(item,"HSlider",EXISTING.get_stylebox(item,"HSlider"))
	for item in ["grabber","grabber_highlight","grabber_disabled"]:
		t.set_icon(item,"HSlider",EXISTING.get_icon(item,"HSlider"))
	t.set_color("font_color","RichTextLabel",TEXT)
	t.set_color("default_color","RichTextLabel",TEXT)
	t.set_font_size("normal_font_size","RichTextLabel",10)
	t.set_constant("line_separation","RichTextLabel",4)
	return t

static func apply(node: Control) -> void:
	node.theme=theme();node.texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST

static func _scaled_font_size(requested: int) -> int:
	if requested >= 24:
		return 16
	if requested >= 20:
		return 14
	if requested >= 18:
		return 12
	if requested >= 14:
		return 10
	if requested >= 12:
		return 9
	return maxi(8, requested)

static func label(text: String, size := 11, color: Color = TEXT) -> Label:
	var l := Label.new();l.text=text;l.add_theme_font_size_override("font_size",_scaled_font_size(size))
	l.add_theme_constant_override("line_spacing",4)
	l.add_theme_color_override("font_color",color);l.mouse_filter=Control.MOUSE_FILTER_IGNORE
	return l

static func button(text: String, callback: Callable, tip := "") -> Button:
	var b := CommandButton.new();b.text=text;b.custom_minimum_size.y=36
	b.add_theme_font_size_override("font_size",10)
	b.tooltip_text=tip;b.focus_mode=Control.FOCUS_ALL
	if callback.is_valid(): b.pressed.connect(callback)
	return b

class CommandButton extends Button:
	var mechanism := ""
	func _draw() -> void:
		if mechanism.is_empty(): return
		var c := Color("a5b7bb") if disabled else Color("edb953") if mechanism=="isolate" else Color("68dce5")
		var y := floorf(size.y/2)
		if mechanism=="isolate" or mechanism=="restore":
			draw_rect(Rect2(7,y-9,14,18),Color("0b171d"))
			draw_rect(Rect2(9,y-7 if mechanism=="isolate" else y+1,10,6),c)
		else:
			draw_rect(Rect2(8,y-4,6,8),c)

static func panel(padding := 10, outer := false) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel",box(METAL if outer else INK,EDGE if outer else SHADOW,padding))
	return p

static func stack(parent: Node, gap := 8) -> VBoxContainer:
	var v := VBoxContainer.new();v.add_theme_constant_override("separation",gap)
	v.size_flags_horizontal=Control.SIZE_EXPAND_FILL;parent.add_child(v);return v

class SegmentedMeter extends Control:
	var value := 0.0
	var maximum := 100.0
	var tint := Color("68dce5")
	var segments := 24
	func _init() -> void:
		custom_minimum_size.y=12;mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var w := floorf(size.x/segments)
		var n := int(roundf(clampf(value/maxf(maximum,0.001),0,1)*segments))
		for i in range(segments):
			draw_rect(Rect2(i*w,0,maxf(1,w-2),size.y),tint if i<n else Color("303e43"))
	func set_reading(reading: float, limit: float=100.0, color: Color=CYAN) -> void:
		value=reading;maximum=limit;tint=color;queue_redraw()

class Readout extends PanelContainer:
	var heading: Label
	var reading: Label
	var detail: Label
	var meter: SegmentedMeter
	static func _make_label(text: String, size: int, color: Color) -> Label:
		var result := Label.new()
		result.text = text
		result.add_theme_font_size_override("font_size", size)
		result.add_theme_color_override("font_color", color)
		result.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return result

	func _init() -> void:
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color("0b171d")
		panel_style.border_color = Color("303e43")
		panel_style.set_border_width_all(2)
		panel_style.border_width_bottom = 4
		panel_style.set_content_margin_all(8)
		panel_style.corner_detail = 1
		panel_style.corner_radius_top_left = 3
		panel_style.corner_radius_bottom_right = 3
		panel_style.anti_aliasing = false
		add_theme_stylebox_override("panel", panel_style)
		size_flags_horizontal=Control.SIZE_EXPAND_FILL
		var v := VBoxContainer.new();v.add_theme_constant_override("separation",3);add_child(v)
		heading=_make_label("",12,Color("a5b7bb"));v.add_child(heading)
		reading=_make_label("",24,Color("68dce5"));v.add_child(reading)
		meter=SegmentedMeter.new();v.add_child(meter)
		detail=_make_label("",12,Color("a5b7bb"));detail.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		v.add_child(detail)
	func show_reading(title: String, value_text: String, hint: String, value: float, maximum: float, color: Color) -> void:
		heading.text=title;reading.text=value_text;detail.text=hint;detail.tooltip_text=hint
		reading.add_theme_font_size_override("font_size",13 if value_text.length()>10 else 16)
		reading.add_theme_color_override("font_color",color);meter.set_reading(value,maximum,color)

class Lamp extends HBoxContainer:
	var bulb: ColorRect
	var caption: Label
	static func _make_label(text: String, size: int) -> Label:
		var result := Label.new()
		result.text = text
		result.add_theme_font_size_override("font_size", size)
		result.add_theme_color_override("font_color", Color("eee7d3"))
		result.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return result

	func _init() -> void:
		add_theme_constant_override("separation",6)
		bulb=ColorRect.new();bulb.custom_minimum_size=Vector2(8,8)
		bulb.size_flags_vertical=Control.SIZE_SHRINK_CENTER;bulb.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(bulb);caption=_make_label("",12);add_child(caption)
	func set_status(text: String, color: Color) -> void:
		bulb.color=color;caption.text=text;caption.add_theme_color_override("font_color",color)

class Confirmation extends VBoxContainer:
	## A review card above the real commit control; no duplicate mission state.
	static func _make_label(text: String, color: Color) -> Label:
		var result := Label.new()
		result.text = text
		result.add_theme_font_size_override("font_size", 12)
		result.add_theme_color_override("font_color", color)
		result.mouse_filter = Control.MOUSE_FILTER_IGNORE
		return result

	func show_review(title: String,description: String) -> void:
		add_theme_constant_override("separation",4)
		add_child(_make_label(title,Color("edb953")))
		var detail := _make_label(description,Color("a5b7bb"))
		detail.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;add_child(detail)

class Chassis extends Control:
	func _init() -> void:
		mouse_filter=Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		for x in [7.0,size.x-9]:
			for y in [7.0,size.y-9]:
				draw_rect(Rect2(x,y,4,4),Color("0b171d"));draw_line(Vector2(x,y),Vector2(x+3,y),Color("a5b7bb"),1)
		for i in range(12):
			draw_rect(Rect2(size.x/2-36+i*6,3,3,4),Color("303e43"))
