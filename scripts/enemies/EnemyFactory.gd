class_name EnemyFactory
extends RefCounted
## EnemyFactory.gd - maps species id -> dedicated species script (Appendix E:
## "must be implemented as a dedicated scene inheriting from EnemyBase").
## Species without a bespoke script (e.g. "drowned") fall back to EnemyBase.
## Const map, no autoload access -> safe in static context.

const BASE := "res://scripts/enemies/EnemyBase.gd"
const SPECIES := {
	"crawler":         "res://scripts/enemies/species/Crawler.gd",
	"blind_stalker":   "res://scripts/enemies/species/BlindStalker.gd",
	"crystal_spider":  "res://scripts/enemies/species/CrystalSpider.gd",
	"mimic":           "res://scripts/enemies/species/MimicCache.gd",
	"tunnel_screamer": "res://scripts/enemies/species/TunnelScreamer.gd",
	"bone_collector":  "res://scripts/enemies/species/BoneCollector.gd",
	"watcher":         "res://scripts/enemies/species/Watcher.gd",
	"shadow_parasite": "res://scripts/enemies/species/ShadowParasite.gd",
	"hollow_monk":     "res://scripts/enemies/species/HollowMonk.gd",
	"faceless":        "res://scripts/enemies/species/FacelessEcho.gd",
}

## Returns an un-setup enemy node; caller must add_child THEN call
## setup(species_id, stage_index) (needs tree access).
static func create(species_id: String):
	var path: String = SPECIES.get(species_id, BASE)
	if not ResourceLoader.exists(path):
		path = BASE
	return load(path).new()
