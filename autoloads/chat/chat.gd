extends Control

var messages = []

@onready var chat_panel = $CanvasLayer/MarginContainer
@onready var text_box = $CanvasLayer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TextBox
@onready var text_input = $CanvasLayer/MarginContainer/PanelContainer/MarginContainer/VBoxContainer/TextInput

func _ready() -> void:
	MultiplayerManager.server_hosted.connect(_on_server_hosted)
	MultiplayerManager.server_joined.connect(_on_server_joined)
	MultiplayerManager.player_connected.connect(_on_player_connected)
	MultiplayerManager.player_disconnected.connect(_on_player_disconnected)
	text_box.clear()

func send_message(message):
	var net_id = multiplayer.get_unique_id()
	network_message.rpc(net_id, message)


@rpc("reliable", "any_peer", "call_local")
func network_message(net_id, message, server_message = false):
	insert_message(net_id, message, server_message)


func format_message(net_id, message, server_message = false):
	var user = MultiplayerManager.get_player_info_by_id(net_id)
	if (server_message):
		return '[SERVER] ' + message
	return user.name + ": " + message


func insert_message(net_id, message, server_message):
	var formatted_message = format_message(net_id, message, server_message)
	messages.append(formatted_message)
	text_box.add_item(formatted_message)
	call_deferred("scroll_text_box_to_bottom")


func reload_messages():
	print('reload')
	text_box.clear()
	for message in messages:
		text_box.add_item(message)


@rpc("reliable", "any_peer")
func get_message_history_from_server():
	print('message received ' + str(multiplayer.get_unique_id()))
	if not multiplayer.is_server():
		return
	print('Server received message for: ' + str(multiplayer.get_remote_sender_id()) + ' messages: ' + str(messages))
	send_message_history_from_server.rpc_id(multiplayer.get_remote_sender_id(), messages)


@rpc("reliable")
func send_message_history_from_server(_messages):
	print('Received messages from ' + str(multiplayer.get_remote_sender_id()) + ' i am ' + str(multiplayer.get_unique_id()) + ' messages: ' + str(_messages))
	messages = _messages
	reload_messages()


func set_visibility(val):
	chat_panel.visible = val


func scroll_text_box_to_bottom():
	text_box.get_v_scroll_bar().value = text_box.get_v_scroll_bar().max_value


func reset_chat():
	print('reset')
	messages = []
	reload_messages()
	set_visibility(false)


func _on_player_connected(net_id, player_info):
	if multiplayer.is_server():
		network_message.rpc(1, player_info.name + ' joined the lobby', true)
	print('chat player connected' + str(net_id))
	if (net_id == multiplayer.get_unique_id() and not multiplayer.is_server()):
		print('requesting message history ' + str(multiplayer.get_unique_id()))
		get_message_history_from_server.rpc_id(1)


func _on_player_disconnected(net_id, player_info):
	if multiplayer.is_server():
		network_message.rpc(1, player_info.name + ' left the lobby', true)


func _on_text_input_text_submitted(new_text: String) -> void:
	send_message(new_text)
	text_input.clear()
	text_input.release_focus()
	text_input.call_deferred("grab_focus")


func _on_server_hosted(player_info):
	set_visibility(true)


func _on_server_joined(net_id, player_info):
	set_visibility(true)
