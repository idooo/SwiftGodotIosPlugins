extends Control

@onready var status_label: Label = $MarginContainer/VBoxContainer/StatusLabel
@onready var token_label: Label = $MarginContainer/VBoxContainer/TokenLabel

# Push notification option flags (bitmask)
const PUSH_ALERT = 1
const PUSH_BADGE = 2
const PUSH_SOUND = 4
const PUSH_PROVISIONAL = 8

var _push: PushNotifications


func _ready() -> void:
	if _push == null && ClassDB.class_exists("PushNotifications"):
		_push = ClassDB.instantiate("PushNotifications")
		_push.device_token_received.connect(_on_device_token_received)
		_push.device_token_updated.connect(_on_device_token_updated)
		_push.registration_error.connect(_on_registration_error)
		_push.authorization_result.connect(_on_authorization_result)
		status_label.text = "Plugin loaded"
	else:
		status_label.text = "PushNotifications plugin not available"


func _on_register_button_pressed() -> void:
	if _push:
		_push.registerPushNotifications(PUSH_ALERT | PUSH_BADGE | PUSH_SOUND)
		status_label.text = "Requesting authorization..."


func _on_set_badge_button_pressed() -> void:
	if _push:
		_push.setBadgeNumber(5)
		status_label.text = "Badge set to 5"


func _on_clear_badge_button_pressed() -> void:
	if _push:
		_push.setBadgeNumber(0)
		status_label.text = "Badge cleared"


func _on_get_badge_button_pressed() -> void:
	if _push:
		var badge = _push.getBadgeNumber()
		status_label.text = "Current badge: %d" % badge


func _on_device_token_received(token: String) -> void:
	status_label.text = "Device token received"
	token_label.text = "Token: %s" % token
	print("APN Device Token: " + token)


func _on_device_token_updated(token: String) -> void:
	print("APN Device Token Updated: " + token)


func _on_registration_error(error_code: int, message: String) -> void:
	status_label.text = "Error (%d): %s" % [error_code, message]


func _on_authorization_result(result: String) -> void:
	if result == "granted":
		status_label.text = "Authorization granted, registering..."
	else:
		status_label.text = "Authorization denied by user"
