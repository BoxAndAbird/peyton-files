extends StaticBody3D
## HelperBase.gd - the four helper NPCs (bible section 14): Lost Merchant,
## Field Medic, Cartographer, Strange Child. One script, data-driven per
## helper id — each gets a distinctive silhouette color, a dialogue line and
## a seeded offer list. Interacting opens the Shop screen
## (GameManager.open_shop(self)).
##
## OFFER SHAPE: { kind, label, desc, price, currency, item_id?, sold: bool }
##   kind: "item" | "heal" | "sanity" | "reveal" | "curse_trade"
##   currency: "essence" (default) or "sanity" (Strange Child pays in mind)
##
## Integration: StageBuilder spawns one helper (stage-seeded) in the "helper"
## room. purchase(i) applies the effect through GameManager/RunManager and
## returns true on success so the shop UI can refresh.

const HELPERS := {
	"merchant": {
		"name": "The Lost Merchant",
		"color": Color(0.85, 0.7, 0.35),
		"line": "You again? No... no, you just look like someone. Buy something. Please.",
	},
	"medic": {
		"name": "The Field Medic",
		"color": Color(0.45, 0.85, 0.6),
		"line": "Sit. Breathe. You are not the worst I have treated down here. Probably.",
	},
	"cartographer": {
		"name": "The Cartographer",
		"color": Color(0.5, 0.7, 0.95),
		"line": "The map moved again while I slept. Hold still and I will show you the way anyway.",
	},
	"child": {
		"name": "The Strange Child",
		"color": Color(0.75, 0.5, 0.85),
		"line": "The cave says you can have a present. It only wants a little of you back.",
	},
}

var helper_id := "merchant"
var info: Dictionary = {}
var offers: Array = []
var _free_heal_used := false   # medic: one free minor heal (bible)

