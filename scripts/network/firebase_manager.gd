extends Node

## Signals
signal auth_completed(success: bool, user_id: String)
signal google_sign_in_completed(success: bool, user_id: String, email: String)
signal save_completed(success: bool, error_msg: String)
signal load_completed(success: bool, data: Dictionary)
signal signed_out()

## Configuration loaded from .env or OS environment
var api_key: String = ""
var project_id: String = ""
var auth_domain: String = ""
var app_id: String = ""
var storage_bucket: String = ""
var hosting_site: String = "echoesintheore"

## Session state
var current_user_id: String = ""
var id_token: String = ""
var refresh_token: String = ""
var user_email: String = ""
var user_display_name: String = ""
var auth_provider: String = "" # "anonymous" or "google.com"
var is_authenticated: bool = false

## Local Auth persistence file
const AUTH_CACHE_PATH: String = "user://firebase_auth.json"

## Endpoints
const FIRESTORE_API_BASE: String = "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/"
const AUTH_URL_BASE: String = "https://identitytoolkit.googleapis.com/v1/accounts:signUp?key="
const AUTH_SIGN_IN_WITH_IDP_URL: String = "https://identitytoolkit.googleapis.com/v1/accounts:signInWithIdp?key="
const SECURE_TOKEN_URL: String = "https://securetoken.googleapis.com/v1/token?key="

## Local loopback server for Desktop Google Sign-in
var _loopback_server: TCPServer = null
var _loopback_port: int = 8080
var _loopback_timeout: float = 0.0
var _loopback_callback: Callable = Callable()


func _ready() -> void:
	_load_env_configuration()
	
	if api_key.is_empty() or project_id.is_empty():
		push_warning("[Firebase] Credentials missing. Please define FIREBASE_API_KEY and FIREBASE_PROJECT_ID.")
		return
	
	print("[Firebase] Initialized with Project ID: ", project_id)
	
	# Attempt to restore previous session from disk, or fallback to guest sign-in
	if not _try_restore_cached_session():
		sign_in_anonymous()


func _process(delta: float) -> void:
	if _loopback_server != null and _loopback_server.is_listening():
		_poll_loopback_server(delta)
	
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js_bridge = Engine.get_singleton("JavaScriptBridge")
		var token_val = js_bridge.eval("window.__godot_id_token || ''")
		if token_val is String and not token_val.is_empty():
			js_bridge.eval("window.__godot_id_token = null;")
			print("[Firebase] Received Google ID token from Web JS bridge: ", token_val.substr(0, 15), "...")
			sign_in_with_google_id_token(token_val, _loopback_callback)


# ==============================================================================
# Environment Configuration (.env parser)
# ==============================================================================
func _load_env_configuration() -> void:
	# 1. Try OS Environment variables first (useful for containers/hosting)
	api_key = OS.get_environment("FIREBASE_API_KEY")
	project_id = OS.get_environment("FIREBASE_PROJECT_ID")
	auth_domain = OS.get_environment("FIREBASE_AUTH_DOMAIN")
	app_id = OS.get_environment("FIREBASE_APP_ID")
	storage_bucket = OS.get_environment("FIREBASE_STORAGE_BUCKET")
	hosting_site = OS.get_environment("FIREBASE_HOSTING_SITE")
	
	# 2. Fall back to local .env file in project root
	if api_key.is_empty() or project_id.is_empty():
		var env_vars = _parse_env_file("res://.env")
		if env_vars.is_empty():
			env_vars = _parse_env_file("user://.env")
		
		if env_vars.has("FIREBASE_API_KEY") and api_key.is_empty():
			api_key = env_vars["FIREBASE_API_KEY"]
		if env_vars.has("FIREBASE_PROJECT_ID") and project_id.is_empty():
			project_id = env_vars["FIREBASE_PROJECT_ID"]
		if env_vars.has("FIREBASE_AUTH_DOMAIN") and auth_domain.is_empty():
			auth_domain = env_vars["FIREBASE_AUTH_DOMAIN"]
		if env_vars.has("FIREBASE_APP_ID") and app_id.is_empty():
			app_id = env_vars["FIREBASE_APP_ID"]
		if env_vars.has("FIREBASE_STORAGE_BUCKET") and storage_bucket.is_empty():
			storage_bucket = env_vars["FIREBASE_STORAGE_BUCKET"]
		if env_vars.has("FIREBASE_HOSTING_SITE") and hosting_site.is_empty():
			hosting_site = env_vars["FIREBASE_HOSTING_SITE"]
	
	# Fallback defaults if not set in environment (API key must be provided via environment or .env)
	if project_id.is_empty():
		project_id = "hackathon-c565e"
	if auth_domain.is_empty():
		auth_domain = project_id + ".firebaseapp.com"
	if app_id.is_empty():
		app_id = "1:424472725839:web:866a1dd51f51a241981d3a"
	if storage_bucket.is_empty():
		storage_bucket = project_id + ".firebasestorage.app"
	if hosting_site.is_empty():
		hosting_site = "echoesintheore"


