class_name TicTacToe extends Control

@onready var p1_name_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayerOne/HBoxName/NameLabelValue
@onready var p1_turn_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayerOne/HBoxTurn/TurnLabelValue
@onready var p1_win_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayerOne/HBoxWins/WinLabelValue

@onready var p2_name_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayerTwo/HBoxName/NameLabelValue
@onready var p2_turn_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayerTwo/HBoxTurn/TurnLabelValue
@onready var p2_win_label = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/VBoxPlayerTwo/HBoxWins/WinLabelValue

@onready var tiles = $MarginContainer/PanelContainer/MarginContainer/VBoxContainer/HBoxContainer/GridContainer

var players_ready = 0

var p1
var p2

# true -> player 1 turn, false -> player 2 turn
var turn = true
var p1_wins = 0
var p2_wins = 0
var player_won = false

var board

func _ready() -> void:
	reset_board()
	if not multiplayer.is_server():
		player_ready.rpc()


@rpc("call_local", "reliable")
func set_players(_p1, _p2):
	print('set_players ' + str(multiplayer.get_unique_id()) + ': p1: ' + str(_p1) + ' p2: ' + str(_p2))
	p1 = _p1
	p2 = _p2
	update_ui()

@rpc("any_peer", "call_local", "reliable")
func player_ready():
	players_ready += 1
	if players_ready >= MultiplayerManager.players.size() - 1 and multiplayer.is_server():
		var players = MultiplayerManager.get_active_players()
		set_players.rpc(players[0], players[1])
		Chat.network_message.rpc(1, 'Tic tac toe started: ' + str(p1.name) + ' vs ' + str(p2.name), true)


func update_ui():
	p1_name_label.text = p1.name
	p2_name_label.text = p2.name
	if turn:
		p1_turn_label.text = "yes"
		p2_turn_label.text = "no"
	else:
		p1_turn_label.text = "no"
		p2_turn_label.text = "yes"
	p1_win_label.text = str(p1_wins)
	p2_win_label.text = str(p2_wins)


func clicked(col, row):
	server_handle_click.rpc(col, row)

@rpc("any_peer", "reliable", "call_local")
func server_handle_click(col, row):
	if not multiplayer.is_server() or player_won:
		return
	
	var caller_id = multiplayer.get_remote_sender_id()
	if caller_id == p1.net_id and turn and board[col][row] == null:
		handle_turn.rpc(true, col, row)
	elif caller_id == p2.net_id and not turn  and board[col][row] == null:
		handle_turn.rpc(false, col, row)

@rpc("reliable", "call_local")
func handle_turn(is_player_1, col, row):
	turn = !turn
	update_ui()
	
	var tile = tiles.get_child(row * 3 + col)
	
	if is_player_1:
		tile.set_texture("x")
		board[col][row] = "x"
	else:
		tile.set_texture("o")
		board[col][row] = "o"
	
	if multiplayer.is_server():
		var p1_win = check_win("x")
		var p2_win = check_win("o")
		if p1_win:
			Chat.network_message.rpc(1, p1.name + ' won!', true)
			handle_win.rpc(true)
		elif p2_win:
			Chat.network_message.rpc(1, p2.name + ' won!', true)
			handle_win.rpc(false)
		else:
			check_full_board()
		

@rpc("call_local", "reliable")
func handle_win(p1_win):
	player_won = true
	if p1_win:
		p1_wins += 1
	else:
		p2_wins += 1
	update_ui()
	await get_tree().create_timer(2).timeout
	reset_board()


@rpc("call_local", "reliable")
func handle_tie():
	player_won = true
	await get_tree().create_timer(2).timeout
	reset_board()

func check_full_board():
	for x in range(3):
		for y in range(3):
			if (board[x][y] == null):
				return
	
	Chat.network_message.rpc(1, 'It was a tie, restarting', true)
	handle_tie.rpc()


func check_win(val):
	if (board[0][0] == val and board[0][1] == val and board[0][2] == val):
		return true
	if (board[1][0] == val and board[1][1] == val and board[1][2] == val):
		return true
	if (board[2][0] == val and board[2][1] == val and board[2][2] == val):
		return true
	if (board[0][0] == val and board[1][0] == val and board[2][0] == val):
		return true
	if (board[0][1] == val and board[1][1] == val and board[2][1] == val):
		return true
	if (board[0][2] == val and board[1][2] == val and board[2][2] == val):
		return true
	if (board[0][0] == val and board[1][1] == val and board[2][2] == val):
		return true
	if (board[0][2] == val and board[1][1] == val and board[2][0] == val):
		return true
	return false


func reset_board():
	board = [
	[null, null, null],
	[null, null, null],
	[null, null, null]
	]
	
	for tile in tiles.get_children():
		tile.set_texture(null)
	player_won = false


func _on_quit_game_button_pressed() -> void:
	MultiplayerManager.return_to_lobby()
