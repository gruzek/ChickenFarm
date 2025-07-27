extends MarginContainer

@export var starting_eggs = 0

@onready var egg_label: Label = $EggLabel
@onready var coop_label: Label = $CoopLabel

var eggs: int:
	set(eggs_in):
		eggs = eggs_in # Makes sure it won't go below 0
		egg_label.text = ("Eggs: " + str(eggs))
		print("got egg")

var chickens: int:
	set(chickens_in):
		chickens = chickens_in
		update_chicken_display()

var chickens_in_coops: int:
	set(chickens_in_coops_in):
		chickens_in_coops = chickens_in_coops_in
		update_chicken_display()

var total_coop_capacity: int:
	set(total_coop_capacity_in):
		total_coop_capacity = total_coop_capacity_in
		update_chicken_display()

func update_chicken_display():
	var chicken_text = str(chickens) + " Chicken" + ("s" if chickens != 1 else "")
	var coop_text = " " + str(chickens_in_coops) + "/" + str(total_coop_capacity) + " in Coops"
	coop_label.text = chicken_text + coop_text


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	eggs = starting_eggs
	# Chickens will manage their own count when they're created
	
	# Connect to player death signal to store stats
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.player_death.connect(_on_player_death)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_death():
	"""Store current game stats when player dies"""
	var game_stats = get_node("/root/GameStats")
	if game_stats:
		game_stats.set_death_stats(chickens, eggs)
