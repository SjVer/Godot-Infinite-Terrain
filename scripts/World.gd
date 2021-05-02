extends Spatial

var old_vars = []

func _ready():
	old_vars = [
		$Terrain.auto_update,
		$Terrain.add_water_planes,
		$Terrain.add_shaders
	]
	$Terrain.auto_update = true
	$Terrain.add_water_planes = true
	$Terrain.add_shaders = true
	
func _exit_tree():
	$Terrain.auto_update = old_vars[0]
	$Terrain.add_water_planes = old_vars[1]
	$Terrain.add_shaders = old_vars[2]
