extends RefCounted
## Campaign data only. The existing walkthrough owns actions, actors and input.
const CHAPTER := "chapter.asteria.first_watch"
const MISSIONS := [
	"story.a1.010_watch_briefing", "story.a1.020_meet_amara",
	"story.a1.030_aux_service", "story.a1.040_irrigation_report",
	"story.a1.050_watch_handoff",
]
const CUES := ["cue.thura.earth_years", "cue.asteria.arrival", "cue.asteria.watch_handoff"]
const RECEIPTS := ["watch.accepted", "roster.reviewed", "amara.introduced",
	"hydro.observed", "hydro.diagnosed", "amara.observation_reported",
	"power.reported", "amara.repair_reported", "summary.submitted", "watch.acknowledged"]
var receipts := {}
var evidence := {}
var cues := {}
var sequence := 0
var summary := ""

func has(receipt: String) -> bool:
	return bool(receipts.get(receipt, false))

func record(receipt: String) -> bool:
	if receipt not in RECEIPTS or has(receipt): return false
	receipts[receipt] = true
	return true

func completed_count() -> int:
	var total := 0
	for receipt in ["roster.reviewed", "amara.observation_reported", "power.reported", "amara.repair_reported", "watch.acknowledged"]:
		if has(receipt): total += 1
	return total

func mission_id() -> String:
	return MISSIONS[mini(completed_count(), 4)]

func work_orders() -> PackedStringArray:
	var allowed := PackedStringArray()
	if has("watch.accepted"): allowed.append("crew")
	if has("amara.introduced"): allowed.append("hydro.inspect")
	if has("amara.observation_reported"): allowed.append("power")
	if has("power.reported"): allowed.append("hydro")
	return allowed

func objective() -> Dictionary:
	var result := {"id": mission_id(), "title": "Receive the watch", "description": "Bridge: speak to Maya through the planning table beside the main helm.", "station": "bridge.planning", "marker_label": "BRIDGE"}
	if has("watch.acknowledged"):
		result.title = "Watch handed over"
		result.description = "Await the Erebos survey briefing. Optional ship activities remain available; deployment is not authorized."
	elif has("amara.repair_reported"):
		result.title = "Hand over the watch"
		result.description = "Bridge planning table: review your measured summary and receive Maya's acknowledgement."
	elif has("power.reported"):
		result.title = "Restore irrigation"
		result.description = "Hydroponics console: service the restricted manifold, restore and verify delivery, then report to Amara."
		result.station = "hydro.console"; result.marker_label = "HYDROPONICS"
	elif has("amara.observation_reported"):
		result.title = "Restore service power"
		result.description = "Power room: diagnose, isolate and allocate at the breaker/converter, synchronize the cell banks, restore and verify."
		result.station = "power.breaker"; result.marker_label = "POWER"
	elif has("hydro.diagnosed"):
		result.title = "Report the delivery problem"
		result.description = "Speak to Amara about the healthy pump, normal reservoir and restricted delivery."
		result.station = "amara"; result.marker_label = "AMARA"
	elif has("amara.introduced"):
		result.title = "Inspect nutrient delivery"
		result.description = "Hydroponics console: capture EC, pump capacity and delivery; record the diagnosis supported by the readings."
		result.station = "hydro.console"; result.marker_label = "HYDROPONICS"
	elif has("roster.reviewed"):
		result.title = "Meet Amara"
		result.description = "Hydroponics, below crew quarters: talk to Amara Okoye about the grow beds."
		result.station = "amara"; result.marker_label = "AMARA"
	elif has("watch.accepted"):
		result.title = "Review the duty roster"
		result.description = "Crew quarters, below the bridge corridor: use the personal computer desk to compare roster and watch records."
		result.station = "quarters.desk"; result.marker_label = "QUARTERS"
	return result

func request_cue(cue_id: String, delivery: String) -> Dictionary:
	if cue_id not in CUES: return {}
	var previous: Dictionary = cues.get(cue_id, {})
	if previous.get("status", "") in ["completed", "skipped"]: return {}
	sequence += 1
	# A loaded older checkpoint can repeat its counter. A fresh nonce keeps
	# callbacks from that previous attempt distinct across reloads and restarts.
	var token := "%s:%d:%s" % [cue_id, sequence,Crypto.new().generate_random_bytes(12).hex_encode()]
	cues[cue_id] = {"version": 1, "status": "pending", "token": token, "delivery": delivery}
	return {"cue_id": cue_id, "request_token": token, "contract_version": 1, "chapter": CHAPTER, "phase": "outbound"}

func finish_cue(cue_id: String, token: String, outcome: String) -> bool:
	if cue_id not in CUES or outcome not in ["completed", "skipped", "cancelled", "failed"]: return false
	var current: Dictionary = cues.get(cue_id, {})
	if current.get("status") != "pending" or current.get("token") != token: return false
	current.status = outcome
	return true

func snapshot() -> Dictionary:
	return {"version": 1, "chapter": CHAPTER, "receipts": receipts.duplicate(true), "evidence": evidence.duplicate(true), "cues": cues.duplicate(true), "sequence": sequence, "summary": summary}

func restore(data: Dictionary) -> bool:
	if data.get("version") != 1 or data.get("chapter") != CHAPTER: return false
	for key in ["receipts", "evidence", "cues"]:
		if not data.get(key) is Dictionary: return false
	if not data.get("summary") is String or data.summary.length() > 30000: return false
	if not (data.get("sequence") is int or data.get("sequence") is float) or not is_finite(float(data.sequence)) or data.sequence < 0 or data.sequence != floor(data.sequence): return false
	for key in data.receipts:
		if key not in RECEIPTS or data.receipts[key] != true or not data.receipts[key] is bool: return false
	for key in data.evidence:
		if key not in ["power.before", "power.after", "hydro.before", "hydro.after"] or not data.evidence[key] is String or data.evidence[key].length() > 10000: return false
	for i in range(1, RECEIPTS.size()):
		if data.receipts.has(RECEIPTS[i]) and not data.receipts.has(RECEIPTS[i-1]): return false
	for key in data.cues:
		var cue: Variant = data.cues[key]
		if key not in CUES or not cue is Dictionary or cue.get("version") != 1: return false
		if cue.get("status") not in ["pending", "completed", "skipped", "cancelled", "failed"]: return false
		if not cue.get("token") is String or not cue.token.begins_with(key+":") or not cue.get("delivery") is String: return false
	if data.receipts.has("watch.acknowledged") and (data.summary.is_empty() or data.cues.get("cue.asteria.watch_handoff", {}).get("status") not in ["completed", "skipped"]): return false
	receipts = data.receipts.duplicate(true); evidence = data.evidence.duplicate(true)
	cues = data.cues.duplicate(true); sequence = int(data.sequence); summary = data.summary
	return true
