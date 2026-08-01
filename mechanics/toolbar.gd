extends Control

@onready var instruction_panel: Panel = $InstructionPanel
@onready var instruction_label: Label = $InstructionPanel/MarginContainer/InstructionLabel
@onready var icon_container: HBoxContainer = $HBoxContainer

var combo_text := {
	"Punch": "Combo: X + P + M",
	"Kick": "Combo: K + 1 + B + M",
	"Electrocute": "Combo: Shift + N + W",
	"Fry": "Combo: < + Q + T + H",
}

func _ready() -> void:
	instruction_panel.visible = false
	for icon_name in combo_text.keys():
		var icon: Control = icon_container.get_node(icon_name)
		icon.mouse_entered.connect(_on_icon_hover.bind(icon_name))
		icon.mouse_exited.connect(_on_icon_unhover)

func _on_icon_hover(icon_name: String) -> void:
	instruction_label.text = combo_text[icon_name]
	instruction_panel.visible = true

func _on_icon_unhover() -> void:
	instruction_panel.visible = false