func _parse_env_file(path: String) -> Dictionary:
	var result: Dictionary = {}
	if not FileAccess.file_exists(path):
		return result
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return result
	
	while not file.eof_reached():
		var line: String = file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		
		var delimiter_idx: int = line.find("=")
		if delimiter_idx == -1:
			continue
		
		var key: String = line.substr(0, delimiter_idx).strip_edges()
		var value: String = line.substr(delimiter_idx + 1).strip_edges()
		
		# Strip enclosing quotes if present
		if (value.begins_with("\"") and value.ends_with("\"")) or (value.begins_with("'") and value.ends_with("'")):
			value = value.substr(1, value.length() - 2)
		
		result[key] = value
	
	return result


# ==============================================================================
# Session Cache
# ==============================================================================
func _save_session_cache() -> void:
	var cache_data := {
		"current_user_id": current_user_id,
		"id_token": id_token,
		"refresh_token": refresh_token,
		"user_email": user_email,
		"user_display_name": user_display_name,
		"auth_provider": auth_provider,
		"timestamp": Time.get_unix_time_from_system()
	}
	var file = FileAccess.open(AUTH_CACHE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(cache_data))
		file.close()


func _try_restore_cached_session() -> bool:
	if not FileAccess.file_exists(AUTH_CACHE_PATH):
		return false
	
	var file = FileAccess.open(AUTH_CACHE_PATH, FileAccess.READ)
	if not file:
		return false
	
	var json = JSON.parse_string(file.get_as_text())
	file.close()
	if not json is Dictionary:
		return false
	
	var cached_uid: String = json.get("current_user_id", "")
	var cached_token: String = json.get("id_token", "")
	var cached_refresh: String = json.get("refresh_token", "")
	
	if cached_uid.is_empty() or cached_token.is_empty():
		return false
	
	current_user_id = cached_uid
	id_token = cached_token
	refresh_token = cached_refresh
	user_email = json.get("user_email", "")
	user_display_name = json.get("user_display_name", "")
	auth_provider = json.get("auth_provider", "anonymous")
	is_authenticated = true
	
	print("[Firebase] Restored session for UID: %s (%s, %s)" % [current_user_id, auth_provider, user_email if not user_email.is_empty() else "guest"])
	
	# If we have a refresh token, proactively refresh id_token to ensure it's unexpired
	if not refresh_token.is_empty():
		refresh_auth_token()
	else:
		auth_completed.emit(true, current_user_id)
	
	return true


# ==============================================================================
# Authentication: Anonymous Guest
# ==============================================================================
func sign_in_anonymous(callback: Callable = Callable()) -> void:
	if api_key.is_empty():
		push_error("[Firebase] Cannot authenticate: Missing API Key.")
		if callback.is_valid():
			callback.call(false, "")
		return
	
	var url = AUTH_URL_BASE + api_key
	var headers = ["Content-Type: application/json"]
	var payload = JSON.stringify({"returnSecureToken": true})
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var success: bool = false
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json is Dictionary:
				current_user_id = json.get("localId", "")
				id_token = json.get("idToken", "")
				refresh_token = json.get("refreshToken", "")
				user_email = ""
				user_display_name = "Guest"
				auth_provider = "anonymous"
				is_authenticated = true
				success = true
				_save_session_cache()
				print("[Firebase] Authenticated as guest UID: ", current_user_id)
		else:
			push_error("[Firebase] Anonymous auth failed with HTTP code: %d" % response_code)
		
		auth_completed.emit(success, current_user_id)
		if callback.is_valid():
			callback.call(success, current_user_id)
		http.queue_free()
	)
	
	http.request(url, headers, HTTPClient.METHOD_POST, payload)


