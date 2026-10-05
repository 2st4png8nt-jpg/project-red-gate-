extends Node
# DataLoader — Autoload. Loads and caches data Resources from
# res://data/** by path. Nothing outside this autoload should call
# load()/preload() on a file under res://data/ directly.

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

## Enumerates every .tres resource in a data folder. Exported builds
## convert .tres resources to binary and leave a "<name>.tres.remap"
## pointer file at the original path instead — a raw DirAccess listing
## sees that literal name, not the original extension, so this strips
## a trailing ".remap" before checking for ".tres" and always loads via
## the original (un-remapped) path, which load() resolves correctly in
## both the editor and an exported build.
func load_all_in_dir(dir_path: String) -> Array[Resource]:
	var results: Array[Resource] = []
	var dir := DirAccess.open(dir_path)
	if dir == null:
		push_warning("DataLoader: directory not found: %s" % dir_path)
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
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
