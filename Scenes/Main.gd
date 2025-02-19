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

var background_music_player: AudioStreamPlayer

var success_sound = preload("res://Sounds/success.mp3")
var victory_sound = preload("res://Sounds/victory.mp3")
var lose_sound    = preload("res://Sounds/lose.mp3")

var sfx_player: AudioStreamPlayer

func _ready() -> void:
	_background_music_setup()

	total_treasures = get_tree().get_nodes_in_group("treasure").size()
	remaining_time = total_time
	game_ended = false

	end_screen_img.visible = false

	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)

	timer_progress.max_value = total_time
	timer_progress.value = remaining_time

	score_progress.max_value = total_treasures
	score_progress.value = treasures_collected

	update_ui()

func _background_music_setup() -> void:
	background_music_player = AudioStreamPlayer.new()
	add_child(background_music_player)

	var music_stream = preload("res://Sounds/beautiful-melancholy-piano.mp3")
	background_music_player.stream = music_stream

	background_music_player.play()

func _process(delta: float) -> void:
	if game_ended:
		return

	remaining_time -= delta
	update_ui()

	if remaining_time <= 0:
		on_time_up()

func update_ui() -> void:
	timer_label.text = "Time: " + str(int(remaining_time))
	score_label.text = "Treasures: %d / %d" % [treasures_collected, total_treasures]

	timer_progress.value = remaining_time
	score_progress.value = treasures_collected

	var progress_ratio = remaining_time / total_time
	if progress_ratio < 0.3:
		timer_label.add_theme_color_override("font_color", Color.RED)
	elif progress_ratio < 0.6:
		timer_label.add_theme_color_override("font_color", Color.ORANGE)
	else:
		timer_label.add_theme_color_override("font_color", Color.GREEN)

func on_treasure_collected() -> void:
	treasures_collected += 1

	sfx_player.stream = success_sound
	sfx_player.play()

	var tween = create_tween()
	tween.tween_property(score_label, "scale", Vector2(1.5, 1.5), 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(score_label, "scale", Vector2(1, 1), 0.2).set_delay(0.2)

	update_ui()

	if treasures_collected == total_treasures:
		on_win()

func on_win() -> void:
	game_ended = true
	did_we_win = true

	sfx_player.stream = victory_sound
	sfx_player.play()

	_show_end_screen("Victory!")

func on_time_up() -> void:
	game_ended = true
	did_we_win = false
	
	sfx_player.stream = lose_sound
	sfx_player.play()

	_show_end_screen("Time's up! You lose!")

func _show_end_screen(message: String) -> void:
	main_screen_img.visible = false

	if did_we_win:
		result_label.add_theme_color_override("font_color", Color.DARK_GREEN)
	else:
		result_label.add_theme_color_override("font_color", Color.DARK_RED)

	result_label.text = message

	var elapsed_time: float = (total_time - remaining_time) if did_we_win else total_time

	if did_we_win and elapsed_time < best_time:
		best_time = elapsed_time

	if treasures_collected > best_score:
		best_score = treasures_collected

	end_time_label.text = "Your Time: " + str(round(elapsed_time)) + " sec"
	end_score_label.text = "Your Score: " + str(treasures_collected)

	if best_time < 9999.0:
		end_best_time_label.text = "Best Time: " + str(round(best_time)) + " sec"
	else:
		end_best_time_label.text = "Best Time: N/A"

	end_best_score_label.text = "Best Score: " + str(best_score)

	retry_label.text = "Press Enter To Try Again"

	end_screen_img.visible = true

func _input(event: InputEvent) -> void:

	if event.is_action_pressed("quit"):
		get_tree().quit()

	if game_ended and event.is_action_pressed("ui_accept"):
		get_tree().reload_current_scene()
