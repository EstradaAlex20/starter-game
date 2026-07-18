extends Label

func _ready():
	text = "Coins: %d" % ScoreManager.coins
	ScoreManager.coins_changed.connect(_on_coins_changed)

func _on_coins_changed(total: int) -> void:
	text = "Coins: %d" % total
