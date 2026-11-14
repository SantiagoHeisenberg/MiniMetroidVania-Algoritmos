extends CharacterBody2D
## Jugador: movimiento, salto (y doble salto al obtener la gema), ataque y vida.
## Todo se construye por código, así que no hace falta configurar nada en el editor.

signal hp_changed(hp: int)
signal died

const SPEED := 280.0
const JUMP_VELOCITY := -520.0
const GRAVITY := 1400.0
const SIZE := Vector2(28, 40)
const ATTACK_SIZE := Vector2(46, 30)

var max_hp := 5
var hp := 5
var dead := false
var has_double_jump := false

var facing := 1
var jumps_used := 0
var invuln := 0.0
var stun := 0.0
var attack_time := 0.0
var attack_cooldown := 0.0
var hit_enemies: Array = []

var jump_requested := false
var attack_requested := false

var body_rect: ColorRect
var eye_rect: ColorRect
var attack_rect: ColorRect


func _ready() -> void:
	add_to_group("player")
	collision_layer = 2 # el jugador vive en la capa 2
	collision_mask = 1  # y solo choca con el mundo (capa 1)

	var shape := RectangleShape2D.new()
	shape.size = SIZE
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	body_rect = ColorRect.new()
	body_rect.color = Color(0.30, 0.65, 1.0)
	body_rect.size = SIZE
	body_rect.position = -SIZE / 2.0
	add_child(body_rect)

	eye_rect = ColorRect.new()
	eye_rect.color = Color.WHITE
	eye_rect.size = Vector2(8, 8)
	add_child(eye_rect)

	attack_rect = ColorRect.new()
	attack_rect.color = Color(1.0, 1.0, 0.6, 0.8)
	attack_rect.size = ATTACK_SIZE
	attack_rect.visible = false
	add_child(attack_rect)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.physical_keycode:
			KEY_W, KEY_SPACE, KEY_UP:
				jump_requested = true
			KEY_J, KEY_X, KEY_K:
				attack_requested = true


func hitbox() -> Rect2:
	return Rect2(global_position - SIZE / 2.0, SIZE)


func attack_global_rect() -> Rect2:
	return Rect2(global_position + attack_rect.position, ATTACK_SIZE)


func take_damage(amount: int, from_dir: int) -> void:
	if invuln > 0.0 or dead:
		return
	hp -= amount
	invuln = 1.0
	stun = 0.2
	velocity = Vector2(from_dir * 320.0, -250.0)
	hp_changed.emit(hp)
	if hp <= 0:
		dead = true
		attack_rect.visible = false
		body_rect.color = Color(0.35, 0.35, 0.4)
		body_rect.modulate.a = 1.0
		died.emit()


func _physics_process(delta: float) -> void:
	if dead:
		return

	invuln = maxf(invuln - delta, 0.0)
	stun = maxf(stun - delta, 0.0)
	attack_cooldown = maxf(attack_cooldown - delta, 0.0)

	# --- Movimiento horizontal ---
	var axis := 0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		axis += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		axis -= 1

	if stun <= 0.0:
		velocity.x = axis * SPEED
		if axis != 0:
			facing = axis
	else:
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)

	# --- Gravedad y saltos ---
	velocity.y += GRAVITY * delta
	if is_on_floor():
		jumps_used = 0
	elif jumps_used == 0:
		jumps_used = 1 # caer de un borde cuenta como el primer salto

	if jump_requested and stun <= 0.0:
		var max_jumps := 2 if has_double_jump else 1
		if jumps_used < max_jumps:
			velocity.y = JUMP_VELOCITY
			jumps_used += 1
	jump_requested = false

	# --- Ataque ---
	if attack_requested and attack_cooldown <= 0.0:
		attack_time = 0.15
		attack_cooldown = 0.35
		hit_enemies.clear()
	attack_requested = false

	if attack_time > 0.0:
		attack_time -= delta
		attack_rect.visible = true
		var ox := SIZE.x / 2.0 if facing > 0 else -SIZE.x / 2.0 - ATTACK_SIZE.x
		attack_rect.position = Vector2(ox, -ATTACK_SIZE.y / 2.0)
		var area := attack_global_rect()
		for e in get_tree().get_nodes_in_group("enemies"):
			if e in hit_enemies:
				continue
			if area.intersects(e.hitbox()):
				hit_enemies.append(e)
				e.take_damage(1, facing)
	else:
		attack_rect.visible = false

	move_and_slide()

	# --- Visual ---
	eye_rect.position = Vector2(4.0 if facing > 0 else -12.0, -14.0)
	if invuln > 0.0 and int(invuln * 20.0) % 2 == 0:
		body_rect.modulate.a = 0.35
	else:
		body_rect.modulate.a = 1.0
