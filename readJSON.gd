extends Node

const JSON_PATH := "res://hex_tree_structure.json"

var hex_tree_root: Dictionary
var current_node: Dictionary

#HTTPs Node:
@onready var vault_loader := $"MarkdownLoader"

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
	var label = current_node.get("label", "Unnamed")
	var next_file = current_node.get("next", "None")
	content_display.clear()
	content_display.append_text("Now at: " + label + "\n")
	content_display.append_text("Next file: " + next_file + "\n")
	print("👁 Fetching markdown file:", next_file)

	if vault_loader:
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
	print("🚀 Vault loaded with primary_text:\n", primary_text.substr(0, 100))
	content_display.clear()
	content_display.append_text(primary_text)
	print("🚀 Vault content received!")

	for block in embedded.keys():
		print("📎 Embedded block:", block)
		content_display.append_text("\n[embedded: " + block + "]")
