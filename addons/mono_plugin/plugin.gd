@tool
extends EditorPlugin

const MENU_NAME = "Export Plugins"
const DOCS_NAME = "docs"
const REPO_NAME = ".mono_repo"
var plugin


func _enter_tree():
	add_tool_menu_item(MENU_NAME, _export_mono_plugins)


func _exit_tree():
	_remove_exported_files()
	remove_tool_menu_item(MENU_NAME)


func _plugin_dirs() -> Array[String]:
	var addons := DirAccess.open("res://addons")
	if not addons:
		return []
	var dirs: Array[String] = []
	addons.list_dir_begin()
	var name := addons.get_next()
	while name != "":
		if addons.current_is_dir():
			dirs.append(name)
		name = addons.get_next()
	addons.list_dir_end()
	return dirs

func _export_mono_plugins():
	var plugin_dirs := _plugin_dirs()
	for dir_name in plugin_dirs:
		_export(dir_name, "res://addons/%s/%s" % [dir_name, REPO_NAME])

func _remove_exported_files():
	var plugin_dirs := _plugin_dirs()
	for dir_name in plugin_dirs:
		_rmtree("res://addons/%s/%s" % [dir_name, REPO_NAME])



func _export(dir_name: String, repo_path: String) -> void:
	# 整理输出目录
	if not _rmtree(repo_path):
		return
	DirAccess.make_dir_recursive_absolute("%s/addons/%s" % [repo_path, dir_name])
	# 自动创建 .gitignore 并排除 .mono_repo/ 目录
	var gitignore := "res://addons/%s/%s" % [dir_name, ".gitignore"]
	if not FileAccess.file_exists(gitignore):
		var file := FileAccess.open(gitignore, FileAccess.WRITE)
		file.store_line("%s/" % REPO_NAME)
		file.close()

	# 将插件目录下内容整理并拷贝到输出目录
	var from_dir := DirAccess.open("res://addons/%s" % dir_name)
	from_dir.include_hidden = true
	from_dir.list_dir_begin()
	var name := from_dir.get_next()
	while name != "":
		var from := "res://addons/%s/%s" % [dir_name, name]
		var dest := "%s/addons/%s/%s" % [repo_path, dir_name, name]
		if from_dir.current_is_dir():
			if name == DOCS_NAME:
				_cptree(from, "%s/%s" % [repo_path, name])
			if name != REPO_NAME:
				_cptree(from, dest)
		elif name.ends_with(".md"):
			# 顶层的 Markdown 文件特殊处理，放到仓库根目录
			DirAccess.copy_absolute(from, "%s/%s" % [repo_path, name])
		else:
			DirAccess.copy_absolute(from, dest)
		name = from_dir.get_next()
	from_dir.list_dir_end()


func _rmtree(path: String) -> bool:
	var dir := DirAccess.open(path)
	if not dir:
		return false
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			if name != '.git':
				_rmtree("%s/%s" % [path, name])
		dir.remove(name)
		name = dir.get_next()
	dir.list_dir_end()
	return true


func _cptree(from_dir: String, dest_dir: String) -> bool:
	var dir := DirAccess.open(from_dir)
	if not dir:
		return false
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		var from := "%s/%s" % [from_dir, name]
		var dest := "%s/%s" % [dest_dir, name]
		if dir.current_is_dir():
			_cptree(from, dest)
		else:
			DirAccess.make_dir_recursive_absolute(dest_dir)
			DirAccess.copy_absolute(from, dest)
		name = dir.get_next()
	dir.list_dir_end()
	return true
