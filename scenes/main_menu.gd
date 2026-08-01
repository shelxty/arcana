extends Node2D
func _ready() -> void:
	stagger_pop_in()

func stagger_pop_in() -> void:
	var delay_step: float = 0.1
	var index: int = 0
	
	for child in $pop_in.get_children():
		child.scale = Vector2.ZERO
		
		if child is Control:
			child.pivot_offset = child.size / 2
		elif child is Sprite2D:
			child.centered = true
		
		var tween = create_tween().set_parallel(true)
		var start_delay = index * delay_step
		
		tween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tween.tween_property(child, "scale", Vector2.ONE, 0.2).set_delay(start_delay)
		if index == 6:
			await tween.finished
			$pop_in/start.grab_focus()
		
		index += 1