# ==============================================================================
# Authentication: Google Sign-in
# ==============================================================================
## Triggers Google Sign-in flow.
## - On Web: Uses JavaScript popup or Google Identity Services.
## - On Desktop: Launches browser to hosted OAuth gateway and listens on loopback server.
func sign_in_with_google(callback: Callable = Callable()) -> void:
	if api_key.is_empty():
		push_error("[Firebase] Cannot sign in with Google: Missing API Key.")
		if callback.is_valid():
			callback.call(false, "", "")
		return
	
	# Web platform: communicate directly with browser / JS bridge
	if OS.has_feature("web") and Engine.has_singleton("JavaScriptBridge"):
		var js_bridge = Engine.get_singleton("JavaScriptBridge")
		# Call web sign-in helper
		var js_code = """
			if (typeof window.handleGoogleSignIn === 'function') {
				window.handleGoogleSignIn();
			} else {
				window.open('https://%s.web.app/', 'firebase_auth', 'width=500,height=650');
			}
		""" % hosting_site
		js_bridge.eval(js_code)
		if callback.is_valid():
			_loopback_callback = callback
		return
	
	# Desktop platforms (macOS / Windows / Linux):
	_start_desktop_oauth_flow(callback)


func _start_desktop_oauth_flow(callback: Callable) -> void:
	_stop_loopback_server()
	_loopback_callback = callback
	
	_loopback_server = TCPServer.new()
	_loopback_port = 8080
	var err = _loopback_server.listen(_loopback_port, "127.0.0.1")
	if err != OK:
		# Try alternate port 8081 if 8080 is occupied
		_loopback_port = 8081
		err = _loopback_server.listen(_loopback_port, "127.0.0.1")
	
	if err != OK:
		push_error("[Firebase] Failed to start local loopback server for Google Sign-in.")
		if callback.is_valid():
			callback.call(false, "", "")
		return
	
	_loopback_timeout = 180.0 # 3 minutes timeout
	var redirect_url = "http://127.0.0.1:%d" % _loopback_port
	var auth_url = "https://%s.web.app/?redirect=%s" % [hosting_site, redirect_url.uri_encode()]
	
	print("[Firebase] Starting Google Sign-in flow. Opening browser: ", auth_url)
	OS.shell_open(auth_url)


func _poll_loopback_server(delta: float) -> void:
	_loopback_timeout -= delta
	if _loopback_timeout <= 0.0:
		print("[Firebase] Google Sign-in loopback timed out.")
		_stop_loopback_server()
		if _loopback_callback.is_valid():
			_loopback_callback.call(false, "", "")
			_loopback_callback = Callable()
		return
	
	if _loopback_server.is_connection_available():
		var peer: StreamPeerTCP = _loopback_server.take_connection()
		if peer != null:
			_handle_loopback_request(peer)


