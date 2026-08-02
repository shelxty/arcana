extends Node2D
func _ready() -> void:
	stagger_pop_in()

func stagger_pop_in() -> void:
	var delay_step: float = 0.15
	var index: int = 0
	
	for child in $pop_in.get_children():
		child.scale = Vector2.ZERO #width + height to zero = invis
		
		var tween = create_tween().set_parallel(true)
		var start_delay = index * delay_step
		
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(child, "scale", Vector2.ONE, 0.2).set_delay(start_delay)
		if index == 6:
			await tween.finished
			$pop_in/start.grab_focus()
		
		index += 1

func pop_out(sprite) -> void:
	sprite.pivot_offset = sprite.size / 2
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite,"scale", Vector2(1.3,1.3), 0.2)
	
func pop_in(sprite) -> void:
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(sprite,"scale", Vector2(1,1), 0.2)
	

func _on_start_focus_entered() -> void:
	pop_out($pop_in/start)
	pop_in($pop_in/credits)
	pop_in($pop_in/quit)

func _on_credits_focus_entered() -> void:
	pop_out($pop_in/credits)
	pop_in($pop_in/start)
	pop_in($pop_in/quit)

func _on_quit_focus_entered() -> void:
	pop_out($pop_in/quit)
	pop_in($pop_in/credits)
	pop_in($pop_in/start)


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/scene_1.tscn")
