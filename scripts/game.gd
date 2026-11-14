extends Node2D
## Controla el juego completo: construye las 3 salas por código, la interfaz,
## la gema de doble salto, las transiciones entre salas y la victoria / derrota.
##
## Salas:  0 = inicio (gema)  ->  1 = obstáculo (muro alto + 2 enemigos)  ->  2 = jefe

const W := 1152.0
const H := 648.0
const FLOOR_Y := 560.0

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")

const ROOM_COLORS := [
	Color(0.10, 0.12, 0.18),
	Color(0.14, 0.10, 0.17),
	Color(0.20, 0.08, 0.08),
]
const FLOOR_COLOR := Color(0.25, 0.27, 0.33)
const WALL_COLOR := Color(0.38, 0.40, 0.48)

var room_idx := 0
var room: Node2D
var player
var boss
var pickup: ColorRect

var has_ability := false
var killed := {} # enemigos derrotados (se recuerdan al cambiar de sala)
var ended := false

var hud_label: Label
var hint_label: Label
var boss_label: Label
var msg_label: Label
var toast_label: Label


func _ready() -> void:
	_build_ui()
	player = PlayerScript.new()
	add_child(player)
	player.hp_changed.connect(_update_hud)
	player.died.connect(_on_player_died)
	_load_room(0, 80.0, 530.0)
	_update_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_R:
		get_tree().reload_current_scene()


func _physics_process(_delta: float) -> void:
	# Recoger la gema de doble salto
	if pickup != null and player.hitbox().intersects(Rect2(pickup.position, pickup.size)):
		has_ability = true
		player.has_double_jump = true
		pickup.queue_free()
		pickup = null
		_update_hud()
		_toast("¡Obtuviste el DOBLE SALTO! Pulsa salto otra vez en el aire.")

	# Cambiar de sala por los bordes de la pantalla
	if player.position.x > W and room_idx < 2:
		_load_room(room_idx + 1, 30.0, player.position.y)
	elif player.position.x < 0.0 and room_idx > 0:
		_load_room(room_idx - 1, W - 30.0, player.position.y)


# ---------------------------------------------------------------- Salas

func _load_room(idx: int, spawn_x: float, spawn_y: float) -> void:
	if room != null:
		remove_child(room)
		room.queue_free()
	room_idx = idx
	pickup = null
	boss = null
	boss_label.text = ""

	room = Node2D.new()
	add_child(room)
	move_child(room, 0) # la sala se dibuja detrás del jugador
	RenderingServer.set_default_clear_color(ROOM_COLORS[idx])

	match idx:
		0:
			_build_start_room()
		1:
			_build_obstacle_room()
		2:
			_build_boss_room()

	player.position = Vector2(spawn_x, spawn_y)
	_update_hint()


func _build_start_room() -> void:
	_block(Rect2(0, FLOOR_Y, W, H - FLOOR_Y), FLOOR_COLOR)
	_block(Rect2(-40, 0, 40, H), WALL_COLOR) # pared izquierda
	_block(Rect2(840, 490, 160, 20), WALL_COLOR) # plataforma de la gema
	if not has_ability:
		pickup = ColorRect.new()
		pickup.color = Color(1.0, 0.85, 0.2)
		pickup.size = Vector2(24, 24)
		pickup.position = Vector2(908, 462)
		room.add_child(pickup)


func _build_obstacle_room() -> void:
	_block(Rect2(0, FLOOR_Y, W, H - FLOOR_Y), FLOOR_COLOR)
	_block(Rect2(560, 410, 40, 150), WALL_COLOR) # muro: solo se pasa con doble salto
	_spawn_enemy("r1a", 300.0, 120.0, 520.0)
	_spawn_enemy("r1b", 820.0, 650.0, 1090.0)


func _build_boss_room() -> void:
	_block(Rect2(0, FLOOR_Y, W, H - FLOOR_Y), FLOOR_COLOR)
	_block(Rect2(W, 0, 40, H), WALL_COLOR) # pared derecha
	if killed.has("boss"):
		return
	var b = EnemyScript.new()
	b.max_hp = 5
	b.speed = 110.0
	b.size = Vector2(70, 80)
	b.color = Color(0.75, 0.15, 0.55)
	b.is_boss = true
	b.min_x = 60.0
	b.max_x = W - 60.0
	b.position = Vector2(820.0, FLOOR_Y - 41.0)
	b.died.connect(_on_enemy_died.bind("boss"))
	b.hp_changed.connect(_on_boss_hp)
	room.add_child(b)
	boss = b
	boss_label.text = "Jefe: %d" % b.max_hp


func _spawn_enemy(key: String, x: float, min_x: float, max_x: float) -> void:
	if killed.has(key):
		return
	var e = EnemyScript.new()
	e.position = Vector2(x, FLOOR_Y - 20.0)
	e.min_x = min_x
	e.max_x = max_x
	e.died.connect(_on_enemy_died.bind(key))
	room.add_child(e)


func _block(r: Rect2, color: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.position = r.position + r.size / 2.0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = r.size
	cs.shape = shape
	body.add_child(cs)
	var cr := ColorRect.new()
	cr.color = color
	cr.size = r.size
	cr.position = -r.size / 2.0
	body.add_child(cr)
	room.add_child(body)


# ---------------------------------------------------------------- Eventos

func _on_enemy_died(key: String) -> void:
	killed[key] = true
	if key == "boss":
		boss_label.text = "Jefe: 0"
		_win()


func _on_boss_hp(hp: int) -> void:
	boss_label.text = "Jefe: %d" % maxi(hp, 0)


func _on_player_died() -> void:
	ended = true
	msg_label.text = "GAME OVER\nPulsa R para reiniciar"


func _win() -> void:
	ended = true
	msg_label.text = "¡VICTORIA!\nDerrotaste al jefe\nPulsa R para jugar de nuevo"


# ---------------------------------------------------------------- Interfaz

func _build_ui() -> void:
	var ui := CanvasLayer.new()
	ui.layer = 10
	add_child(ui)

	hud_label = _make_label(ui, Vector2(16, 10), 22)
	boss_label = _make_label(ui, Vector2(W - 200.0, 10), 22)
	hint_label = _make_label(ui, Vector2(16, H - 70.0), 20)
	toast_label = _make_label(ui, Vector2(16, 80), 22)

	msg_label = _make_label(ui, Vector2.ZERO, 44)
	msg_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	msg_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	msg_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _make_label(parent: Node, pos: Vector2, font_size: int) -> Label:
	var l := Label.new()
	l.position = pos
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 6)
	parent.add_child(l)
	return l


func _update_hud(_hp: int = 0) -> void:
	var skill := "SÍ" if has_ability else "no"
	hud_label.text = "Vida: %d/%d    Doble salto: %s" % [maxi(player.hp, 0), player.max_hp, skill]


func _update_hint() -> void:
	match room_idx:
		0:
			if has_ability:
				hint_label.text = "Ya tienes el doble salto. Sigue hacia la derecha →"
			else:
				hint_label.text = "A/D o flechas: mover   W/Espacio: saltar   J: atacar   R: reiniciar\nSube a la plataforma y toma la gema dorada →"
		1:
			if has_ability:
				hint_label.text = "Ese muro es alto... pero ahora puedes saltar dos veces."
			else:
				hint_label.text = "Un muro demasiado alto. Quizás te falta algo de la sala anterior..."
		2:
			hint_label.text = "¡Derrota al jefe! Cuidado cuando parpadee: va a embestir."


func _toast(text: String) -> void:
	toast_label.text = text
	await get_tree().create_timer(3.0).timeout
	if toast_label.text == text:
		toast_label.text = ""
