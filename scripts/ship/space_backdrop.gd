extends AnimatedSprite2D

const FRAMES: Array[Texture2D] = [
	preload("res://art/overview/space_frames/asteria_space_backdrop_00.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_01.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_02.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_03.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_04.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_05.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_06.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_07.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_08.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_09.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_10.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_11.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_12.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_13.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_14.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_15.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_16.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_17.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_18.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_19.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_20.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_21.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_22.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_23.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_24.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_25.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_26.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_27.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_28.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_29.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_30.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_31.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_32.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_33.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_34.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_35.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_36.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_37.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_38.jpg"),
	preload("res://art/overview/space_frames/asteria_space_backdrop_39.jpg"),
]

const ANIMATION_NAME := &"drift"
const FRAMES_PER_SECOND := 12.0


func _ready() -> void:
	var frame_set := SpriteFrames.new()
	frame_set.add_animation(ANIMATION_NAME)
	frame_set.set_animation_speed(ANIMATION_NAME, FRAMES_PER_SECOND)
	frame_set.set_animation_loop(ANIMATION_NAME, true)
	for frame_texture in FRAMES:
		frame_set.add_frame(ANIMATION_NAME, frame_texture)
	sprite_frames = frame_set
	play(ANIMATION_NAME)
