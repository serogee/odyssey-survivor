extends Control

var level = "res://World/world1.tscn"

<<<<<<< Updated upstream
func _on_btn_play_click_end():
	get_tree().change_scene_to_file(level)

=======
func _on_btn_play_click_end() -> void:
	get_tree().change_scene_to_file(level)
>>>>>>> Stashed changes
func _on_btn_exit_click_end():
	get_tree().quit()


