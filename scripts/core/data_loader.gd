extends Node
# Loads and caches data Resources from res://data/** by path.
# Nothing outside this autoload should call load()/preload() on a file
# under res://data/ directly (see ARCHITECTURE.md Section 3).

var _cache: Dictionary = {}

func load_resource(path: String) -> Resource:
	if _cache.has(path):
		return _cache[path]
	if not ResourceLoader.exists(path):
		push_warning("DataLoader: resource not found: %s" % path)
		return null
	var res := load(path)
	_cache[path] = res
	return res

func load_all_in_dir(dir_path: String) -> Array[Resource]:
	var results: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("DataLoader: directory not found: %s" % dir_path)
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		# Exported builds convert .tres resources to binary and leave a
		# ".tres.remap" pointer file at the original path instead — a
		# raw DirAccess listing sees that remap file, not the original
		# ".tres" name, so this bug is invisible in the editor and in
		# headless runs against the uncompiled project (both read the
		# real .tres files directly) and only surfaces in an exported
		# build. Strip a trailing ".remap" before checking the
		# extension, then load via the original (un-remapped) path —
		# load()/ResourceLoader.load() already follows the remap
		# transparently when given that canonical path.
		var resource_name := file_name
		if resource_name.ends_with(".remap"):
			resource_name = resource_name.substr(0, resource_name.length() - len(".remap"))
		if resource_name.ends_with(".tres"):
			var res := load_resource(dir_path.path_join(resource_name))
			if res != null:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results

func clear_cache() -> void:
	_cache.clear()
