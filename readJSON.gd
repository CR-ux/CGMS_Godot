extends Node

const JSON_PATH := "res://hex_tree_structure.json"

var hex_tree_root: Dictionary
var current_node: Dictionary

#HTTPs Node:
@onready var vault_loader := $"MarkdownLoader"
var requesting_from: String = ""

#Content Display for Room Changes
@onready var content_display = $"/root/HexRoom/Control/ContentDisplay"

@onready var lhp = $"/root/HexRoom/HBoxContainer/lhp"
@onready var rhp = $"/root/HexRoom/HBoxContainer/rhp"

func _ready():
	load_hex_tree()
	lhp.pressed.connect(_on_lhp_pressed)
	rhp.pressed.connect(_on_rhp_pressed)
	vault_loader.vault_content_ready.connect(_on_vault_loaded)
	if vault_loader:
		print("✅ Connected to VaultLoader signal")
		vault_loader.vault_content_ready.connect(_on_vault_loaded)
	else:
		print("⚠️ VaultLoader not found")

func load_hex_tree():
	var file := FileAccess.open(JSON_PATH, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		var result: Variant = JSON.parse_string(text)
		if result == null:
			push_error("Failed to parse JSON: null returned.")
			return
		if typeof(result) == TYPE_DICTIONARY:
			hex_tree_root = result
			current_node = hex_tree_root
			update_display()
		else:
			push_error("Failed to parse JSON content.")
	else:
		push_error("Could not open file at: " + JSON_PATH)

func update_display():
	if not current_node:
		return
	# var label = current_node.get("label", "Unnamed")
	var next_file = current_node.get("next", "None")
	# content_display.clear()
	# content_display.append_text("	at: " + label + "\n")
	# content_display.append_text("Next file: " + next_file + "\n")
	print("👁 Fetching markdown file:", next_file)

	if vault_loader:
		vault_loader.requesting_from = next_file
		vault_loader.fetch_markdown(next_file)

func _on_lhp_pressed():
	_branch_to(0)

func _on_rhp_pressed():
	_branch_to(1)

func _branch_to(index: int):
	var branches = current_node.get("branches", [])
	print("Current node:", current_node.get("label", "Unnamed"), " has ", branches.size(), " branches.")
	if branches.size() > index:
		current_node = branches[index]
		update_display()
	else:
		print("No branch in that direction.")


# Handles loaded vault content and embedded blocks
func _on_vault_loaded(primary_text: String, embedded: Dictionary):
	var new_text := primary_text + "\n"
	for key in embedded.keys():
		new_text += "\n\n📎 Embedded block: " + key + "\n" + embedded[key]
	content_display.text = new_text


func _on_request_completed(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	var path = vault_loader.requesting_from
	print("✅ HTTP request completed for:", path)

	if response_code != 200:
		push_error("Failed to load: " + path + " with code " + str(response_code))
		return

	var text: String = body.get_string_from_utf8()
	var links = _extract_links(text)
	vault_loader.emit_signal("vault_content_ready", text, links)

func _extract_links(text: String) -> Dictionary:
	var found_links := {}
	var regex = RegEx.new()
	regex.compile("!\\[\\[(.*?)\\]\\]")

	for match in regex.search_all(text):
		var link = match.get_string(1).strip_edges()
		found_links[link] = link + ".md"
	return found_links
