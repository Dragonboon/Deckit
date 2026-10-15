# Recetas de integración · Deckit

[Inicio](GETTING_STARTED.md) · [Labs](EXAMPLES.md) · [API](REFERENCE.md)

Cada receta añade una mecánica concreta. El código usa las clases del plugin;
los SVG y las reglas de ejemplo viven en `examples/` y no son dependencias.
Abre el proyecto y pulsa **F6 en un lab** o **F5 para el índice**.

## 1. Crear una mano, robar y descartar

**Prueba:** lab 01 → Draw → Move selected → table → discard.

Este script completo puede añadirse a un `Control` vacío:

```gdscript
extends Control

var game := DeckitGameState.new()

func _ready() -> void:
    for id in [&"draw", &"hand", &"table", &"discard"]:
        game.register_zone(DeckitCardZone.new(id, &"player"))
    game.get_zone(&"draw").visibility = DeckitCardZone.Visibility.HIDDEN
    game.get_zone(&"hand").capacity = 5
    var definition := DeckitCardDefinition.new()
    definition.card_id = &"scout"
    definition.display_name = "Explorador"
    # Opcional: asigna front_texture y back_texture de tu propio proyecto.
    for index in range(8):
        var card := DeckitCardInstance.new(definition, StringName("scout-%d" % index))
        card.face_up = true
        game.get_zone(&"draw").add_card(card)
    draw_one()

func draw_one() -> bool:
    var card := game.get_zone(&"draw").peek_top()
    if card == null:
        return false
    return game.perform(DeckitCardAction.new(&"draw", &"hand", card.instance_id, &"player"))
```

Para descartar cambia origen/destino a `hand`/`discard`. **Una definición** puede
compartirse entre copias; cada copia necesita un `instance_id` distinto. La capacidad
se comprueba antes de mover: una mano llena conserva la carta en el mazo.

## 2. Drag and drop entre zonas y posición libre en mesa

**Prueba:** lab 01 → arrastra del mazo a mano, de mano a mesa y recoloca en mesa.
Suelta fuera de una zona o sobre una mano llena: la carta permanece donde estaba.

Añade estas vistas al `Control` de la receta anterior después de registrar las zonas:

```gdscript
var hand_view := DeckitZoneView.new()
hand_view.position = Vector2(20, 20)
hand_view.size = Vector2(300, 300)
hand_view.drag_enabled = true
hand_view.drop_enabled = true
hand_view.actor_id = &"player"
add_child(hand_view)
hand_view.bind(game, &"hand", &"player")

var table_view := DeckitZoneView.new()
table_view.free_layout = true     # Antes de add_child: elige superficie libre.
table_view.table_height = 300
table_view.position = Vector2(350, 20)
table_view.size = Vector2(650, 350)
table_view.drag_enabled = true
table_view.drop_enabled = true
table_view.actor_id = &"player"
add_child(table_view)
table_view.bind(game, &"table", &"player")
```

`drag_enabled` y `drop_enabled` están desactivados por defecto. Una transferencia
consulta `game.can_perform()` al pasar el ratón y vuelve a validar al soltar antes
de llamar a `game.perform()`. Las reglas deben comprobar sin modificar estado.

Mover dentro de una mesa libre cambia **solo coordenadas de presentación**, no el
orden de cartas, turnos ni recursos. Usa `card_position_changed(id, position)` para
guardar posiciones en tu capa UI. `card_positions` usa coordenadas locales a la
superficie bajo el título. `set_card_position(id, position)` limita a sus bordes y
sirve también para controles de teclado. Esta función no cambia de zona.

El payload `DeckitCardDrag` pertenece a un estado local y a una instancia concreta.
No es un mensaje de red ni un permiso. Para un juego remoto, envía una intención al
servidor y usa tu propia interacción hasta que este autorice el movimiento.

## 3. Cartas ocultas y alternativa al ratón

**Prueba:** lab 01 → observa el reverso del mazo → roba → voltea en mesa.

```gdscript
game.get_zone(&"hand").visibility = DeckitCardZone.Visibility.OWNER_ONLY
hand_view.set_viewer(&"player")  # Ve la mano del propietario.
hand_view.set_viewer(&"guest")   # Solo ve reversos.
```

`HIDDEN` siempre oculta; `OWNER_ONLY` revela al propietario identificado;
`PUBLIC` utiliza `card.face_up`. El preview de arrastre respeta lo que muestra
la vista de origen. La identidad del observador **no** autoriza movimientos:
para eso existe `actor_id` y las reglas del juego.

```gdscript
hand_view.card_requested.connect(func(zone: StringName, id: StringName) -> void:
    # Guarda la selección en tu controlador y habilita botones accesibles.
    var selected: Array[StringName] = [id]
    hand_view.set_selected_cards(selected)
)
```

Usa los mismos `DeckitCardAction` desde botones. En el lab, Tab y Enter/Espacio
seleccionan cartas; las flechas recolocan la carta seleccionada cuando tiene el
foco en la mesa. El drag es una comodidad, no el único mecanismo de interacción.
Ocultar imágenes no protege datos secretos: no transmitas definiciones privadas.

## 4. Condiciones, efectos y secuencias

**Prueba:** lab 02 → selecciona A y pulsa Conditional +1 charge; repite con C.
C carece del tag requerido y la acción falla sin añadir el contador.

