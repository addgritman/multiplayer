extends Control

@onready var start_game_button = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer2/StartGameButton
@onready var player_list = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayers/PlayerList
@onready var spectator_list = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxSpectators/SpectatorList
@onready var games_list = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxGames/GamesList
@onready var game_name_label = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxGameInfo/HBoxGameName/GameNameValueLabel
@onready var game_description_label = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxGameInfo/HBoxDescription/DescriptionValueLabel
@onready var player_count_label = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxGameInfo/HBoxPlayerCount/PlayerCountValueLabel
@onready var game_picture = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxGameInfo/GamePicture
@onready var swap_button = $MarginContainer2/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/PlayerSpectatorSwapButton

@export var default_game_picture: Texture

var slug = null
var min_player = 0
var max_player = 0

func _ready() -> void:
	MultiplayerManager.player_connected.connect(_on_player_connected)
	MultiplayerManager.player_disconnected.connect(_on_player_disconnected)
	MultiplayerManager.player_info_updated.connect(_on_player_info_updated)
	if not multiplayer.is_server():
		start_game_button.disabled = true
	reload_player_list()
	load_game_list()


func load_game_list():
	for game in GameData.games:
		games_list.add_item(game.name)


func reload_player_list():
	player_list.clear()
	spectator_list.clear()
	for player in MultiplayerManager.players:
		var player_info = MultiplayerManager.players[player]
		var name = player_info.name + (' (host)') if player_info.is_host else player_info.name
		if (player_info.player_type == 'player'):
			player_list.add_item(name)
		elif(player_info.player_type == 'spectator'):
			spectator_list.add_item(name)


func set_selected_game_data(game_data):
	var game_name = game_data.name
	var game_description = game_data.description
	var min_player_count = game_data.players_min
	var max_player_count = game_data.players_max
	var picture = game_data.picture
	slug = game_data.slug
	
	min_player = min_player_count
	max_player = max_player_count
	
	game_name_label.text = game_name
	game_description_label.text = game_description
	player_count_label.text = str(min_player_count) + '-' + str(max_player_count) if min_player_count != max_player_count else str(min_player_count)
	if picture != null:
		pass
	else:
		game_picture.texture = default_game_picture
	game_picture.size = Vector2(100, 100)


func can_start_game():
	if not slug:
		return false
	if player_list.item_count < min_player or player_list.item_count > max_player:
		return false
	return true


func _on_player_connected(net_id, player_info):
	reload_player_list()


func _on_player_disconnected(net_id, player_info):
	reload_player_list()


func _on_start_game_button_pressed() -> void:
	if can_start_game():
		MultiplayerManager.load_game(slug)


func _on_leave_server_button_pressed() -> void:
	MultiplayerManager.remove_multiplayer_peer()
	Chat.reset_chat()
	SceneManager.load_main_menu()


func _on_player_spectator_swap_button_pressed() -> void:
	swap_button.disabled = true
	var type = MultiplayerManager.players[multiplayer.get_unique_id()].player_type
	var new_type = 'player'
	if type == 'player':
		new_type = 'spectator'
	MultiplayerManager.update_player_type.rpc(multiplayer.get_unique_id(), new_type)
	await get_tree().create_timer(2).timeout
	swap_button.disabled = false


func _on_player_info_updated(net_id, player_info):
	reload_player_list()


func _on_games_list_item_selected(index: int) -> void:
	var game_data = GameData.games[index]
	set_selected_game_data(game_data)
