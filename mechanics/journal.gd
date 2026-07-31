extends CanvasLayer

@onready var icon: TextureButton = $TextureButton
@onready var panel: Control = $JournalPanel
@onready var left_text: TextEdit = $JournalPanel/LeftPage/LeftTextEdit
@onready var right_label: RichTextLabel = $JournalPanel/RightPage/RightRichLabel


var is_open: bool = false

func _ready() -> void:
	visible = true
	left_text.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1)) # dark ink
	left_text.add_theme_color_override("font_selected_color", Color(1, 1, 1))
	left_text.add_theme_color_override("font_placeholder_color", Color(0.5, 0.5, 0.5, 0.6))
	
	var handwriting_font := load("res://assets/fonts/ks_hand.ttf")
	left_text.add_theme_font_override("font", handwriting_font)
	left_text.add_theme_font_size_override("font_size", 22)
	
	panel.visible = false
	icon.pressed.connect(_on_icon_pressed)

	# close button
	if panel.has_node("CloseButton"):
		panel.get_node("CloseButton").pressed.connect(close_notebook)

func _on_icon_pressed() -> void:
	if is_open:
		close_notebook()
	else:
		open_notebook()

func open_notebook() -> void:
	play_sfx()
	panel.visible = true
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.8, 0.8)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK)
	is_open = true
	left_text.grab_focus()

func close_notebook() -> void:
	panel.visible = false
	is_open = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_notebook"):
		_on_icon_pressed()
	if is_open and event.is_action_pressed("ui_cancel"):
		close_notebook()
		# these above are for the "n" keyboard shortcut to open/close the notebook
		# the ui_cancel is a built-in inputmap 
signal note_added(text: String)

func add_auto_note(text: String, category: String = "") -> void:
	var timestamp := Time.get_time_string_from_system()
	var formatted := ""
	if category != "":
		formatted = "[b][%s][/b] %s\n" % [category, text]
	else:
		formatted = "%s\n" % text

	right_label.append_text(formatted)
	note_added.emit(text)

	if not is_open:
		_flash_icon_notification()

func _flash_icon_notification() -> void:
	if icon.has_node("NotificationDot"):
		icon.get_node("NotificationDot").visible = true # notification dot to notify player of updates to notebook
		
func play_sfx() -> void:
	var sfx = AudioStreamPlayer.new()
	add_child(sfx)
	sfx.stream = AudioGlobal.paper_rustle_audios.pick_random()
	sfx.play()
	await sfx.finished
	sfx.queue_free()

func reset_notes() -> void:
	left_text.text = ""
	right_label.text = ""

"""
now if we want to add anything to the notebook automatically, 
all we have to do is: 
Notebook.add_auto_note("Witness claims xxx", "Testimony")
"""
