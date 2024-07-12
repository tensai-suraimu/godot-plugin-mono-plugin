@tool
extends EditorPlugin

const MENU_NAME = "Export Plugins"
const REPO_NAME = ".mono_repo"

enum FileOperate {
	COPY_TO_TOP,
}

const DEF_SECTION_FILES := {
	# 扫描时忽略这些文件
	".git/": "IGNORE",
	".godot/": "IGNORE",
	"project.godot": "IGNORE",
	# 输出到 REPO 根目录
	"docs/": "FLATTEN",
	"LICENSE": "FLATTEN",
	"ReadMe.md": "FLATTEN"
}


func _enter_tree() -> void:
	add_tool_menu_item(MENU_NAME, _export_mono_plugins)


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

func _export_mono_plugins() -> void:
	var plugin_dirs := _plugin_dirs()
	for addon_name in plugin_dirs:
		_export(addon_name, "res://addons/%s/%s" % [addon_name, REPO_NAME])


func _export(addon_name: String, repo_path: String) -> void:
	# 无 .mono_repo/ 文件夹，忽略
	if not DirAccess.dir_exists_absolute(repo_path):
		return
	var config := ConfigFile.new()
	var config_path := "res://addons/%s/plugin.cfg" % addon_name
	if OK != config.load(config_path):
		return
	if true or not config.has_section(REPO_NAME):
		for name in DEF_SECTION_FILES.keys():
			var value := DEF_SECTION_FILES[name] as String
			config.set_value(REPO_NAME, name, value)
	config.save(config_path)
	# 整理输出目录
	_tidy_repo(config, "", repo_path, "")

	DirAccess.make_dir_recursive_absolute("%s/addons/%s" % [repo_path, addon_name])
	# 自动创建 .gitignore 并排除 .mono_repo/ 目录
	var gitignore := "res://addons/%s/%s" % [addon_name, ".gitignore"]
	if not FileAccess.file_exists(gitignore):
		var file := FileAccess.open(gitignore, FileAccess.WRITE)
		file.store_line("%s/" % REPO_NAME)
		file.close()
	# 拷贝插件目录
	_cptree(config, "", "res://addons/%s" % addon_name, "")


func _tidy_repo(config: ConfigFile, operate: String, root: String, path: String) -> void:
	var dir := DirAccess.open("%s/%s" % [root, path])
	if not dir:
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			var next := "%s%s/" % [path, name]
			var oper := config.get_value(REPO_NAME, next, operate)
			if oper != "IGNORE":
				_tidy_repo(config, oper, root, next)
		else:
			var next := "%s%s" % [path, name]
			var oper := config.get_value(REPO_NAME, next, operate)
			if oper != "IGNORE":
				var source := (
					"%s/../%s" % [root, next]
				) if oper == "FLATTEN" else (
					"res://%s" % next
				)
				var output := "%s/%s" % [root, next]
				_tidy_file(source, output)
		name = dir.get_next()
	dir.list_dir_end()

func _tidy_file(source: String, output: String) -> void:
	var src_mod_at := FileAccess.get_modified_time(source)
	var out_mod_at := FileAccess.get_modified_time(output)
	# 若源文件已删除，输出文件也一起删除
	if src_mod_at <= 0 or not FileAccess.file_exists(source):
		DirAccess.remove_absolute(output)
		return
	# 输出文件无效，正常情况下不应该出现
	if out_mod_at <= 0 or not FileAccess.file_exists(output):
		return
	# 输出文件较新（被修改了），覆盖回去
	if src_mod_at < out_mod_at:
		DirAccess.copy_absolute(output, source)

func _cptree(config: ConfigFile, operate: String, root: String, path: String) -> void:
	var dir := DirAccess.open("%s/%s" % [root, path])
	if not dir:
		return
	dir.include_hidden = true
	dir.list_dir_begin()
	var name := dir.get_next()
	while name != "":
		if dir.current_is_dir():
			if name == REPO_NAME:
				name = dir.get_next()
				continue
			var next := "%s%s/" % [path, name]
			var oper := config.get_value(REPO_NAME, next, operate)
			if oper != "IGNORE":
				_cptree(config, oper, root, next)
		else:
			var next := "%s%s" % [path, name]
			var oper := config.get_value(REPO_NAME, next, operate)
			if oper != "IGNORE":
				var source := "%s/%s" % [root, next]
				var output := (
					"%s/%s/%s" % [root, REPO_NAME, next]
				) if oper == "FLATTEN" else (
					"%s/%s/%s/%s" % [root, REPO_NAME, root.substr(6), next]
				)
				var out_dir := output.substr(0, output.rfind("/"))
				DirAccess.make_dir_recursive_absolute(out_dir)
				DirAccess.copy_absolute(source, output)
		name = dir.get_next()
	dir.list_dir_end()