func setup(p_helper_id: String, rng: RandomNumberGenerator) -> void:
	helper_id = p_helper_id
	info = HELPERS.get(helper_id, HELPERS["merchant"])
	collision_layer = 0b100000   # interactable layer
	collision_mask = 0
	add_to_group("interactables")
	add_to_group("helpers")      # sanity NPC-distortion events check this

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.45
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	add_child(col)

	# Placeholder body: hooded figure tinted per helper + a small camp light
	# (helpers are safe islands: always well lit, bible section 19).
	var mesh := MeshInstance3D.new()
	var cap_m := CapsuleMesh.new()
	cap_m.radius = 0.42
	cap_m.height = 1.6
	mesh.mesh = cap_m
	mesh.position = Vector3(0, 0.9, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = info["color"]
	mat.roughness = 1.0
	mesh.material_override = mat
	add_child(mesh)
	var hood := MeshInstance3D.new()
	var cone := CylinderMesh.new()
	cone.top_radius = 0.05
	cone.bottom_radius = 0.4
	cone.height = 0.6
	hood.mesh = cone
	hood.position = Vector3(0, 1.9, 0)
	hood.material_override = mat
	add_child(hood)
	var lamp := OmniLight3D.new()
	lamp.omni_range = 7.0
	lamp.light_energy = 1.0
	lamp.light_color = Color(info["color"]).lightened(0.4)
	lamp.shadow_enabled = false
	lamp.position = Vector3(0.8, 1.6, 0)
	add_child(lamp)

	_build_offers(rng)

func prompt_text() -> String:
	return "Speak with " + String(info["name"])

func interact(_player: Node) -> void:
	GameManager.open_shop(self)

# --- offers ------------------------------------------------------------
func _build_offers(rng: RandomNumberGenerator) -> void:
	offers.clear()
	match helper_id:
		"merchant":
			# 3 items scaling with stage; prices by rarity.
			for i in range(3):
				var iid := Database.roll_item_id(rng, 2.0 + RunManager.stage_index * 2.0)
				var item := Database.get_item(iid)
				offers.append({
					"kind": "item", "item_id": iid, "sold": false, "currency": "essence",
					"label": String(item["name"]),
					"desc": "%s · +%d %s" % [String(item["rarity"]).capitalize(),
						int(item["stat_value"]), String(item["stat"]).capitalize()],
					"price": _price_for(String(item["rarity"])),
				})
		"medic":
			offers.append({"kind": "heal", "label": "Field Dressing (free)", "sold": false,
				"desc": "A quick patch. Restores 20 health.", "price": 0, "currency": "essence"})
			offers.append({"kind": "heal", "label": "Full Treatment", "sold": false,
				"desc": "Restores 60 health.", "price": 15, "currency": "essence"})
			offers.append({"kind": "sanity", "label": "Steady Words", "sold": false,
				"desc": "Restores 30 sanity.", "price": 12, "currency": "essence"})
		"cartographer":
			offers.append({"kind": "reveal", "label": "Mark the Exit", "sold": false,
				"desc": "He sketches the way to the descent gate.", "price": 8, "currency": "essence"})
			offers.append({"kind": "sanity", "label": "A Familiar Map", "sold": false,
				"desc": "Something recognizable. Restores 20 sanity.", "price": 8, "currency": "essence"})
			var iid := Database.roll_item_id(rng, 6.0)
			var item := Database.get_item(iid)
			offers.append({"kind": "item", "item_id": iid, "sold": false, "currency": "essence",
				"label": String(item["name"]) + " (found in a dead man's pack)",
				"desc": "%s · +%d %s" % [String(item["rarity"]).capitalize(),
					int(item["stat_value"]), String(item["stat"]).capitalize()],
				"price": _price_for(String(item["rarity"])) - 2})
		"child":
			# One powerful item paid in SANITY (bible: trades curses for relics).
			var iid := Database.roll_item_id(rng, 20.0)
			var item := Database.get_item(iid)
			if String(item["rarity"]) in ["common", "uncommon"]:
				iid = Database.roll_item_id(rng, 20.0)
				item = Database.get_item(iid)
			offers.append({"kind": "curse_trade", "item_id": iid, "sold": false,
				"currency": "sanity",
				"label": String(item["name"]),
				"desc": "%s · +%d %s. 'The cave keeps a piece of you.'" % [
					String(item["rarity"]).capitalize(), int(item["stat_value"]),
					String(item["stat"]).capitalize()],
				"price": 25})
			offers.append({"kind": "clue", "label": "A Cryptic Clue", "sold": false,
				"desc": "The child whispers something true.", "price": 0, "currency": "essence"})

func _price_for(rarity: String) -> int:
	match rarity:
		"common": return 8
		"uncommon": return 14
		"rare": return 22
		"epic": return 34
		"legendary": return 50
		"cursed": return 18
	return 10

## Merchant Credit upgrade: first shop item discounted.
func price_of(index: int) -> int:
	var price := int(offers[index].get("price", 0))
	if RunManager.active_tags().has("shop_discount") and index == 0:
		price = int(price * 0.5)
	return price

# --- purchasing ----------------------------------------------------------
func purchase(index: int) -> bool:
	if index < 0 or index >= offers.size():
		return false
	var offer: Dictionary = offers[index]
	if offer.get("sold", false):
		return false
	var price := price_of(index)

	# Pay.
	if String(offer.get("currency", "essence")) == "sanity":
		var sm = _sanity_manager()
		if sm == null or sm.sanity <= price + 5.0:
			EventBus.subtitle_requested.emit("You do not have enough of yourself left.", 2.0)
			return false
		sm.set_sanity(sm.sanity - price)
	else:
		if RunManager.essence < price:
			EventBus.subtitle_requested.emit("Not enough essence.", 1.5)
			return false
		RunManager.essence -= price
		EventBus.essence_gained.emit(0)   # refresh the HUD counter

	# Deliver.
	var ok := true
	match String(offer["kind"]):
		"item", "curse_trade":
			ok = RunManager.add_item(String(offer["item_id"]))
			if not ok:
				# Refund on full pack.
				if String(offer.get("currency", "essence")) == "essence":
					RunManager.essence += price
					EventBus.essence_gained.emit(0)
				EventBus.subtitle_requested.emit("Your pack is full.", 1.5)
				return false
		"heal":
			var amount := 20.0 if price == 0 else 60.0
			if price == 0:
				if _free_heal_used:
					return false
				_free_heal_used = true
			if GameManager.player and GameManager.player.has_method("heal"):
				GameManager.player.heal(amount)
		"sanity":
			var sm = _sanity_manager()
			if sm:
				sm.set_sanity(sm.sanity + (30.0 if price >= 12 else 20.0))
		"reveal":
			_reveal_exit()
		"clue":
			EventBus.subtitle_requested.emit(_cryptic_clue(), 4.0)
	offer["sold"] = true
	AudioManager.play("pickup")
	# Ending matrix (Appendix G2): Mercy tracks aiding the Medic and Child.
	if helper_id == "medic" or helper_id == "child":
		RunManager.helpers_aided += 1
	return true

func _sanity_manager():
	if GameManager.current_stage:
		return GameManager.current_stage.get_node_or_null("SanityManager")
	return null

func _reveal_exit() -> void:
	if GameManager.current_stage and GameManager.current_stage.has_method("reveal_exit_direction"):
		GameManager.current_stage.reveal_exit_direction()

func _cryptic_clue() -> String:
	var clues := [
		"'The worm is blind, but the ground tells it everything.'",
		"'When your own face hunts you, remember which hand you favor.'",
		"'The Priest fears silence more than steel.'",
		"'Some chests have teeth. The shiny ones, mostly.'",
		"'Low sanity opens doors. Some should stay shut.'",
	]
	return clues[randi() % clues.size()]
