extends Control

@onready var markdown_display = $Control/MarkdownDisplay

func _ready():
	$HBoxContainer/TreePanel/MarkdownLoader.connect(
		"vault_content_ready",
		Callable(self, "_on_vault_ready_proxy")
	)
	
	var start_screen = $StartScreen
	var buttons = {
		"Queen": "hex-1-A",
		"Pawn": "hex-1-B",
		"Knight": "hex-1-C",
		"Bishop": "hex-1-D",
		"Castle": "hex-1-E",
		"King": "hex-1-F"
	}

	for label in buttons.keys():
		var btn = start_screen.get_node("HexButtonsContainer/Button_%s" % label)
		if btn:
			btn.connect("pressed", Callable(self, "_on_hex_button_pressed").bind(buttons[label]))
		else:
			print("Warning: Could not find button for %s" % label)

func _on_vault_ready_proxy(primary_text: String, embedded: Dictionary) -> void:
	markdown_display.type_text(primary_text, embedded)

func _on_hex_button_pressed(hex_path: String) -> void:
	print("Hex button pressed, going to:", hex_path)
	
	# Hide the start screen when a hex button is clicked
	$StartScreen.visible = false
	
	# Show main UI (HBoxContainer, etc.)
	$HBoxContainer.visible = true
	$Control.visible = true  # Assuming this is your markdown area

	# Load markdown
	$HBoxContainer/TreePanel/MarkdownLoader.fetch_markdown(hex_path + ".md")