func _handle_loopback_request(peer: StreamPeerTCP) -> void:
	# Give peer a moment to send data
	OS.delay_msec(50)
	var bytes = peer.get_available_bytes()
	if bytes <= 0:
		peer.disconnect_from_host()
		return
	
	var request_str = peer.get_utf8_string(bytes)
	# Extract GET line
	var first_line = request_str.get_slice("\r\n", 0)
	var parts = first_line.split(" ")
	if parts.size() < 2:
		peer.disconnect_from_host()
		return
	
	var path_and_query = parts[1]
	var query_start = path_and_query.find("?")
	var query_params: Dictionary = {}
	if query_start != -1:
		var query_str = path_and_query.substr(query_start + 1)
		for param in query_str.split("&"):
			var kv = param.split("=")
			if kv.size() == 2:
				query_params[kv[0].uri_decode()] = kv[1].uri_decode()
	
	# Send response page to browser
	var html_body = """<!DOCTYPE html>
<html>
<head><title>Echoes in the Ore - Sign In</title>
<style>
body { background: #070c11; color: #7bf0a4; font-family: monospace; display: flex; align-items: center; justify-content: center; height: 100vh; margin: 0; }
.box { border: 1px solid #3d6b75; padding: 28px; text-align: center; border-radius: 6px; }
h2 { color: #f8fafc; margin-top: 0; }
</style></head>
<body>
<div class="box">
<h2>[ SIGN-IN SUCCESSFUL ]</h2>
<p>Authentication linked to Echoes in the Ore.<br>You may now close this browser tab and return to the game.</p>
</div>
</body></html>"""
	
	var response = "HTTP/1.1 200 OK\r\nContent-Type: text/html; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [html_body.utf8().size(), html_body]
	peer.put_data(response.utf8())
	peer.disconnect_from_host()
	
	_stop_loopback_server()
	
	var extracted_id_token = query_params.get("id_token", "")
	var extracted_email = query_params.get("email", "")
	var extracted_name = query_params.get("displayName", "")
	
	if not extracted_id_token.is_empty():
		print("[Firebase] Captured Google ID Token from browser redirect. Authenticating with Firebase...")
		sign_in_with_google_id_token(extracted_id_token, _loopback_callback)
		_loopback_callback = Callable()
	else:
		push_warning("[Firebase] Loopback request did not contain id_token.")
		if _loopback_callback.is_valid():
			_loopback_callback.call(false, "", "")
			_loopback_callback = Callable()


func _stop_loopback_server() -> void:
	if _loopback_server != null:
		_loopback_server.stop()
		_loopback_server = null


## Authenticates with Firebase Identity Toolkit using a Google ID token.
## Links account if currently authenticated as anonymous.
func sign_in_with_google_id_token(google_id_token: String, callback: Callable = Callable()) -> void:
	if api_key.is_empty():
		push_error("[Firebase] Missing API Key.")
		if callback.is_valid():
			callback.call(false, "", "")
		return
	
	var url = AUTH_SIGN_IN_WITH_IDP_URL + api_key
	var headers = ["Content-Type: application/json"]
	
	var payload_dict := {
		"postBody": "id_token=" + google_id_token + "&providerId=google.com",
		"requestUri": "https://" + auth_domain,
		"returnIdpCredential": true,
		"returnSecureToken": true
	}
	
	# If already logged in as guest, link account to retain save data
	if is_authenticated and auth_provider == "anonymous" and not id_token.is_empty():
		payload_dict["idToken"] = id_token
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var success: bool = false
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json is Dictionary:
				current_user_id = json.get("localId", "")
				id_token = json.get("idToken", "")
				refresh_token = json.get("refreshToken", refresh_token)
				user_email = json.get("email", "")
				user_display_name = json.get("displayName", "Google Pilot")
				auth_provider = "google.com"
				is_authenticated = true
				success = true
				_save_session_cache()
				print("[Firebase] Google Sign-in successful! User UID: %s (%s)" % [current_user_id, user_email])
		else:
			var err_body = body.get_string_from_utf8()
			push_error("[Firebase] Google IDP sign-in failed (HTTP %d): %s" % [response_code, err_body])
		
		auth_completed.emit(success, current_user_id)
		google_sign_in_completed.emit(success, current_user_id, user_email)
		if callback.is_valid():
			callback.call(success, current_user_id, user_email)
		http.queue_free()
	)
	
	http.request(url, headers, HTTPClient.METHOD_POST, JSON.stringify(payload_dict))


