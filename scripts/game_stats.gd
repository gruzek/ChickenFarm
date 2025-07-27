extends Node

# Global singleton to store game statistics at death
var death_chicken_count: int = 0
var death_egg_count: int = 0

func set_death_stats(chickens: int, eggs: int):
	"""Store the statistics when player dies"""
	death_chicken_count = chickens
	death_egg_count = eggs

func get_death_stats_text() -> String:
	"""Get formatted death statistics text"""
	return str(death_chicken_count) + " Chickens and " + str(death_egg_count) + " Eggs"
