extends Node


func load_game(slug):
	if slug == 'tic-tac-toe':
		get_tree().change_scene_to_file("res://games/tic-tac-toe/tic_tac_toe.tscn")


func load_main_menu():
	get_tree().change_scene_to_file("res://menus/main_menu.tscn")


func load_multiplayer_menu():
	get_tree().change_scene_to_file("res://menus/multiplayer_menu.tscn")


func load_multiplayer_lobby():
	get_tree().change_scene_to_file("res://menus/multiplayer_lobby.tscn")


func quit_game():
	get_tree().quit()
