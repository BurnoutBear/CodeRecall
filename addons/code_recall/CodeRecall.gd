@tool
class_name CodeRecall
extends EditorPlugin

var cfg : ConfigFile
var plugin_name : String
var ui_scene : PackedScene = preload("res://addons/code_recall/ui_scene.tscn")
var ui : CodeRecallUI

var folder_path : String
var timer : Timer
var flag : bool
const height : float = 25.0
const offset : float = 25.0

func _enable_plugin():
	## UI Setup
	cfg = ConfigFile.new()
	cfg.load("res://addons/code_recall/plugin.cfg")
	plugin_name = cfg.get_value("plugin", "name")
	ui = ui_scene.instantiate()
	ui.name = plugin_name
	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_UL, ui)
	
	ui.directory.connect(get_projects)
	ui.search.connect(search_code)
	ui.collapse.connect(collapse_all.bind(ui.code_container))
	
	timer = Timer.new()
	self.add_child(timer)
	flag = false

func _disable_plugin():
	if ui:
		remove_control_from_docks(ui)
		ui.queue_free()

func dir_change(path : String):
	remove_all(ui.code_container)
	get_projects(path)

func get_projects(path: String):
	var dir = DirAccess.open(path)
	var i : int = 0
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					## CREATE PROJECT FOLDABLE
					var fc : FoldableContainer = FoldableContainer.new()
					ui.code_container.add_child(fc)
					fc.title = "[ P ] " + file_name
					var vb : VBoxContainer = VBoxContainer.new()
					fc.add_child(vb)
					vb.SIZE_EXPAND_FILL
					get_scripts(full_path, vb)
					if vb.get_child_count() < 1:
						fc.queue_free()
			file_name = dir.get_next()
		dir.list_dir_end()

func get_scripts(path: String, parent : Control):
	var dir = DirAccess.open(path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			var full_path = path.path_join(file_name)
			if dir.current_is_dir():
				if file_name != "." and file_name != "..":
					get_scripts(full_path, parent)
			elif file_name.ends_with(".gd"):
				## CREATE SCRIPT FOLDABLE
				var fc : FoldableContainer = FoldableContainer.new()
				parent.add_child(fc)
				fc.title = "[ S ] " + file_name
				var vb : VBoxContainer = VBoxContainer.new()
				fc.add_child(vb)
				vb.SIZE_EXPAND_FILL
				# fc.fold()
				get_code(full_path, vb)
				if vb.get_child_count() < 1:
					fc.queue_free()
			file_name = dir.get_next()
		dir.list_dir_end()

func get_code(file_path: String, parent : Control):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Error while opening file: ", file_path)
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Split into lines
	var lines = content.split("\n")
	
	var fc : FoldableContainer = null
	for line in lines:
		var trimmed : String = line.strip_edges()
		if trimmed.begins_with("func "):
			# Extract func name
			var func_declaration = trimmed.substr(5)  # Remove "func "
			var paren_pos = func_declaration.find("(")
			if paren_pos != -1:
				var func_name = func_declaration.substr(0, paren_pos).strip_edges()
				## CREATE FUNC FOLDABLE
				fc = FoldableContainer.new()
				parent.add_child(fc)
				fc.title = func_name
				var vb : VBoxContainer = VBoxContainer.new()
				fc.add_child(vb)
				vb.SIZE_EXPAND_FILL
				## CREATE CODE AREA
				var tf : TextEdit = TextEdit.new()
				vb.add_child(tf)
				tf.text = trimmed
				flag = true
				tf.editable = false
				tf.gui_input.connect(copy_text.bind(tf))
		elif flag:
			if line.begins_with("\t"):
				fc.get_child(0).get_child(0).text += "\n" + line
			else:
				fc.get_child(0).get_child(0).custom_minimum_size.y = offset + height * fc.get_child(0).get_child(0).text.get_slice_count("\n")
				flag = false
				#fc.fold()

func copy_text(event : InputEvent, tf : TextEdit):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				if tf.text[0] == "f":
					flag = true
					timer.start(0.2)
					await timer.timeout
					flag = false
			else:
				if flag and tf.text[0] == "f":
					if timer.time_left > 0.0:
						timer.stop()
						timer.timeout.emit()
					DisplayServer.clipboard_set(tf.text)
					print("Copied to clipboard!")
					var tmp : String = tf.text
					tf.text = tf.text.to_upper()
					await get_tree().create_timer(0.2).timeout
					tf.text = tmp

func search_code(node : Control):
	var r : RandomNumberGenerator = RandomNumberGenerator.new()
	for child in node.get_children():
		var f = r.randf()
		if f < 0.5:
			child.visible = false

func clear_search(node : Control):
	for child in node.get_children():
		child.visible = true
		clear_search(child)

func remove_empty(node : Control):
	for child in node.get_children():
		if child is FoldableContainer:
			if child.title.ends_with(".gd"):
				if child.get_child(0).get_child_count() < 2:
					child.queue_free()
				elif child.get_child(0).get_child(1).text.contains("\tpass\n"):
					child.queue_free()
		remove_empty(child)

func hide_empty(node : Control):
	for child in node.get_children():
		child.visible = true
		hide_empty(child)

func remove_all(node : Control):
	for child in node.get_children():
		remove_all(child)
		child.queue_free()

func collapse_all(node : Control):
	for child in node.get_children():
		collapse_all(child)
		if child is FoldableContainer:
			child.fold()
