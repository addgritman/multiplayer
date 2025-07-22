extends Control

@export var col = 0
@export var row = 0
@export var board: TicTacToe
@export var x_texture: Texture
@export var o_texture: Texture

@onready var tile_texture = $TileTexture

func _ready() -> void:
	self_modulate = Color(1, 1, 1, 0)


func set_texture(val):
	if val == "x":
		tile_texture.texture = x_texture
	elif val == "o":
		tile_texture.texture = o_texture
	else:
		tile_texture.texture = null


func _on_pressed() -> void:
	board.clicked(col, row)
