extends Control


func _on_single_player_button_pressed() -> void:
	print('Load single player here')


func _on_multiplayer_button_pressed() -> void:
	SceneManager.load_multiplayer_menu()


func _on_settings_button_pressed() -> void:
	print('Load settings here')


func _on_exit_button_pressed() -> void:
	SceneManager.quit_game()
