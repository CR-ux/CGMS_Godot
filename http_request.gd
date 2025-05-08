extends Node


@onready var lhp = %lhp
@onready var rhp = %rhp
@onready var fetcher = %HTTPRequest

var current_page = 0

# Store index.json data from THE-VAULT
var vault_paths: Array = []

func clean_embeds(text: String) -> String:
	# Remove 'Embedded block:' lines but keep the filename as a wikilink
	var lines = text.split("\n")
	var cleaned = []
	for line in lines:
		if line.strip_edges().begins_with("📎 Embedded block:") or line.strip_edges().begins_with("Embedded block:"):
			var filename = line.split(":")[-1].strip_edges()
			if filename != "":
				cleaned.append("![[%s]]" % filename)
		else:
			cleaned.append(line)
	return "\n".join(cleaned)

func wikilink_to_url(text: String) -> String:
	var pattern := r"!\[\[([^\]]+)\]\]"
	var regex = RegEx.new()
	regex.compile(pattern)
	var matches = regex.search_all(text)

	var vault_base := "https://raw.githubusercontent.com/CR-ux/THE-VAULT/main/"

	for m in matches:
		var full = m.get_string(0)
		var inner = m.get_string(1)
		print("🔍 Found wikilink:", inner)
		var encoded_inner = inner.uri_encode()
		var is_image := inner.ends_with(".png") or inner.ends_with(".jpg") or inner.ends_with(".jpeg") or inner.ends_with(".gif")
		var final_url := ""

		# Search index for a matching filename, with verbose logging
		for path in vault_paths:
			var candidate = path.get_file().strip_edges().to_lower()
			var target = inner.strip_edges().to_lower()
			if candidate == target:
				final_url = vault_base + path.uri_encode()
				print("✅ Matched:", inner, "→", final_url)
				break
			else:
				print("❌ No match for:", target, "against", candidate)

		# Fallback to root if not found
		if final_url == "":
			final_url = vault_base + encoded_inner
			print("⚠️ No match found, falling back to:", final_url)

		if is_image:
			text = text.replace(full, "[img]" + final_url + "[/img]")
		else:
			text = text.replace(full, "[url=" + final_url + "]" + inner + "[/url]")

	print("🔧 Final resolved text:\n", text)
	return text

func _ready():
	fetch_vault_index()

# Fetch index.json from THE-VAULT and store in vault_paths
func fetch_vault_index():
	var index_request = HTTPRequest.new()
	add_child(index_request)
	index_request.request("https://raw.githubusercontent.com/CR-ux/THE-VAULT/main/index.json")
	index_request.request_completed.connect(_on_index_request_completed)

func _on_index_request_completed(_result, code, _headers, body):
	if code == 200:
		var data = body.get_string_from_utf8()
		var parsed = JSON.parse_string(data)
		if parsed is Array:
			vault_paths = parsed
			print("🗃️ Vault index loaded with %d entries" % vault_paths.size())
			fetch_page("https://raw.githubusercontent.com/CR-ux/CGMS/main/CYOCGMS/public/hexes/The%20Woman%20In%20The%20Wallpaper/hex-1-A.md")

func fetch_page(url):
	fetcher.request(url)

func _on_httprequest_request_completed(_result, response_code, _headers, body):
	print("Request finished with code: ", response_code)

	if response_code == 200:
		var text = body.get_string_from_utf8()
		var split = text.split("~PAGE_BREAK~")

		# Clean up both sides
		var clean_text_l = wikilink_to_url(clean_embeds(split[0]))
		var clean_text_r = split.size() > 1 and wikilink_to_url(clean_embeds(split[1])) or ""

		# Enable BBCode to support links
		lhp.bbcode_enabled = true
		rhp.bbcode_enabled = true

		lhp.text = clean_text_l
		rhp.text = clean_text_r
	else:
		lhp.text = "Failed to fetch page."
		rhp.text = ""
