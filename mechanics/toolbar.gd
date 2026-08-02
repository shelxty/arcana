extends Control

@onready var instruction_panel: Panel = $InstructionPanel
@onready var instruction_label: Label = $InstructionPanel/MarginContainer/InstructionLabel
@onready var icon_container: HBoxContainer = $HBoxContainer
@onready var combo_progress_label: Label = $ComboProgressLabel
@onready var success_label: TextureRect = $SuccessLabel

@onready var health_bar: TextureProgressBar = $HealthBar
@onready var victory_panel: Panel = $VictoryPanel
@onready var correct_flash: TextureRect = $CorrectFlash
@onready var incorrect_flash: TextureRect = $IncorrectFlash


@onready var ceiling: TextureRect = $Ceiling


@onready var punch_impact: TextureRect = $PunchImpact
@onready var kick_impact: TextureRect = $KickImpact
@onready var taser_impact: TextureRect = $TaserImpact
@onready var electric_wire_impact: TextureRect = $ElectricWireImpact
@onready var frying_impact: TextureRect = $FryingImpact

var combo_text := {
	"Punch": "Combo: X + P + M",
	"Kick": "Combo: K + 1 + B + M",
	"Electrocute": "Combo: Shift + D + W ",
	"Fry": "Combo: L + Q + T + H",
}

var combo_sequences := {
	"Punch": [KEY_X, KEY_P, KEY_M],
	"Kick": [KEY_K, KEY_1, KEY_B, KEY_M],
	"Electrocute": [KEY_SHIFT, KEY_D, KEY_W],
	"Fry": [KEY_L, KEY_Q, KEY_T, KEY_H],
}


var hotkey_to_combo := {
	KEY_A: "Punch",
	KEY_B: "Kick",
	KEY_C: "Electrocute",
	KEY_D: "Fry",
}

var in_combo_system: bool = false
var active_combo: String = ""
var combo_step: int = 0
var completed_combos: int = 0
const COMBOS_TO_WIN := 4
const MAX_HEALTH := 4
const FLASH_DURATION := 0.15
const NEXT_SCENE_PATH := "res://scenes/scene_2.tscn"

func _ready() -> void:
	instruction_panel.visible = false
	combo_progress_label.visible = false
	success_label.visible = false
	victory_panel.visible = false
	correct_flash.visible = false
	incorrect_flash.visible = false

	punch_impact.visible = false
	kick_impact.visible = false
	taser_impact.visible = false
	electric_wire_impact.visible = false
	frying_impact.visible = false

	health_bar.max_value = MAX_HEALTH
	health_bar.value = MAX_HEALTH

	for icon_name in combo_text.keys():
		var icon: Control = icon_container.get_node(icon_name)
		icon.mouse_entered.connect(_on_icon_hover.bind(icon_name))
		icon.mouse_exited.connect(_on_icon_unhover)

func _on_icon_hover(icon_name: String) -> void:
	if in_combo_system:
		return
	instruction_label.text = combo_text[icon_name]
	instruction_panel.visible = true

func _on_icon_unhover() -> void:
	if in_combo_system:
		return
	instruction_panel.visible = false

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	var key = event.keycode

	if key == KEY_ESCAPE and in_combo_system:
		_exit_combo_system()
		return

	if active_combo == "":
		if key in hotkey_to_combo:
			_start_combo(hotkey_to_combo[key])
		return

	var expected_key: int = combo_sequences[active_combo][combo_step]
	if key == expected_key:
		_show_flash(correct_flash)
		pop_out(ceiling)
		await get_tree().create_timer(0.05).timeout
		pop_in(ceiling)
		
		_play_combo_animation(active_combo)

		combo_step += 1
		if combo_step >= combo_sequences[active_combo].size():
			_complete_combo()
		else:
			_update_progress_label()
	else:
		_show_flash(incorrect_flash)

func _show_flash(flash: TextureRect) -> void:
	flash.visible = true
	var tween = create_tween()
	tween.tween_interval(FLASH_DURATION)
	tween.tween_callback(func(): flash.visible = false)

func _start_combo(combo_name: String) -> void:
	in_combo_system = true
	active_combo = combo_name
	combo_step = 0
	instruction_label.text = combo_text[combo_name]
	instruction_panel.visible = true
	combo_progress_label.visible = true
	_update_progress_label()

func _update_progress_label() -> void:
	var total: int = combo_sequences[active_combo].size()
	combo_progress_label.text = "%s: Step %d / %d  (Esc to cancel)" % [active_combo, combo_step + 1, total]

func _complete_combo() -> void:
	completed_combos += 1
	var target_health: float = MAX_HEALTH - completed_combos

	var health_tween = create_tween()
	health_tween.tween_property(health_bar, "value", target_health, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	await get_tree().create_timer(0.6).timeout
	health_bar.value = target_health 
	print("Health bar value: ", health_bar.value)
	print("target health: ", target_health)
	success_label.visible = true
	health_bar.visible = false

	instruction_panel.visible = false
	combo_progress_label.visible = false

	active_combo = ""
	combo_step = 0

	await get_tree().create_timer(1.0).timeout
	success_label.visible = false
	health_bar.visible = true

	if completed_combos >= COMBOS_TO_WIN:
		_show_victory()

func _show_victory() -> void:
	in_combo_system = false # locked out of re-entering combos once victory sequence starts

	await get_tree().create_timer(1.0).timeout
	victory_panel.visible = true
	health_bar.visible = false

	await get_tree().create_timer(3.0).timeout
	victory_panel.visible = false

	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file(NEXT_SCENE_PATH)

func _exit_combo_system() -> void:
	in_combo_system = false
	active_combo = ""
	combo_step = 0
	instruction_panel.visible = false
	combo_progress_label.visible = false

func pop_out(sprite) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", Vector2(4, 4), 0.2)

func pop_in(sprite) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite, "scale", Vector2(3, 3), 0.2)

