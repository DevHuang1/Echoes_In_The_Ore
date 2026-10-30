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
	var result := {
		"id": mission_id(), "title": "Receive your watch",
		"description": "Bridge planning table: speak with Commander Chen, review the active duties, then acknowledge the handoff.",
		"purpose": "Asteria-1 is approaching Erebos. Accept responsibility and learn what the crew needs from you.",
		"station": "bridge.planning", "marker_label": "BRIDGE"
	}
	if has("watch.acknowledged"):
		result.title = "Watch handed over"
		result.description = "Wait at the bridge for the Erebos survey briefing. Do not deploy until Commander Chen authorizes landing."
		result.purpose = "The ship is not cleared to land yet. Your watch is complete, but the mission briefing is still pending."
	elif has("amara.repair_reported"):
		result.title = "Hand over the watch"
		result.description = "Bridge planning table: present your verified service report and receive Commander Chen's acknowledgement."
		result.purpose = "The crew needs a clear record of what was observed, repaired, and confirmed before the watch changes."
	elif has("power.reported"):
		result.title = "Restore irrigation"
		result.description = "Hydroponics console: route nutrients through the restricted manifold, verify flow, then report the readings to Amara."
		result.purpose = "The plants are receiving too little nutrient flow. Repair the cause using the measurements you recorded."
		result.station = "hydro.console"; result.marker_label = "HYDROPONICS"
	elif has("amara.observation_reported"):
		result.title = "Restore service power"
		result.description = "Power room: diagnose the fault, isolate the correct breaker, synchronize the cell banks, then verify the feed."
		result.purpose = "The irrigation fault may be caused by low power. Stabilize the service feed before repairing the nutrient line."
		result.station = "power.breaker"; result.marker_label = "POWER"
	elif has("hydro.diagnosed"):
		result.title = "Report the delivery problem"
		result.description = "Speak with Amara and compare the healthy pump, normal reservoir, and restricted delivery readings."
		result.purpose = "Amara needs the evidence before the crew changes settings or replaces working equipment."
		result.station = "amara"; result.marker_label = "AMARA"
	elif has("amara.introduced"):
		result.title = "Inspect nutrient delivery"
		result.description = "Hydroponics console: measure nutrient strength, pump output, and delivery; record what the readings show."
		result.purpose = "Find out why the seedlings are weakening before attempting a repair."
		result.station = "hydro.console"; result.marker_label = "HYDROPONICS"
	elif has("roster.reviewed"):
		result.title = "Meet Amara"
		result.description = "Hydroponics, below crew quarters: speak with Dr. Amara Okoye about the grow beds and her concerns."
		result.purpose = "Meet the science officer and learn why she is worried about the ship's plant systems."
		result.station = "amara"; result.marker_label = "AMARA"
	elif has("watch.accepted"):
		result.title = "Review the duty roster"
		result.description = "Crew quarters: use Thura's personal terminal to read the duty roster and current watch records."
		result.purpose = "Learn who is aboard and what needs attention before starting the ship's work orders."
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
