extends Area3D

func _ready() -> void:
	# Add this to a group "treasure" so we can count them in Main
	add_to_group("treasure")
	# Connect the body_entered signal if not connected in the editor
	self.body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	# Check if it's the player
	if body.name == "Player":
		# We'll tell Main that we found a treasure
		var main_node = get_tree().get_root().get_node("Main")
		if main_node:
			main_node.on_treasure_collected()

		# Remove ourselves from the game
		queue_free()
