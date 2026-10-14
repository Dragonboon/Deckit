class_name DeckitUtils


static func collision_layer_to_value(layer: int) -> int:
	if layer < 1 or layer > 32:
		push_error("DeckitUtils.layer_to_value: The specified collision layer (%d) is invalid. Please ensure the layer value is between 1 and 32" % layer)
	
	return pow(2, clampi(layer, 1, 32) - 1)
	
	
@warning_ignore("narrowing_conversion")
static func collision_value_to_layer(value: int) -> int:
	if value == 1:
		return value
		
	## This bitwise operation check if the value is a valid base 2
	if value > 0 and (value & (value - 1)) == 0:
		return (log(value) / log(2)) + 1
	
	push_error("DeckitUtils.value_to_layer: The specified value %d) is invalid. Please ensure the value is a power of 2" % value)
	
	return 0
	
	
static func center_pivot(texture_rect: TextureRect) -> void:
	if texture_rect.texture:
		texture_rect.pivot_offset = (texture_rect.texture.get_size() / 2).ceil()


static func set_owner_to_edited_scene_root(node: Node) -> void:
	if Engine.is_editor_hint() and node.get_tree():
		node.owner = node.get_tree().edited_scene_root


static func remove_child_nodes(node: Node) -> void:
	for child in node.get_children():
		child.free()


## Supports RegEx expressions
static func get_files_recursive(path: String, regex: RegEx = null) -> Array:
	if path.is_empty() or not DirAccess.dir_exists_absolute(path):
		push_error("DeckitUtils.get_files_recursive: directory not found '%s'" % path)

		return []

	var files = []
	var directory = DirAccess.open(path)
	
	if directory:
		directory.list_dir_begin()
		var file := directory.get_next()
		
		while file != "":
			if directory.current_is_dir():
				files += get_files_recursive(directory.get_current_dir().path_join(file), regex)
			else:
				var file_path = directory.get_current_dir().path_join(file)
				
				if regex != null:
					if regex.search(file_path):
						files.append(file_path)
				else:
					files.append(file_path)
					
			file = directory.get_next()
			
		directory.list_dir_end()
		files.sort()
		return files
	else:
		push_error("DeckitUtils.get_files_recursive: An error %s occurred when trying to open directory: %s" % [DirAccess.get_open_error(), path])
		
		return []


static func get_resource_files(path: String) -> Array[Resource]:
	var regex = RegEx.new()
	regex.compile(".tres$")
	
	var resources: Array[Resource] = []
	resources.assign(get_files_recursive(path, regex)\
		.map(func(filepath: String): return ResourceLoader.load(filepath)))

	return resources
	

static func dirpath_is_valid(path: String) -> bool:
	return not path.is_empty() and path.is_absolute_path() and DirAccess.dir_exists_absolute(path)


## Compatibility alias; prefer center_pivot() for new code.
static func center_texture_rect_pivot(texture_rect: TextureRect) -> TextureRect:
	center_pivot(texture_rect)
	return texture_rect


static func repeat(element: Variant, times: int) -> Array[Variant]:
	var result: Array[Variant] = []
	
	for _time: int in times:
		if element is Dictionary or element is Array:
			result.append(element.duplicate(true))
		elif element is Resource:
			result.append(element.duplicate())
		else:
			result.append(element)
		
	return result
