extends SceneTree

var _timer: float = 0.0

func _init() -> void:
	print("--- BEGIN FIREBASE BACKEND VALIDATION TEST ---")


func _process(delta: float) -> bool:
	_timer += delta
	var fb = root.get_node_or_null("FirebaseManager")
	if fb == null and _timer < 1.0:
		return false
	
	assert(fb != null, "FirebaseManager autoload must exist in the scene tree!")
	print("[TEST] Firebase Manager found!")
	print("       Project ID: ", fb.project_id)
	print("       Auth Domain: ", fb.auth_domain)
	print("       Hosting Site: ", fb.hosting_site)
	assert(fb.project_id == "hackathon-c565e", "Project ID must be hackathon-c565e")
	assert(fb.auth_domain == "hackathon-c565e.firebaseapp.com", "Auth domain must match project")
	assert(fb.hosting_site == "echoesintheore", "Hosting site must be echoesintheore")
	assert(not fb.api_key.is_empty(), "API Key must not be empty")
	
	print("[TEST] Methods verified:")
	print("       - sign_in_with_google: ", fb.has_method("sign_in_with_google"))
	print("       - sign_in_with_google_id_token: ", fb.has_method("sign_in_with_google_id_token"))
	print("       - sign_in_anonymous: ", fb.has_method("sign_in_anonymous"))
	print("       - save_player_game: ", fb.has_method("save_player_game"))
	print("       - load_player_game: ", fb.has_method("load_player_game"))
	print("       - sign_out: ", fb.has_method("sign_out"))
	
	assert(fb.has_method("sign_in_with_google"))
	assert(fb.has_method("sign_in_with_google_id_token"))
	assert(fb.has_method("sign_in_anonymous"))
	assert(fb.has_method("save_player_game"))
	assert(fb.has_method("load_player_game"))
	assert(fb.has_method("sign_out"))
	
	print("--- FIREBASE VALIDATION PASSED! ---")
	quit(0)
	return true
