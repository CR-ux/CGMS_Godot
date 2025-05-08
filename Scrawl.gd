@tool
extends MarkdownLabel

var scroll_delay := 0.03  # Seconds between characters
var typing_text := ""
var char_index := 0
var typing := false
var lines := []
var current_line := 0

func _ready():
	scroll_active = true

func type_text(primary_text: String, _embedded: Dictionary) -> void:
	var processed_text := primary_text
	var regex := RegEx.new()
	regex.compile("!\\[\\[([^\\]]+)\\]\\]")
	var matches := regex.search_all(processed_text)
	for match in matches:
		var full := match.get_string(0)
		var inner := match.get_string(1)
		var slug := inner.replace(" ", "%20").replace("(", "%28").replace(")", "%29")
		var url := "https://carpvs.com/" + slug
		var replacement := "[" + inner + "](" + url + ")"
		processed_text = processed_text.replace(full, replacement)
	markdown_text = processed_text
	
#func _type_next_char():
#	if typing and char_index < typing_text.length():
#		append_text(typing_text[char_index])
#		char_index += 1
#		scroll_to_line(get_line_count())
#		await get_tree().create_timer(scroll_delay).timeout
#		_type_next_char()
#	else:
#		typing = false

func _fade_in_next_line():
	if current_line < lines.size():
		append_text(lines[current_line] + "\n")
		current_line += 1
		await get_tree().process_frame

		var target_scroll := get_v_scroll_bar().max_value
		var tween := create_tween()
		tween.tween_property(get_v_scroll_bar(), "value", target_scroll, 0.4)
		await tween.finished
		await tween.finished
		_fade_in_next_line()
	else:
		typing = false