## Refreshes the short-lived Firebase ID Token using the long-lived refresh token
func refresh_auth_token(callback: Callable = Callable()) -> void:
	if refresh_token.is_empty() or api_key.is_empty():
		if callback.is_valid():
			callback.call(false)
		return
	
	var url = SECURE_TOKEN_URL + api_key
	var headers = ["Content-Type: application/x-www-form-urlencoded"]
	var body_data = "grant_type=refresh_token&refresh_token=" + refresh_token.uri_encode()
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		var success: bool = false
		if response_code == 200:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json is Dictionary:
				id_token = json.get("id_token", id_token)
				refresh_token = json.get("refresh_token", refresh_token)
				current_user_id = json.get("user_id", current_user_id)
				is_authenticated = true
				success = true
				_save_session_cache()
				print("[Firebase] Token refreshed successfully.")
		else:
			push_warning("[Firebase] Token refresh failed with code: %d" % response_code)
		
		if callback.is_valid():
			callback.call(success)
		http.queue_free()
	)
	
	http.request(url, headers, HTTPClient.METHOD_POST, body_data)


## Sign out the current user and reset to a clean guest state
func sign_out() -> void:
	_stop_loopback_server()
	current_user_id = ""
	id_token = ""
	refresh_token = ""
	user_email = ""
	user_display_name = ""
	auth_provider = ""
	is_authenticated = false
	
	if FileAccess.file_exists(AUTH_CACHE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(AUTH_CACHE_PATH))
	
	signed_out.emit()
	print("[Firebase] Signed out.")
	
	# Re-init guest anonymous session
	sign_in_anonymous()


# ==============================================================================
# Cloud Firestore Operations (Save / Load)
# ==============================================================================
## Saves or updates a document in a collection.
## E.g., save_document("saves", current_user_id, {...})
func save_document(collection: String, document_id: String, data: Dictionary, callback: Callable = Callable()) -> void:
	if not _ensure_ready_for_firestore(callback):
		return
	
	var url = (FIRESTORE_API_BASE % project_id) + "%s/%s" % [collection, document_id]
	var headers = [
		"Content-Type: application/json",
		"Authorization: Bearer " + id_token
	]
	
	var firestore_body = {
		"fields": _dict_to_firestore_fields(data)
	}
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		# If token expired (401), try refreshing token once and retrying
		if response_code == 401 and not refresh_token.is_empty():
			http.queue_free()
			refresh_auth_token(func(refreshed: bool):
				if refreshed:
					save_document(collection, document_id, data, callback)
				else:
					save_completed.emit(false, "Authentication expired")
					if callback.is_valid(): callback.call(false, "Authentication expired")
			)
			return
		
		var success: bool = (response_code == 200)
		var err_msg: String = ""
		if not success:
			err_msg = "HTTP %d: %s" % [response_code, body.get_string_from_utf8()]
			push_error("[Firebase] Firestore save failed: " + err_msg)
		else:
			print("[Firebase] Document successfully saved to %s/%s" % [collection, document_id])
		
		save_completed.emit(success, err_msg)
		if callback.is_valid():
			callback.call(success, err_msg)
		http.queue_free()
	)
	
	http.request(url, headers, HTTPClient.METHOD_PATCH, JSON.stringify(firestore_body))


## Loads a document from a collection.
## E.g., load_document("saves", current_user_id)
func load_document(collection: String, document_id: String, callback: Callable = Callable()) -> void:
	if not _ensure_ready_for_firestore(callback):
		return
	
	var url = (FIRESTORE_API_BASE % project_id) + "%s/%s" % [collection, document_id]
	var headers = [
		"Authorization: Bearer " + id_token
	]
	
	var http = HTTPRequest.new()
	add_child(http)
	
	http.request_completed.connect(func(_result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray):
		# If token expired (401), try refreshing token once and retrying
		if response_code == 401 and not refresh_token.is_empty():
			http.queue_free()
			refresh_auth_token(func(refreshed: bool):
				if refreshed:
					load_document(collection, document_id, callback)
				else:
					load_completed.emit(false, {})
					if callback.is_valid(): callback.call(false, {})
			)
			return
		
		var success: bool = (response_code == 200)
		var result_data: Dictionary = {}
		
		if success:
			var json = JSON.parse_string(body.get_string_from_utf8())
			if json is Dictionary and json.has("fields"):
				result_data = _firestore_fields_to_dict(json["fields"])
				print("[Firebase] Document loaded from %s/%s" % [collection, document_id])
		else:
			push_warning("[Firebase] Load failed or document not found (HTTP %d)" % response_code)
		
		load_completed.emit(success, result_data)
		if callback.is_valid():
			callback.call(success, result_data)
		http.queue_free()
	)
	
	http.request(url, headers, HTTPClient.METHOD_GET)