# ---------------

func _get_ceiling_screen_pos() -> Vector2:
	# return get_global_transform_with_canvas().affine_inverse() * ceiling.get_global_transform_with_canvas().origin
	return Vector2(4500, -1500)

func _play_combo_animation(combo_name: String) -> void:
	match combo_name:
		"Punch":
			_play_hit_burst(punch_impact)
		"Kick":
			_play_hit_burst(kick_impact)
		"Electrocute":
			_play_electrocute()
		"Fry":
			_play_fry()

func _play_hit_burst(impact: TextureRect) -> void:
	var center := _get_ceiling_screen_pos()
	print(center)
	
	var hit_count := 3
	var stagger := 0.1

	for i in range(hit_count):
		var offset := Vector2(randf_range(-1500, 1500), randf_range(-1500, 1500))
		_play_single_impact(impact, center + offset, i * stagger)
		await get_tree().create_timer(0.15).timeout

func _play_single_impact(impact: TextureRect, pos: Vector2, delay: float) -> void:
	impact.position = pos - impact.size / 2
	impact.scale = Vector2.ZERO
	impact.modulate.a = 1.0

	var tween = create_tween()
	tween.tween_interval(delay)
	tween.tween_callback(func(): impact.visible = true)
	tween.tween_property(impact, "scale", Vector2(1.2, 1.2), 0.06).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(impact, "scale", Vector2(1.0, 1.0), 0.04)
	tween.parallel().tween_property(impact, "modulate:a", 0.0, 0.1).set_delay(0.05)
	tween.tween_callback(func(): impact.visible = false)

func _play_electrocute() -> void:
	var center := _get_ceiling_screen_pos()
	print(center)

	taser_impact.position = center + Vector2(-4050, -3000) - taser_impact.size / 2
	taser_impact.scale = Vector2(4, 4)
	taser_impact.modulate.a = 1.0
	taser_impact.visible = true

	electric_wire_impact.position = center + Vector2(-4050, -3000) - electric_wire_impact.size / 2
	electric_wire_impact.scale = Vector2(4, 4)
	electric_wire_impact.modulate.a = 1.0

	var taser_tween = create_tween()
	taser_tween.tween_property(taser_impact, "scale", Vector2(4,4), 0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var wire_tween = create_tween()
	wire_tween.tween_interval(0.05)
	wire_tween.tween_callback(func(): electric_wire_impact.visible = true)
	wire_tween.tween_property(electric_wire_impact, "scale", Vector2(4,4), 0.06)
	for i in range(4):
		wire_tween.tween_property(electric_wire_impact, "position:x", electric_wire_impact.position.x + 3, 0.02)
		wire_tween.tween_property(electric_wire_impact, "position:x", electric_wire_impact.position.x - 3, 0.02)

	var original_modulate: Color = ceiling.modulate
	var yellow_tween = create_tween()
	yellow_tween.tween_property(ceiling, "modulate", Color(0.794, 0.519, 0.178, 1.0), 0.1)
	yellow_tween.tween_property(ceiling, "modulate", original_modulate, 0.15)

	await wire_tween.finished

	var fade_tween = create_tween().set_parallel(true)
	fade_tween.tween_property(taser_impact, "modulate:a", 0.0, 0.1)
	fade_tween.tween_property(electric_wire_impact, "modulate:a", 0.0, 0.1)
	await fade_tween.finished
	taser_impact.visible = false
	electric_wire_impact.visible = false

func _play_fry() -> void:
	var center := _get_ceiling_screen_pos()
	print(center)
	var pan_target_pos := center + Vector2(-3000, -1500) - frying_impact.size / 2
	var pan_start_pos := pan_target_pos + Vector2(0, 30)

	frying_impact.position = pan_start_pos
	frying_impact.modulate.a = 0.0
	frying_impact.visible = true

	var pan_tween = create_tween().set_parallel(true)
	pan_tween.tween_property(frying_impact, "position", pan_target_pos, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	pan_tween.tween_property(frying_impact, "modulate:a", 1.0, 0.15)

	var original_modulate: Color = ceiling.modulate
	var red_tween = create_tween()
	red_tween.tween_property(ceiling, "modulate", Color(1.0, 0.3, 0.3), 0.1)
	red_tween.tween_property(ceiling, "modulate", original_modulate, 0.15)

	await get_tree().create_timer(0.3).timeout

	var pan_out_tween = create_tween().set_parallel(true)
	pan_out_tween.tween_property(frying_impact, "position", pan_start_pos, 0.1)
	pan_out_tween.tween_property(frying_impact, "modulate:a", 0.0, 0.1)
	await pan_out_tween.finished
	frying_impact.visible = false
