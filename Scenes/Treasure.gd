extends Area3D

func _ready() -> void:
	add_to_group("treasure")
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.name == "Player":
		var main_node = get_tree().get_root().get_node("Main")
		if main_node:
			main_node.on_treasure_collected()

		queue_free()
