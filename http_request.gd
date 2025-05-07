extends Node

@onready var lhp = $HBoxContainer/lhp
@onready var rhp = $HBoxContainer/rhp
@onready var fetcher = $HBoxContainer/HTTPRequest

var page_urls = [
	"https://raw.githubusercontent.com/CR-ux/CGMS/main/CYOCGMS/public/hexes/The%20Woman%20In%20The%20Wallpaper/hex-1-A.md"
]

var current_page = 0

func _ready():
	fetch_page(current_page)

func fetch_page(index):
	if index >= 0 and index < page_urls.size():
		fetcher.request(page_urls[index])

func _on_httprequest_request_completed(_result, response_code, _headers, body):
	print("Request finished with code: ", response_code)

	if response_code == 200:
		var text = body.get_string_from_utf8()
		var split = text.split("~PAGE_BREAK~")
		print("Split size: ", split.size())
		print("Split content: ", split)
		lhp.text = split[0]
		rhp.text = split.size() > 1 and split[1] or ""
	else:
		lhp.text = "Failed to fetch page."
		rhp.text = ""
