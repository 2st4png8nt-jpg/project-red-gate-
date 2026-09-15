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
		if file_name.ends_with(".tres"):
			var res := load_resource(dir_path.path_join(file_name))
			if res != null:
				results.append(res)
		file_name = dir.get_next()
	dir.list_dir_end()
	return results

func clear_cache() -> void:
	_cache.clear()
