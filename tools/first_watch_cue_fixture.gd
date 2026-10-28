extends Node
## Contract fixture only: no cinematic art, voice or story mutation.
signal cue_finished(request_token: String,cue_id: String,outcome: String,landing_id: String)
var context := {}
func required_actor_ids() -> PackedStringArray:
	return PackedStringArray([str(Engine.get_meta("first_watch_fixture_actor","thura"))])
func play_cue(value: Dictionary) -> void:
	context=value
	var camera := Camera2D.new(); add_child(camera); camera.make_current()
	context.gameplay_camera.zoom=Vector2(3,3)
	context.gameplay_camera.offset=Vector2(17,11)
	context.gameplay_camera.position=Vector2(12,-9)
	context.gameplay_camera.position_smoothing_enabled=not context.gameplay_camera.position_smoothing_enabled
	context.gameplay_camera.limit_left=-10;context.gameplay_camera.limit_top=-20
	context.gameplay_camera.limit_right=400;context.gameplay_camera.limit_bottom=500
	var outcome := str(Engine.get_meta("first_watch_fixture_outcome","pending"))
	if outcome=="node_exit": queue_free()
	elif outcome!="pending":
		await get_tree().process_frame
		cue_finished.emit(str(context.request_token),str(context.cue_id),outcome,str(Engine.get_meta("first_watch_fixture_landing","ship")))
