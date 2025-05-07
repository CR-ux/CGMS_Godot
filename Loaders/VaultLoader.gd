extends HTTPRequest

signal vault_content_ready(primary_text: String, embedded: Dictionary)

var embedded_results := {}
var pending_links := []
var loaded_paths := {}

func fetch_markdown(path: String):
	embedded_results.clear()
	pending_links.clear()
	loaded_paths.clear()
	_fetch_file(path)

func _fetch_file(path: String):
	if loaded_paths.has(path):
		return
	loaded_paths[path] = true

	var base_url := ""
	if path.begins_with("hex-"):
		base_url = "https://raw.githubusercontent.com/CR-ux/CGMS/main/cgms_engine/The%20Woman%20In%20The%20Wallpaper/"
	else:
		base_url = "https://raw.githubusercontent.com/CR-ux/THE-VAULT/main/"

	var full_url = base_url + path
	set_meta("path", path)
	var result = request(full_url)
	if result != OK:
		push_error("❌ Request failed for: " + full_url + " | Code: " + str(result))

func _on_request_completed(_result, response_code, _headers, body):
	var path = get_meta("path", "unknown")
	print("✅ HTTP request completed for:", path)
	if response_code != 200:
		push_error("Failed to load: " + path + " with code " + str(response_code))
		return

	var text: String = body.get_string_from_utf8()
	var links = _extract_links(text)

	if path.begins_with("hex-"):
		print("📤 Emitting vault_content_ready for:", path)
		emit_signal("vault_content_ready", text, {})
		return

	embedded_results[path] = text
	for key in links.keys():
		var linked_path = links[key]
		if not loaded_paths.has(linked_path):
			pending_links.append(linked_path)
			_fetch_file(linked_path)

	if pending_links.size() == 0:
		print("📤 Emitting vault_content_ready for:", path)
		emit_signal("vault_content_ready", embedded_results[path], embedded_results)

func _extract_links(text: String) -> Dictionary:
	var found_links := {}
	var regex = RegEx.new()
	regex.compile("!\\[\\[(.*?)\\]\\]")
	for match in regex.search_all(text):
		var link = match.get_string(1).strip_edges()
		found_links[link] = link + ".md"
	return found_links
