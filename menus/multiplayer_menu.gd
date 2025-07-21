extends Control

@onready var player_name_line_edit = $PanelContainer/MarginContainer/VBoxContainer/PlayerName
@onready var host_port_line_edit = $PanelContainer/MarginContainer/VBoxContainer/HostContainer/LineEdit
@onready var join_port_line_edit = $PanelContainer/MarginContainer/VBoxContainer/JoinContainer/PortLineEdit
@onready var join_ip_line_edit = $PanelContainer/MarginContainer/VBoxContainer/JoinContainer/IpLineEdit


func _on_host_button_pressed() -> void:
	var player_name = player_name_line_edit.text
	var port = int(host_port_line_edit.text)
	MultiplayerManager.host_game(player_name, port)


func _on_join_button_pressed() -> void:
	var player_name = player_name_line_edit.text
	var ip = join_ip_line_edit.text
	var port = int(host_port_line_edit.text)
	MultiplayerManager.join_game(player_name, ip, port)


func _on_main_menu_button_pressed() -> void:
	SceneManager.load_main_menu()


func get_local_ip():
	if OS.has_feature("windows"):
		if OS.has_environment("COMPUTERNAME"):
			return IP.resolve_hostname(str(OS.get_environment("COMPUTERNAME")),1)
	elif OS.has_feature("x11"):
		if OS.has_environment("HOSTNAME"):
			return IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
	elif OS.has_feature("OSX"):
		if OS.has_environment("HOSTNAME"):
			return  IP.resolve_hostname(str(OS.get_environment("HOSTNAME")),1)
