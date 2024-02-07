extends Camera2D

@export var tile_map: TileMap

func _ready():
	var visibleArea = tile_map.get_used_rect()
	var tileSize = tile_map.cell_quadrant_size
	var upperLeftCorner = visibleArea.position * tileSize
	var lowerRightCorner = (visibleArea.position + visibleArea.size) * tileSize
	
	limit_left = visibleArea.position.x + upperLeftCorner.x;
	limit_top = visibleArea.position.y + upperLeftCorner.y;
	limit_right = visibleArea.position.x + lowerRightCorner.x;
	limit_bottom = visibleArea.position.y + lowerRightCorner.y;
