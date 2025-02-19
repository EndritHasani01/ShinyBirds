extends Node3D

@export var total_time: float = 120.0
var remaining_time: float
var treasures_collected: int = 0
var total_treasures: int = 0
var game_ended: bool = false
var did_we_win: bool = false

# best records (best_time: lowest elapsed time wins, best_score: highest treasures)
var best_time: float = 9999.0
var best_score: int = 0

@onready var main_screen_img: Control = $HUD/MainScreen_Img
@onready var timer_label: Label = $HUD/MainScreen_Img/TimerLabel
@onready var score_label: Label = $HUD/MainScreen_Img/ScoreLabel
@onready var timer_progress: ProgressBar = $HUD/MainScreen_Img/TimerProgressBar
@onready var score_progress: ProgressBar = $HUD/MainScreen_Img/ScoreProgressBar

@onready var end_screen_img: Control = $HUD/EndScreen_Img
@onready var end_time_label: Label = $HUD/EndScreen_Img/TimeLabel
@onready var end_score_label: Label = $HUD/EndScreen_Img/ScoreLabel
@onready var end_best_time_label: Label = $HUD/EndScreen_Img/BestTimeLabel
@onready var end_best_score_label: Label = $HUD/EndScreen_Img/BestScoreLabel
@onready var retry_label: Label = $HUD/EndScreen_Img/RetryLabel
@onready var result_label: Label = $HUD/EndScreen_Img/ResultLabel

# We'll create an AudioStreamPlayer in code for background music.
var background_music_player: AudioStreamPlayer

# --- NEW: Preload your sfx. ---------------------------------
var success_sound = preload("res://Sounds/success.mp3")
var victory_sound = preload("res://Sounds/victory.mp3")
var lose_sound    = preload("res://Sounds/lose.mp3")

# A dedicated AudioStreamPlayer for one-shot sfx.
var sfx_player: AudioStreamPlayer

func _ready() -> void:
	# 1) Play background music
	_background_music_setup()

	# 2) Count all treasure nodes
	total_treasures = get_tree().get_nodes_in_group("treasure").size()
	remaining_time = total_time
	game_ended = false

	# Hide the end screen overlay initially
	end_screen_img.visible = false

	# Create our sfx_player
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	# Set up progress bars
	timer_progress.max_value = total_time
	timer_progress.value = remaining_time

	score_progress.max_value = total_treasures
	score_progress.value = treasures_collected

	update_ui()

func _background_music_setup() -> void:
	# Create a new AudioStreamPlayer on the fly:
	background_music_player = AudioStreamPlayer.new()
	add_child(background_music_player)

	# Load the MP3 (make sure your path matches the actual file location)
	var music_stream = preload("res://Sounds/beautiful-melancholy-piano.mp3")
	background_music_player.stream = music_stream

	# Optional: if the stream type supports looping, enable it:
	# if music_stream is AudioStreamOGGVorbis or AudioStreamMP3:
	#     music_stream.loop = true

	background_music_player.play()

func _process(delta: float) -> void:
	if game_ended:
		return

	remaining_time -= delta
	update_ui()

	if remaining_time <= 0:
		on_time_up()

func update_ui() -> void:
	# Update timer and score text
	timer_label.text = "Time: " + str(int(remaining_time))
	score_label.text = "Treasures: %d / %d" % [treasures_collected, total_treasures]

	# Update progress bars
	timer_progress.value = remaining_time
	score_progress.value = treasures_collected

	# Change timer text color (green → orange → red)
	var progress_ratio = remaining_time / total_time
	if progress_ratio < 0.3:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif progress_ratio < 0.6:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.add_theme_color_override("font_color", Color.GREEN)

func on_treasure_collected() -> void:
	treasures_collected += 1

	# Play "success" sound
	sfx_player.stream = success_sound
	sfx_player.play()

	# Animate the score label with a “pop” effect using a Tween
	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_label, "scale", Vector2(1, 1), 0.2).set_delay(0.2)

	update_ui()

	if treasures_collected == total_treasures:
		on_win()

func on_win() -> void:
	game_ended = true
	did_we_win = true

	# Play "victory" sound
	sfx_player.stream = victory_sound
	sfx_player.play()

	_show_end_screen("Victory!")

func on_time_up() -> void:
	game_ended = true
	did_we_win = false

	# Play "lose" sound
	sfx_player.stream = lose_sound
	sfx_player.play()

	_show_end_screen("Time's up! You lose!")

func _show_end_screen(message: String) -> void:
	# Hide the in-game UI
	main_screen_img.visible = false

	if did_we_win:
		result_label.add_theme_color_override("font_color", Color.DARK_GREEN)
	else:
		result_label.add_theme_color_override("font_color", Color.DARK_RED)

	result_label.text = message

	# Calculate elapsed time
	var elapsed_time: float = (total_time - remaining_time) if did_we_win else total_time

	# Update best records:
	# For best time, lower elapsed time is better—only update if the player won.
	if did_we_win and elapsed_time < best_time:
		best_time = elapsed_time

	# For best score, update if this run’s score is higher.
	if treasures_collected > best_score:
		best_score = treasures_collected

	# Update the end screen labels
	end_time_label.text = "Your Time: " + str(round(elapsed_time)) + " sec"
	end_score_label.text = "Your Score: " + str(treasures_collected)

	# Only show best time if a win has been recorded
	if best_time < 9999.0:
		end_best_time_label.text = "Best Time: " + str(round(best_time)) + " sec"
	else:
		end_best_time_label.text = "Best Time: N/A"

	end_best_score_label.text = "Best Score: " + str(best_score)

	# Show the retry prompt
	retry_label.text = "Press Enter To Try Again"

	# Make the end screen overlay visible
	end_screen_img.visible = true

func _input(event: InputEvent) -> void:
	# When the game has ended, allow the player to restart by pressing Enter (ui_accept)

	if event.is_action_pressed("quit"):
		get_tree().quit()

	if game_ended and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