```gdscript
var effect := DeckitCounterEffect.new()
effect.counter_key = &"charge"
effect.delta = 1
var target := DeckitCardTarget.new(&"hand", &"scout-0")
var action := DeckitEffectAction.new().configure(effect, target, &"player")
var condition := DeckitTagCondition.new()
condition.tag = "allowed"
action.conditions.append(condition)
var accepted := game.perform(action)
```

Añade `allowed` a `definition.tags` para permitirlo. `DeckitFaceEffect` sirve para
voltear; implementa `DeckitCardEffect` para habilidades específicas. Un target
incluye zona e ID: después de mover la carta debes construir el target de destino.

```gdscript
var sequence := DeckitActionSequence.new()
sequence.add_step(DeckitCardAction.new(&"hand", &"table", &"scout-0", &"player"))
sequence.add_step(DeckitEffectAction.new().configure(
    effect, DeckitCardTarget.new(&"table", &"scout-0"), &"player"))
sequence.execute(game)
# Consulta executed_count y failed_step; no hay rollback automático.
```

Para costes o restricciones de turno implementa `DeckitCardRule.allows()`. No
cobres recursos dentro de `allows()` ni `can_apply()`: se consultan durante el
hover. Ejecuta costes en una acción propia que valide y aplique tu operación.
El plugin no presupone cómo funciona el maná, combate o economía de tu juego.

## 5. Reaccionar a una carta que entra en juego

**Prueba:** lab 02 → resuelve una carta → Process reactions → aparece `arrival: 1`.

```gdscript
var queue := DeckitEventQueue.new()
queue.bind(game)
queue.register_responder(preload("res://examples/labs/sample_event_responder.gd").new())
# En tu propio juego copia/adapta ese responder fuera del plugin.
# Tras perform(), procesa explícitamente las notificaciones:
queue.drain()
```

El responder de ejemplo acepta `action.applied` cuando una carta entra en `table`
desde otra zona y devuelve una acción de contador. Comprueba también el origen:
el efecto generado publica otro evento y no debe volver a activar la misma regla.
Para animaciones paso a paso usa `resolve_next()`; `drain()` procesa varias.
Al desmontar el controlador llama a `queue.unbind()` si mantienes la cola viva.

## 6. Turnos y respuestas en pila

**Prueba:** lab 02 → Open → selecciona A y Stage → B y Stage → Pass dos veces → Resolve.
En LIFO sale B primero; Process reactions hace visible su consecuencia. Vuelve a
pasar con ambos jugadores antes de resolver A. C demuestra rechazo en resolución.

```gdscript
var turns := DeckitTurnManager.new()
turns.configure([&"one", &"two"], [&"begin", &"action", &"end"])
turns.start()
var window := DeckitPriorityWindow.new()
var gate := DeckitPriorityTurnGate.new()
gate.priority_window = window
turns.add_rule(gate)
window.open_from_turn(game, turns)
var actor := window.current_participant()
window.submit_action(actor, DeckitCardAction.new(&"hand", &"table", &"scout-0", actor))
window.pass_priority(window.current_participant())
window.pass_priority(window.current_participant())
window.resolve_next()
```

Proponer no mueve la carta ni reserva costes. La acción se valida al resolver:
puede quedar obsoleta y ser rechazada. El lab evita proponer dos veces la misma
carta como política de ejemplo. El plugin permite otras políticas.

`resolution_order` permite LIFO/FIFO. `cancel()` elimina propuestas pendientes,
no deshace resultados. Con la pila vacía, dos pases cierran la ventana; después
`turns.next_phase()` vuelve a estar permitido. Tu juego decide cuándo abrirla.

## 7. De una receta de mazo a cartas en juego

**Prueba:** lab 03 → Build runtime preview → añade demasiadas copias → Validate.
Corrige, guarda JSON y vuelve a cargarlo; Reset recipe restaura el ejemplo inicial.

```gdscript
var catalog := DeckitCardCatalog.new()
var definition := DeckitCardDefinition.new()
definition.card_id = &"scout"
definition.display_name = "Explorador"
catalog.add_card(definition)
var deck := DeckitDeckList.new()
deck.add(&"scout", 4)
var rules := DeckitDeckRules.new()
rules.minimum_cards = 4
rules.default_copy_limit = 4
var factory := DeckitDeckFactory.new()
var copies := factory.build(deck, catalog, &"main", &"player", "match-1", rules)
if not factory.last_errors.is_empty():
    push_warning("; ".join(factory.last_errors))
else:
    for card in copies:
        game.get_zone(&"draw").add_card(card)
```

Conserva el factory o asigna prefijos únicos entre partidas/factories. El JSON de
`DeckitDeckCodec` describe tipos y cantidades; no incluye posiciones, partida,
texturas ni progreso. Valida antes de materializar y usa `inspect_integrity()` para
comprobar IDs duplicados. La UI del constructor es opcional.

## Componentes clásicos

`DeckitCardHand`, `DeckitCardPile`, `DeckitPlayingCardUI` y `DeckitDraggable2D`
continúan disponibles. Son otra API visual, independiente de las zonas de estado.
No mezcles sus arrays con `DeckitGameState` esperando sincronización automática.
Los tres labs usan el modelo de estado para que las mismas acciones funcionen
con botones, arrastre y pruebas headless. Consulta [la referencia](REFERENCE.md)
si tu proyecto ya utiliza los componentes clásicos.
