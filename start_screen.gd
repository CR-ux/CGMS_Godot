extends Control

signal start_branch(label: String)

func _ready():
	$HexButtonsContainer/Button_Queen.pressed.connect(_on_queen_pressed)
	$HexButtonsContainer/Button_Pawn.pressed.connect(_on_pawn_pressed)
	$HexButtonsContainer/Button_Bishop.pressed.connect(_on_pawn_pressed)
	$HexButtonsContainer/Button_Castle.pressed.connect(_on_pawn_pressed)
	$HexButtonsContainer/Button_Knight.pressed.connect(_on_pawn_pressed)
	$HexButtonsContainer/Button_King.pressed.connect(_on_pawn_pressed)	# and so on...

func _on_queen_pressed():
	emit_signal("start_branch", "hex-1-A")

func _on_pawn_pressed():
	emit_signal("start_branch", "hex-1-B")
