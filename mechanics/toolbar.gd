extends Control

@onready var instruction_panel: Panel = $InstructionPanel
@onready var instruction_label: Label = $InstructionPanel/MarginContainer/InstructionLabel
@onready var icon_container: HBoxContainer = $HBoxContainer
@onready var combo_progress_label: Label = $ComboProgressLabel
@onready var success_label: Label = $SuccessLabel
@onready var health_bar: TextureProgressBar = $HealthBar
@onready var victory_panel: Panel = $VictoryPanel

# Human-readable instructions shown on hover
var combo_text := {
	"Punch": "Combo: X + P + M",
	"Kick": "Combo: K + 1 + B + M",
	"Electrocute": "Combo: Shift + D + W",
	"Fry": "Combo: L + Q + T + H",
}

# Actual input sequences the player must press, in order.
# Use Godot's key constants (KEY_*) or "ui_*" action names — here we use raw keys.
var combo_sequences := {
	"Punch": [KEY_X, KEY_P, KEY_M],
	"Kick": [KEY_K, KEY_1, KEY_B, KEY_M],
	"Electrocute": [KEY_SHIFT, KEY_D, KEY_W],
	"Fry": [KEY_L, KEY_Q, KEY_T, KEY_H],
}

# Which hotkey (A/B/C/D) triggers which combo
var hotkey_to_combo := {
	KEY_A: "Punch",
	KEY_B: "Kick",
	KEY_C: "Electrocute",
	KEY_D: "Fry",
}

var in_combo_system: bool = false      # true once any hotkey has been pressed
var active_combo: String = ""          # name of combo currently being attempted, "" if just browsing
var combo_step: int = 0                # progress index into active combo's sequence
var completed_combos: int = 0
const COMBOS_TO_WIN := 4
const MAX_HEALTH := 4

func _ready() -> void:
	instruction_panel.visible = false
	combo_progress_label.visible = false
	success_label.visible = false
	victory_panel.visible = false

	health_bar.max_value = MAX_HEALTH
	health_bar.value = MAX_HEALTH

	for icon_name in combo_text.keys():
		var icon: Control = icon_container.get_node(icon_name)
		icon.mouse_entered.connect(_on_icon_hover.bind(icon_name))
		icon.mouse_exited.connect(_on_icon_unhover)

func _on_icon_hover(icon_name: String) -> void:
	if in_combo_system:
		return # don't show hover tooltips while locked into an active combo
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

	# Escape always exits the combo system entirely
	if key == KEY_ESCAPE and in_combo_system:
		_exit_combo_system()
		return

	# Not yet in a combo attempt: check if this key is one of the A/B/C/D hotkeys
	if active_combo == "":
		if key in hotkey_to_combo:
			_start_combo(hotkey_to_combo[key])
		return

	# In an active combo attempt: check if this key matches the next expected step
	var expected_key: int = combo_sequences[active_combo][combo_step]
	if key == expected_key:
		combo_step += 1
		if combo_step >= combo_sequences[active_combo].size():
			_complete_combo()
		else:
			_update_progress_label()
	# else: wrong key, ignored, player can keep trying

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
	health_bar.value = MAX_HEALTH - completed_combos

	success_label.text = "%s Success!" % active_combo
	success_label.visible = true

	instruction_panel.visible = false
	combo_progress_label.visible = false

	# reset so player can pick the next hotkey, but stay locked in the system
	active_combo = ""
	combo_step = 0

	await get_tree().create_timer(0.8).timeout
	success_label.visible = false

	if completed_combos >= COMBOS_TO_WIN:
		_show_victory()

func _show_victory() -> void:
	victory_panel.visible = true
	in_combo_system = false # or keep true if you want Escape to be the only way out — your call

func _exit_combo_system() -> void:
	in_combo_system = false
	active_combo = ""
	combo_step = 0
	instruction_panel.visible = false
	combo_progress_label.visible = false
