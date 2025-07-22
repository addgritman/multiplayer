extends Node

signal player_connected(peer_id, player_info)
signal player_info_updated(peer_id, player_info)
signal player_disconnected(peer_id)
signal server_disconnected
signal server_hosted(player_info)
signal server_joined(peer_id, player_info)

var players = {}
var players_loaded = 0
var player_info = {}

func _ready():
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)


func host_game(player_name, port, max_connections = 20):
	print('Hosting for player ' + player_name + ' on port ' + str(port))
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_connections)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	player_info = { "name": player_name, "net_id": 1, "is_host": true, "player_type": "spectator" }
	players[1] = player_info
	SceneManager.load_multiplayer_lobby()
	server_hosted.emit(player_info)
	player_connected.emit(1, player_info)


func join_game(player_name, ip, port):
	if ip == "":
		ip = "192.168.0.15"
	print('Joining for player ' + player_name + 'on ip ' + str(ip) + ' on port ' + str(port))
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, port)
	if error:
		return error
	multiplayer.multiplayer_peer = peer
	player_info = { "name": player_name, "net_id": multiplayer.get_unique_id(), "is_host": false, "player_type": "spectator" }
	SceneManager.load_multiplayer_lobby()
	server_joined.emit(multiplayer.get_unique_id(), player_info)


func remove_multiplayer_peer():
	multiplayer.multiplayer_peer = null
	players.clear()


func load_game(slug):
	load_game_everyone.rpc(slug)

@rpc("call_local", "reliable")
func load_game_everyone(slug):
	SceneManager.load_game(slug)


func return_to_lobby():
	Chat.network_message.rpc(1, 'Returning to lobby. Player ' + player_info.name + ' quit', true)
	return_to_lobby_everyone.rpc()

@rpc("call_local", "any_peer", "reliable")
func return_to_lobby_everyone():
	SceneManager.load_multiplayer_lobby()


# When a peer connects, send them my player info.
# This allows transfer of all desired data for each player, not only the unique ID.
@rpc("any_peer", "reliable")
func _register_player(new_player_info):
	print('Registering player: ' + str(new_player_info))
	players[new_player_info.net_id] = new_player_info
	player_connected.emit(new_player_info.net_id, new_player_info)


func get_player_info_by_id(id):
	if players.has(id):
		return players[id]
	else:
		return {
			"name": "Unknown",
			"player_type": "spectator"
		}


func get_active_players():
	var active_players = []
	for id in players:
		if players[id].player_type == 'player':
			active_players.append(players[id])
	return active_players


@rpc("any_peer", "reliable", "call_local")
func update_player_type(net_id, type):
	var player_info = players[net_id]
	player_info.player_type = type
	players[net_id] = player_info
	print(str(net_id) + ': player_info update: ' + str(player_info))
	player_info_updated.emit(net_id, player_info)


func _on_player_connected(id):
	print('Player connected: ' + str(id))
	_register_player.rpc_id(id, player_info)


func _on_player_disconnected(id):
	print('Player disconnected: ' + str(id))
	var player_info = get_player_info_by_id(id)
	players.erase(id)
	player_disconnected.emit(id, player_info)


func _on_connected_ok():
	print('Connection succeeded')
	var peer_id = multiplayer.get_unique_id()
	players[peer_id] = player_info
	player_connected.emit(peer_id, player_info)


func _on_connected_fail():
	print('Connection failed')
	multiplayer.multiplayer_peer = null
	SceneManager.load_main_menu()


func _on_server_disconnected():
	print('Server disconnected')
	multiplayer.multiplayer_peer = null
	players.clear()
	server_disconnected.emit()
	SceneManager.load_main_menu()
