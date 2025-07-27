extends Control

@onready var health_bar: ColorRect = $HealthBar

# store the *original* full width
var full_width: float

func _ready():
	full_width = health_bar.size.x
	print("health bar ready")
	print(full_width)
	# initialize full health
	update_health(1.0)
	
# percent: 0.0 → 1.0
func update_health(percent: float) -> void:
	percent = clamp(percent, 0.0, 1.0)
	
	if health_bar == null:
		return
	# resize fill to match percent of bg width	
	health_bar.size.x = full_width * percent	
	# pick color
	var col: Color
	if percent > 0.5:
		col = Color(0,1,0)     # green
	elif percent > 0.25:
		col = Color(1,0.5,0)   # orange
	else:
		col = Color(1,0,0)     # red
	
	health_bar.color = col


func _on_player_health_changed(percent: float) -> void:
	update_health(percent)
