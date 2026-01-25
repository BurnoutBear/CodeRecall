@tool
class_name CodeRecallUI
extends Control

@onready var button_dir : Button = $VBoxContainer/HBoxContainer/ButtonDir
@onready var searchbar : LineEdit = $VBoxContainer/HBoxContainer/Searchbar
@onready var button_dir_2 : Button = $VBoxContainer/HBoxContainer/ButtonDir2
@onready var button_coll : Button = $VBoxContainer/HBoxContainer/ButtonColl
@onready var folder_path : FileDialog = $VBoxContainer/FolderPath
@onready var scroll_container : ScrollContainer = $VBoxContainer/ScrollContainer
@onready var code_container : VBoxContainer = $VBoxContainer/ScrollContainer/VBoxContainer

signal search(text : String)
signal directory(text : String)
signal collapse()

func _ready():
	button_dir.pressed.connect(on_dir_pressed)
	
	searchbar.right_icon = get_theme_icon("Search", "EditorIcons")
	searchbar.text_changed.connect(check_text)
	searchbar.text_submitted.connect(emit_search)
	
	button_dir_2.icon = get_theme_icon("Folder", "EditorIcons")
	button_dir_2.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_dir_2.pressed.connect(on_dir_pressed)
	
	button_coll.icon = get_theme_icon("CodeFoldedRightArrow", "EditorIcons")
	button_coll.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button_coll.pressed.connect(emit_collapse)
	
	folder_path.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	folder_path.access = FileDialog.ACCESS_FILESYSTEM
	folder_path.title = "Select your projects folder"
	folder_path.ok_button_text = "Confirm"
	folder_path.dir_selected.connect(on_directory_selected)

func on_dir_pressed():
	folder_path.popup_centered(Vector2i(800, 600))

func on_directory_selected(dir_path: String):
	directory.emit(dir_path)
	searchbar.visible = true
	button_dir.visible = false
	button_dir_2.visible = true
	button_coll.visible = true
	scroll_container.visible = true

func check_text(text : String):
	if text == "":
		emit_search("")

func emit_search(text : String):
	search.emit(text)

func emit_collapse():
	collapse.emit()
