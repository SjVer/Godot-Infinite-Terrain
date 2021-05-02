tool
extends Spatial

export(bool) var auto_update = false #setget au_set, au_get
export(bool) var force_update = false setget fu_set, fu_get
export(bool) var clear_chunks = false setget complete_clean

#export(float) var render_dist = 1.0
export(NodePath) var player_node_path
var player_node: Node
export(OpenSimplexNoise) var noise_map = OpenSimplexNoise.new()

export(int) var chunk_size = 64 setget size_set, size_get
export(int) var max_chunks = 16
export(float) var height_multiplier = 80 setget mult_set, mult_get
export(float) var height_offset = 0 setget ho_set, ho_get
export(int, 1, 1000) var LOD_percent = 100 setget lod_set, lod_get

export(bool) var add_water_planes = true
export(bool) var add_shaders = false
export(bool) var Displacement_by_shader = false setget dbs_set, dbs_get

var chunk_material = load("res://materials/terrainshader.tres")

func fu_get():
	return force_update
func fu_set(new):
	force_update = new
	
func size_get():
	return chunk_size
func size_set(new):
	chunk_size = new
	
func mult_get():
	return height_multiplier
func mult_set(new):
	height_multiplier = new
	
func ho_get():
	return height_offset
func ho_set(new):
	height_offset = new
	
func lod_get():
	return LOD_percent
func lod_set(new):
	LOD_percent = new
	
func dbs_get():
	return Displacement_by_shader
func dbs_set(new):
	Displacement_by_shader = new
	chunk_material.set_shader_param("do_noise", (true if new else false))

#var Chunk = load("res://Chunk.gd")

var p: Vector2

# CHUNK STUFF --------------------------

var chunks: Dictionary = {}
var unready_chunks: Dictionary = {}
var thread = Thread.new()

# --------------------------------------

func _process(delta):
	if force_update or auto_update:
		# get player node
		if player_node == null:
			player_node = get_node(player_node_path)
		
		update_chunks()
		clean_chunks()
		reset_chunks()
		
		force_update = false

	
func complete_clean(trash):
	for i in range(5):
		print("")
	# clear old chunks
	for child in get_children():
		remove_child(child)
		child.propagate_call("queue_free", [])
	for key in chunks:
		chunks.erase(key)
	for key in unready_chunks:
		unready_chunks.erase(key)
		thread = Thread.new()
	clear_chunks = false
	force_update = false
	auto_update = false
	print("cleared chunks!")
	print(" - children: ", get_child_count())
	print(" - chunks dict: ", chunks)
	print(" - unready chunks dict: ", unready_chunks)


func chunks_sort(a, b):
	return a.distance_to(p) < b.distance_to(p)

func chunks_sort_keys(a, b):
	var av = Vector2(int(a[0]), int(a[2]))
	var bv = Vector2(int(b[0]), int(b[2]))
	return av.distance_to(p) < bv.direction_to(p)
	

# CHUNK STUFF -----------------------

func add_chunk(x, z):
	var key = str(x) + "," + str(z)
	
	# check if chunk already exists or if it is in the unready_chunks (going to exist)
	if chunks.has(key) or unready_chunks.has(key):
		return
		
	# see if thread is not active at the moment (working on another chunk)
	if not thread.is_active():
		thread.start(self, "load_chunk", [thread, x, z])
		unready_chunks[key] = 1
		
func load_chunk(arr):
	
	var _thread = arr[0]
	var x = arr[1]
	var z = arr[2]

	# generate chunk
	var newchunk = Chunk.new(self, get_child_count()+1, x * chunk_size, z * chunk_size)
	newchunk.name = "Chunk "+str(x)+","+str(z)
	
	# set chunk position
	newchunk.translation = Vector3(x * chunk_size, 0, z * chunk_size)
	
	#newchunk._ready()
	call_deferred("load_done", newchunk, _thread)
	
func load_done(newchunk, _thread):
	add_child(newchunk)
	newchunk.set_owner(self)
	var key = str(newchunk.x / chunk_size) + "," + str(newchunk.z / chunk_size)
	chunks[key] = newchunk
	unready_chunks.erase(key)
	_thread.wait_to_finish()
	
func get_chunk(x, z):
	var key = str(x) + "," + str(z)
	if chunks.has(key):
		return chunks.get(key)
		
	return null
	
func update_chunks():
	var p_x = int(player_node.translation.x) / chunk_size
	var p_z = int(player_node.translation.z) / chunk_size
	
	# gather chunks
	var chunks_list = []
	for x in range(p_x - max_chunks * .5, p_x + max_chunks * .5):
		for z in range(p_z - max_chunks * .5, p_z + max_chunks * .5):
			chunks_list.append(Vector2(x,z))
	
	# sort chunks
	p.x = p_x
	p.y = p_z
	chunks_list.sort_custom(self, "chunks_sort")	
	
	# add chunks
	for item in chunks_list:		
		var x = item.x
		var z = item.y
		add_chunk(x, z)
		var newchunk = get_chunk(x, z)
		if newchunk != null:
			newchunk.should_be_removed = false

func clean_chunks():
	var chunks_list = []
	for key in chunks:
		chunks_list.append(key)
	chunks_list.sort_custom(self, "chunks_sort_key")
	
	for key in chunks_list:
		if chunks[key] == null:
			return
		var chunk = chunks[key]
		if chunk.should_be_removed:
			chunk.queue_free()
			chunks.erase(key)
	
func reset_chunks():
	for key in chunks:
		if chunks[key] == null:
			return
		chunks[key].should_be_removed = true
