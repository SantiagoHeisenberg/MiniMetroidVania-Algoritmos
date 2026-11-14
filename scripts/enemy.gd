extends CharacterBody2D
## Enemigo patrullero. Con is_boss = true se convierte en el jefe:
## patrulla, avisa parpadeando (telegraph), embiste y descansa.

signal died
signal hp_changed(hp: int)

const GRAVITY := 1400.0

# Estas propiedades se asignan desde game.gd ANTES de añadir el nodo a la escena.
var max_hp := 3
var speed := 80.0
var size := Vector2(34, 34)
var color := Color(0.85, 0.25, 0.25)
var is_boss := false
var min_x := 0.0
var max_x := 1152.0

var hp := 3
var dir := -1
var flash := 0.0
var state := "patrol"
var state_time := 2.0
var charge_dir := 1
var body_rect: ColorRect


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	collision_layer = 4 # capa propia: no chocan con el jugador, solo con el mundo
	collision_mask = 1

	var shape := RectangleShape2D.new()
	shape.size = size
	var cs := CollisionShape2D.new()
	cs.shape = shape
	add_child(cs)

	body_rect = ColorRect.new()
	body_rect.size = size
	body_rect.position = -size / 2.0
	body_rect.color = color
	add_child(body_rect)


func hitbox() -> Rect2:
	return Rect2(global_position - size / 2.0, size)


func take_damage(amount: int, _from_dir: int) -> void:
	hp -= amount
	flash = 0.12
	hp_changed.emit(hp)
	if hp <= 0:
		remove_from_group("enemies")
		died.emit()
		queue_free()


func _physics_process(delta: float) -> void:
	velocity.y += GRAVITY * delta
	flash = maxf(flash - delta, 0.0)

	if is_boss:
		_boss_logic(delta)
	else:
		velocity.x = dir * speed

	move_and_slide()

	# Dar la vuelta al llegar a un muro o al límite de patrulla
	if not is_boss or state == "patrol":
		if is_on_wall():
			dir = -dir
		elif dir < 0 and position.x <= min_x:
			dir = 1
		elif dir > 0 and position.x >= max_x:
			dir = -1

	body_rect.color = _current_color()
	_touch_player()


func _boss_logic(delta: float) -> void:
	state_time -= delta
	match state:
		"patrol":
			velocity.x = dir * speed
			if state_time <= 0.0:
				state = "telegraph"
				state_time = 0.6
				var p = get_tree().get_first_node_in_group("player")
				if p:
					charge_dir = 1 if p.global_position.x > global_position.x else -1
		"telegraph":
			velocity.x = 0.0
			if state_time <= 0.0:
				state = "charge"
				state_time = 0.7
		"charge":
			velocity.x = charge_dir * 460.0
			if state_time <= 0.0 or is_on_wall():
				state = "rest"
				state_time = 0.8
		"rest":
			velocity.x = 0.0
			if state_time <= 0.0:
				state = "patrol"
				state_time = 2.0


func _current_color() -> Color:
	if flash > 0.0:
		return Color.WHITE
	if state == "telegraph" and int(state_time * 20.0) % 2 == 0:
		return Color(1.0, 0.85, 0.2)
	return color


func _touch_player() -> void:
	var p = get_tree().get_first_node_in_group("player")
	if p and not p.dead and hitbox().intersects(p.hitbox()):
		var dmg := 2 if (is_boss and state == "charge") else 1
		var from_dir := 1 if p.global_position.x > global_position.x else -1
		p.take_damage(dmg, from_dir)
