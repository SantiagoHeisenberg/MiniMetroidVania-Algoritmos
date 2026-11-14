# Metroidvania en 3 Salas

Un mini metroidvania hecho en **Godot 4.6.1** en pocas horas. Todo (salas, jugador, enemigos, jefe e interfaz) se genera por código con rectángulos de colores, así que el proyecto es pequeño y fácil de leer.

> *Aquí va una captura o GIF del juego*
![Sala de inicio](docs/captura1.png)
## La idea

Lo que hace a un metroidvania un metroidvania: **una habilidad que abre el camino**.

| Sala | Qué pasa |
|------|----------|
| 1 · Inicio | Aprendes a moverte y saltar. Sobre una plataforma hay una gema dorada que te da el **doble salto**. |
| 2 · Obstáculo | Un muro demasiado alto para un salto normal, con 2 enemigos patrullando. Solo se pasa con el doble salto. |
| 3 · Jefe | Un jefe de 5 vidas que patrulla, parpadea para avisar y luego **embiste**. Derrótalo para ganar. |

Puedes volver a las salas anteriores; los enemigos derrotados se quedan derrotados.

## Controles

| Acción | Teclas |
|--------|--------|
| Mover | `A` / `D` o flechas |
| Saltar (y doble salto) | `W`, `Espacio` o flecha arriba |
| Atacar | `J`, `X` o `K` |
| Reiniciar | `R` |

## Cómo ejecutarlo

1. Instala [Godot 4.6.x](https://godotengine.org/download) (versión estándar, no .NET).
2. Clona este repositorio:
   ```bash
   git clone https://github.com/TU_USUARIO/metroidvania-3-salas.git
   ```
3. Abre Godot → **Import** → selecciona `project.godot`.
4. Pulsa **F5** (Play).

## Estructura

```
project.godot
scenes/main.tscn     # escena principal (solo un Node2D con game.gd)
scripts/game.gd      # salas, interfaz, gema, transiciones, victoria/derrota
scripts/player.gd    # movimiento, doble salto, ataque, vida
scripts/enemy.gd     # enemigo patrullero + jefe (is_boss = true)
```

## Cómo funciona (resumen técnico)

- **Salas por código:** `game.gd` construye cada sala con `StaticBody2D` + `ColorRect`, sin TileMaps ni escenas extra.
- **Habilidad:** el doble salto es un contador de saltos (`jumps_used`) que permite 2 en lugar de 1 al obtener la gema.
- **Combate:** el ataque y el contacto con enemigos se resuelven comparando rectángulos (`Rect2.intersects`), sin señales ni capas complicadas.
- **Jefe:** máquina de estados simple: `patrol → telegraph → charge → rest`.
- **Persistencia entre salas:** un diccionario `killed` recuerda qué enemigos murieron.

## Ideas para seguir

- Sprites y animaciones.
- Más habilidades (dash, pared) y más salas.
- Mapa, checkpoints, sonido y música.

## Licencia

MIT License