## Convenience function to save the current player's campaign/story state to Firestore
func save_player_game(data: Dictionary, callback: Callable = Callable()) -> void:
	if current_user_id.is_empty():
		push_warning("[Firebase] Cannot save player game: No current user ID.")
		if callback.is_valid():
			callback.call(false, "No user ID")
		return
	
	var enhanced_data = data.duplicate(true)
	enhanced_data["last_saved_at"] = Time.get_datetime_string_from_system(true)
	enhanced_data["auth_provider"] = auth_provider
	if not user_email.is_empty():
		enhanced_data["user_email"] = user_email
	
	save_document("saves", current_user_id, enhanced_data, callback)


## Convenience function to load the current player's campaign/story state from Firestore
func load_player_game(callback: Callable = Callable()) -> void:
	if current_user_id.is_empty():
		push_warning("[Firebase] Cannot load player game: No current user ID.")
		if callback.is_valid():
			callback.call(false, {})
		return
	
	load_document("saves", current_user_id, callback)


func _ensure_ready_for_firestore(callback: Callable) -> bool:
	if project_id.is_empty():
		push_error("[Firebase] Project ID is missing.")
		if callback.is_valid():
			callback.call(false, "Project ID missing")
		return false
	if current_user_id.is_empty() or id_token.is_empty():
		push_warning("[Firebase] Not authenticated yet. Please wait for auth_completed.")
		if callback.is_valid():
			callback.call(false, "Not authenticated")
		return false
	return true


# ==============================================================================
# Type Conversions (GDScript Dictionary <-> Firestore REST JSON Format)
# ==============================================================================
func _dict_to_firestore_fields(dict: Dictionary) -> Dictionary:
	var fields: Dictionary = {}
	for key in dict:
		fields[key] = _value_to_firestore(dict[key])
	return fields


func _value_to_firestore(val: Variant) -> Dictionary:
	match typeof(val):
		TYPE_STRING, TYPE_STRING_NAME:
			return {"stringValue": str(val)}
		TYPE_INT:
			return {"integerValue": str(val)}
		TYPE_FLOAT:
			return {"doubleValue": float(val)}
		TYPE_BOOL:
			return {"booleanValue": bool(val)}
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY, TYPE_PACKED_INT64_ARRAY, TYPE_PACKED_FLOAT32_ARRAY, TYPE_PACKED_FLOAT64_ARRAY:
			var arr: Array = []
			for item in val:
				arr.append(_value_to_firestore(item))
			return {"arrayValue": {"values": arr}}
		TYPE_DICTIONARY:
			return {"mapValue": {"fields": _dict_to_firestore_fields(val)}}
		TYPE_NIL:
			return {"nullValue": null}
		_:
			return {"stringValue": str(val)}


func _firestore_fields_to_dict(fields: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for key in fields:
		result[key] = _firestore_value_to_variant(fields[key])
	return result


func _firestore_value_to_variant(field: Dictionary) -> Variant:
	if field.has("stringValue"):
		return field["stringValue"]
	elif field.has("doubleValue"):
		return float(field["doubleValue"])
	elif field.has("integerValue"):
		return int(field["integerValue"])
	elif field.has("booleanValue"):
		return bool(field["booleanValue"])
	elif field.has("arrayValue"):
		var list: Array = []
		var values = field["arrayValue"].get("values", [])
		for item in values:
			if item is Dictionary:
				list.append(_firestore_value_to_variant(item))
		return list
	elif field.has("mapValue"):
		var sub_fields = field["mapValue"].get("fields", {})
		return _firestore_fields_to_dict(sub_fields)
	elif field.has("nullValue"):
		return null
	return null
