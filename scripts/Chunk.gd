extends MeshInstance
class_name Chunk

var parent

var noise_map
var x
var z
var size

var should_be_removed: bool = false

func _init(_parent, id: int, _x, _z):
	self.parent = _parent
	
	self.noise_map = parent.noise_map
	self.x = _x
	self.z = _z
	self.size = parent.chunk_size
	
	name = "Chunk #{n}".format({"n": id})
	
	#print("new chunk generated! ID: ",id,", x: ",self.x," z: ",self.z)
	
func _ready():
	generate_mesh()
	if parent.add_shaders:
		set_surface_material(0, parent.chunk_material)#preload("res://materials/terrainshader.tres"))
	if parent.add_water_planes:
		generate_water()

func generate_mesh():
	# get tools
	var mdt = MeshDataTool.new()
	var st = SurfaceTool.new()

	self.mesh = PlaneMesh.new()
	self.mesh.size = Vector2(size, size)
	self.mesh.subdivide_width = size * parent.LOD_percent / 100
	self.mesh.subdivide_depth = size * parent.LOD_percent / 100
	
	if parent.Displacement_by_shader:
		return
	# get verteces
	st.create_from(self.mesh, 0)
	var vert_array = st.commit()
	var vers = mdt.create_from_surface(vert_array, 0)
	
	# iterate through verteces
	for i in range(mdt.get_vertex_count()):
		var vtx = mdt.get_vertex(i)
		# sample from noise and add to vertex height
		vtx.y += noise_map.get_noise_2d(vtx.x + transform.origin.x, vtx.z + transform.origin.z) * parent.height_multiplier + parent.height_offset
		mdt.set_vertex(i, vtx)
		
	# clean up and save mesh and stuff
	for s in range(vert_array.get_surface_count()):
		vert_array.surface_remove(s)
	mdt.commit_to_surface(vert_array)
	st.create_from(vert_array, 0)
	st.generate_normals()
	self.mesh = st.commit()

func generate_water():
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(size, size)
	
	# you may need to change to water.tres if that is your material extension
	plane_mesh.material = preload("res://materials/water.tres")
	
	var mesh_instance = MeshInstance.new()
	mesh_instance.mesh = plane_mesh
	
	add_child(mesh_instance)
