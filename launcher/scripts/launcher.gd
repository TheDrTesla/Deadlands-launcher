extends Control
## The launcher window: the player picks a game, and the launcher checks it for
## updates, shows its patch notes, and starts it.

const PANEL := Color("#1f1b17")
const BORDER := Color("#3d342b")
const TEXT := Color("#ece0cb")
const MUTED := Color("#8f8574")
const GOOD := Color("#9bd13c")
const BAD := Color("#e0503c")
const SETTINGS_PATH := "user://launcher.json"

## How each game in Updater.GAMES looks in the launcher
const LOOKS := {
	"the-deadlands": {
		"accent": Color("#c8642a"),
		"bg": Color("#0e0d0c"),
		"sky": Color("#3a1f14"),
		"glow": Color(0.7, 0.2, 0.1, 0.04),
		"sun": Color(0.75, 0.3, 0.15, 0.45),
		"skyline": true,
		"waiting": "Checking for news from the Deadlands...",
	},
	"ctrl-alt-salvage": {
		"accent": Color("#e07a2f"),
		"bg": Color("#14120f"),
		"sky": Color("#2e1d12"),
		"glow": Color(0.9, 0.45, 0.15, 0.04),
		"sun": Color(0.95, 0.6, 0.3, 0.4),
		"skyline": false,
		"waiting": "Checking for news from the Dead Zone...",
	},
	"lucky-pinball": {
		"accent": Color("#ffc53d"),
		"bg": Color("#0b0814"),
		"sky": Color("#2a1238"),
		"glow": Color(0.9, 0.3, 0.8, 0.04),
		"sun": Color(1.0, 0.75, 0.25, 0.4),
		"skyline": false,
		"waiting": "Polishing the flippers...",
	},
}

var updater: Updater                  # the selected game's
var _updaters: Dictionary = {}        # game id -> Updater
var _game := ""
var _look: Dictionary
var _title: Label
var _game_buttons: Dictionary = {}    # game id -> Button
var _status: Label
var _bar: ProgressBar
var _play: Button
var _repair: Button
var _notes: RichTextLabel
var _version: Label
var _banner: Button
var _busy := false
var _indeterminate := false
var _t := 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	draw.connect(_draw_bg)

	var m := MarginContainer.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for s in ["left", "right", "top", "bottom"]:
		m.add_theme_constant_override("margin_" + s, 28)
	add_child(m)
	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 14)
	m.add_child(root)

	var head := HBoxContainer.new()
	root.add_child(head)
	var titles := VBoxContainer.new()
	titles.add_theme_constant_override("separation", -4)
	titles.add_child(_label("TESLA GAMES LAUNCHER", 14, MUTED))
	_title = _label("", 40, TEXT)
	titles.add_child(_title)
	head.add_child(titles)
	var sp := Control.new()
	sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(sp)
	_version = _label("", 14, MUTED)
	_version.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_version.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	head.add_child(_version)

	var picker := HBoxContainer.new()
	picker.add_theme_constant_override("separation", 8)
	root.add_child(picker)
	var group := ButtonGroup.new()
	for id in Updater.GAMES:
		var b := Button.new()
		b.text = Updater.GAMES[id]["title"]
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(170, 40)
		b.pressed.connect(_select_game.bind(id))
		picker.add_child(b)
		_game_buttons[id] = b

	_banner = Button.new()
	_banner.visible = false
	_banner.pressed.connect(func(): OS.shell_open(str(updater.launcher_update.get("html_url", ""))))
	root.add_child(_banner)

	var notes_panel := PanelContainer.new()
	notes_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	root.add_child(notes_panel)
	var nv := VBoxContainer.new()
	notes_panel.add_child(nv)
	nv.add_child(_label("PATCH NOTES", 13, MUTED))
	_notes = RichTextLabel.new()
	_notes.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_notes.add_theme_color_override("default_color", TEXT)
	_notes.add_theme_font_size_override("normal_font_size", 15)
	nv.add_child(_notes)

	_status = _label("Starting...", 15, TEXT)
	root.add_child(_status)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 12)
	root.add_child(bottom)
	_bar = ProgressBar.new()
	_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_bar.custom_minimum_size.y = 14
	_bar.show_percentage = false
	_bar.max_value = 1.0
	bottom.add_child(_bar)
	_repair = Button.new()
	_repair.text = "Repair"
	_repair.tooltip_text = "Re-download and re-verify the game files"
	_repair.custom_minimum_size = Vector2(110, 52)
	_repair.pressed.connect(func(): _run_update(true))
	bottom.add_child(_repair)
	_play = Button.new()
	_play.text = "PLAY"
	_play.custom_minimum_size = Vector2(200, 52)
	_play.add_theme_font_size_override("font_size", 22)
	_play.pressed.connect(_on_play)
	bottom.add_child(_play)

	_select_game(_saved_game())

