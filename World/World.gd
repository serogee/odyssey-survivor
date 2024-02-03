extends Node2D

const LightTexture = preload("res://World/Light.png")
const GRID_SIZE = 16

@onready var fog = $Fog

var display_width = ProjectSettings.get_setting("display/window/size/viewport_width")
var display_height = ProjectSettings.get_setting("display/window/size/viewport_height")

var fogImage = Image.new()
var fogTexture = ImageTexture.new()
var lightImage = LightTexture.get_image()
var light_offset = Vector2(LightTexture.get_width()/2, LightTexture.get_height()/2)

func _ready():
	var fog_image_width = display_width/GRID_SIZE
	var fog_image_height = display_height/GRID_SIZE
	fogImage.create(fog_image_width, fog_image_height, false, Image.FORMAT_RGBA8)
	fogImage.fill(Color.BLACK)
	lightImage.convert(Image.FORMAT_RGBA8)
	fog.scale *= GRID_SIZE

func update_fog(new_grid_position):
	if fogImage.get_size() != Vector2i.ZERO and lightImage.get_size() != Vector2i.ZERO and new_grid_position.x >= 0 and new_grid_position.y >= 0:
		var light_rect = Rect2(Vector2.ZERO, Vector2(lightImage.get_width(), lightImage.get_height()))
		fogImage.blend_rect(lightImage, light_rect, new_grid_position - light_offset)
		update_fog_image_texture()

func update_fog_image_texture():
	if fogImage.get_size() != Vector2i.ZERO:
		fogTexture.create_from_image(fogImage)
		fog.texture = fogTexture
func _input(event):
	if event is InputEventMouseMotion:
		update_fog(event.position/GRID_SIZE)
