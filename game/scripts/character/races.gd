extends RefCounted
const IDS: Array[String] = ["human","elf","dwarf","orc"]
static var database: Dictionary = {}

static func catalog() -> Dictionary:
	if database.is_empty(): database = JSON.parse_string(FileAccess.get_file_as_string("res://resources/races/races.json"))
	return database

static func valid(id: Variant) -> bool:
	return id is String and IDS.has(id)

static func art_id(id: String, part: String) -> String:
	return part if id == "human" else "race_"+id+"_"+part

static func frames(id: String, part: String) -> SpriteFrames:
	return load("res://resources/art/"+art_id(id,part)+".tres") as SpriteFrames

static func preview(id: String, compact: bool = false) -> SpriteFrames:
	return load("res://resources/art/race_"+id+("_card" if compact else "_showcase")+".tres") as SpriteFrames

static func contacts(id: String) -> Dictionary:
	var path: String = "res://resources/equipment/"+("contacts.json" if id == "human" else "contacts_"+id+".json")
	return JSON.parse_string(FileAccess.get_file_as_string(path))
