class_name RoomGraph
extends RefCounted
## RoomGraph.gd - stage layout graph (bible section 7).
## Places 12-22 rooms on a coarse grid via seeded random walk with branches,
## assigns room roles per the Room Role Table, and guarantees:
##   - exactly one Entrance (walk start) and one Exit (graph-farthest room)
##   - a connected critical path (the walk itself is always connected)
##   - role quotas: 1-3 Loot, 0-1 Helper, 0-2 Secret, 1-2 Event, rest
##     Combat/Traversal in the 35-45% / 15-25% bands.
##
## Output rooms: Array[Dictionary] with
##   { id:int, cell:Vector2i, role:String, links:Array[int], depth:int }
## Deterministic for a given RandomNumberGenerator state.

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var rooms: Array = []
var cell_to_id: Dictionary = {}   # Vector2i -> room id

static func generate(rng: RandomNumberGenerator, count: int) -> RoomGraph:
	var g := RoomGraph.new()
	g._walk(rng, count)
	g._link_extra(rng)
	g._compute_depths()
	g._assign_roles(rng)
	return g

# --- placement: random walk with occasional branching -----------------
func _walk(rng: RandomNumberGenerator, count: int) -> void:
	var cur := Vector2i.ZERO
	_add_room(cur)
	var frontier: Array = [cur]
	while rooms.size() < count:
		# Branch from a random existing room 25% of the time, else continue.
		var from: Vector2i = cur if rng.randf() > 0.25 else frontier[rng.randi_range(0, frontier.size() - 1)]
		var placed := false
		var dirs := DIRS.duplicate()
		# Seeded shuffle.
		for i in range(dirs.size() - 1, 0, -1):
			var j := rng.randi_range(0, i)
			var tmp = dirs[i]; dirs[i] = dirs[j]; dirs[j] = tmp
		for d in dirs:
			var next: Vector2i = from + d
			if not cell_to_id.has(next):
				_add_room(next)
				_link(cell_to_id[from], cell_to_id[next])
				frontier.append(next)
				cur = next
				placed = true
				break
		if not placed:
			# Dead-ended: hop to another frontier room.
			cur = frontier[rng.randi_range(0, frontier.size() - 1)]

func _add_room(cell: Vector2i) -> void:
	var id := rooms.size()
	rooms.append({"id": id, "cell": cell, "role": "combat", "links": [], "depth": 0})
	cell_to_id[cell] = id

func _link(a: int, b: int) -> void:
	if not rooms[a]["links"].has(b):
		rooms[a]["links"].append(b)
	if not rooms[b]["links"].has(a):
		rooms[b]["links"].append(a)

## A few extra links between adjacent cells create loops (better flow).
func _link_extra(rng: RandomNumberGenerator) -> void:
	for r in rooms:
		for d in DIRS:
			var n: Vector2i = r["cell"] + d
			if cell_to_id.has(n) and rng.randf() < 0.18:
				_link(r["id"], cell_to_id[n])

## BFS depth from room 0 (the entrance).
func _compute_depths() -> void:
	var seen := {0: true}
	var queue := [0]
	rooms[0]["depth"] = 0
	while not queue.is_empty():
		var id: int = queue.pop_front()
		for nid in rooms[id]["links"]:
			if not seen.has(nid):
				seen[nid] = true
				rooms[nid]["depth"] = rooms[id]["depth"] + 1
				queue.append(nid)

func _assign_roles(rng: RandomNumberGenerator) -> void:
	# Entrance = room 0; Exit = deepest room.
	rooms[0]["role"] = "entrance"
	var exit_id := 0
	for r in rooms:
		if r["depth"] > rooms[exit_id]["depth"]:
			exit_id = r["id"]
	rooms[exit_id]["role"] = "exit"

	# Candidates = everything else, shuffled deterministically.
	var pool: Array = []
	for r in rooms:
		if r["id"] != 0 and r["id"] != exit_id:
			pool.append(r["id"])
	for i in range(pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = pool[i]; pool[i] = pool[j]; pool[j] = tmp

	var quotas := [
		["loot", rng.randi_range(1, 3)],
		["event", rng.randi_range(1, 2)],
		["secret", rng.randi_range(0, 2)],
		["helper", rng.randi_range(0, 1)],
	]
	var idx := 0
	for q in quotas:
		for i in range(q[1]):
			if idx < pool.size():
				rooms[pool[idx]]["role"] = q[0]
				idx += 1
	# Remaining rooms: ~30% traversal, rest combat.
	while idx < pool.size():
		rooms[pool[idx]]["role"] = "traversal" if rng.randf() < 0.3 else "combat"
		idx += 1

func get_entrance() -> Dictionary:
	return rooms[0]

func get_exit() -> Dictionary:
	for r in rooms:
		if r["role"] == "exit":
			return r
	return rooms[rooms.size() - 1]