## Shows `id` and checks it for updates
func _select_game(id: String) -> void:
	if _busy or id == _game:
		_game_buttons[_game].button_pressed = true
		return
	_game = id
	_look = LOOKS[id]
	_game_buttons[id].button_pressed = true
	if not _updaters.has(id):
		var u := Updater.new(id)
		add_child(u)
		# Only the game on screen may change the status line and progress bar
		u.status.connect(func(t): if u == updater: _status.text = t)
		u.progress.connect(func(f): if u == updater: _on_progress(f))
		_updaters[id] = u
	updater = _updaters[id]
	theme = _make_theme()
	_title.text = str(Updater.GAMES[id]["title"]).to_upper()
	_title.add_theme_color_override("font_color", _look["accent"])
	_notes.text = _look["waiting"]
	_status.remove_theme_color_override("font_color")
	_banner.visible = false
	_save_game(id)
	_run_update(false)

func _saved_game() -> String:
	if FileAccess.file_exists(SETTINGS_PATH):
		var data = JSON.parse_string(FileAccess.get_file_as_string(SETTINGS_PATH))
		if typeof(data) == TYPE_DICTIONARY and Updater.GAMES.has(str(data.get("game", ""))):
			return data["game"]
	return Updater.GAMES.keys()[0]

func _save_game(id: String) -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"game": id}))

func _process(delta: float) -> void:
	_t += delta
	if _indeterminate:
		_bar.value = 0.5 + 0.5 * sin(_t * 4.0)
	queue_redraw()

func _on_progress(f: float) -> void:
	_indeterminate = f < 0.0
	if not _indeterminate:
		_bar.value = f

func _run_update(force: bool) -> void:
	if _busy:
		return
	_busy = true
	_play.disabled = true
	_repair.disabled = true
	_set_picker_disabled(true)
	var res: Dictionary = await updater.check_and_update(force)
	_busy = false
	_set_picker_disabled(false)
	_indeterminate = false
	_bar.value = 1.0 if res["ok"] else 0.0
	_status.text = res["message"]
	_status.add_theme_color_override("font_color", GOOD if res["ok"] else BAD)
	_play.disabled = not res["ok"]
	_repair.disabled = false
	var mine: String = ProjectSettings.get_setting("application/config/version")
	_version.text = "Game %s\nLauncher %s" % [updater.installed_version() if updater.installed_version() != "" else "—", mine]
	if updater.release_notes != "":
		_notes.text = updater.release_notes
	elif not res["ok"]:
		_notes.text = "Once a build is published it will be downloaded here automatically."
	else:
		_notes.text = "Patch notes are unavailable while offline."
	if not updater.launcher_update.is_empty():
		_banner.text = "A new launcher (%s) is available — click to download" % updater.launcher_update["tag_name"]
		_banner.visible = true

func _set_picker_disabled(disabled: bool) -> void:
	for id in _game_buttons:
		_game_buttons[id].disabled = disabled and id != _game

func _on_play() -> void:
	if not updater.installed_ok():
		_status.text = "Game files are damaged. Click Repair."
		_status.add_theme_color_override("font_color", BAD)
		return
	var pid := OS.create_process(updater.game_exe_path(), [])
	if pid <= 0:
		_status.text = "Could not start the game."
		return
	_status.text = "Launching..."
	await get_tree().create_timer(1.0).timeout
	get_tree().quit()

func _label(t: String, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _box(bg: Color, border: Color, w: int = 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(w)
	s.set_corner_radius_all(4)
	s.set_content_margin_all(12)
	return s

func _make_theme() -> Theme:
	var accent: Color = _look["accent"]
	var t := Theme.new()
	t.default_font_size = 16
	t.set_color("font_color", "Label", TEXT)
	t.set_stylebox("normal", "Button", _box(Color("#2a241e"), BORDER))
	t.set_stylebox("hover", "Button", _box(Color("#3a2f24"), accent))
	t.set_stylebox("pressed", "Button", _box(Color("#9e4f18"), accent))
	t.set_stylebox("disabled", "Button", _box(Color("#1a1714"), Color("#2a241e")))
	# The picked game's button stays pressed
	t.set_stylebox("hover_pressed", "Button", _box(Color("#9e4f18"), accent))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_color("font_color", "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color("#5c544a"))
	t.set_stylebox("panel", "PanelContainer", _box(Color(0.12, 0.105, 0.09, 0.88), BORDER))
	t.set_stylebox("background", "ProgressBar", _box(Color("#0d0c0a"), BORDER))
	var fill := _box(accent, accent, 0)
	fill.set_content_margin_all(0)
	t.set_stylebox("fill", "ProgressBar", fill)
	return t

func _draw_bg() -> void:
	var sz := size
	# Smoky sky under a dull sun (The Deadlands adds a ruined skyline)
	for i in 20:
		var f := float(i) / 20.0
		draw_rect(Rect2(0, sz.y * f, sz.x, sz.y / 20.0 + 1), Color(_look["sky"]).lerp(_look["bg"], f))
	var sun := Vector2(sz.x * 0.8, sz.y * 0.3)
	for i in range(5, 0, -1):
		draw_circle(sun, 26.0 * i, _look["glow"])
	draw_circle(sun, 28.0, _look["sun"])
	if not _look["skyline"]:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var x := 0.0
	while x < sz.x:
		var w := rng.randf_range(30, 90)
		var h := rng.randf_range(30, 140)
		draw_rect(Rect2(x, sz.y - h, w, h), Color("#140f0d", 0.8))
		x += w + rng.randf_range(0, 24)
