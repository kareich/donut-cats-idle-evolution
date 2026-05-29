# Sprint 5 — Integration Checklist

## Autoloads to add in project.godot

Add these three lines to the `[autoload]` section:

```ini
WeatherSystem="*res://scripts/visitor/WeatherSystem.gd"
VisitorManager="*res://scripts/visitor/VisitorManager.gd"
PushNotificationManager="*res://scripts/visitor/PushNotificationManager.gd"
```

Order matters — WeatherSystem must be before VisitorManager.

## ShopScene integration

In the shop scene file (`scenes/shop/ShopScene.tscn` or equivalent), add as a child:

```
[ext_resource type="PackedScene" path="res://scenes/visitor/ShopVisitorLayer.tscn"]
```

And instantiate it as a child node of ShopScene. No additional code needed in ShopScene.gd — all visitor logic is self-contained in ShopVisitorLayer.

## Collection Book integration

In `scenes/collection/CollectionBook.gd` (or the tab container managing shelves), add the Visitors tab:

```gdscript
const VISITOR_SHELF_SCENE = preload("res://scenes/collection/VisitorShelf.tscn")

# In _ready() or wherever tabs are set up:
var visitor_tab = VISITOR_SHELF_SCENE.instantiate()
tab_container.add_child(visitor_tab)
tab_container.set_tab_title(tab_container.get_child_count() - 1, "Visitors")
```

## Push notification opt-in

Prompt the player for push notification permission on first launch (after tutorial).
Call `PushNotificationManager.request_opt_in()` after `tutorial_shown_v1` save key is set.

Add a toggle in Settings: `PushNotificationManager.set_enabled(value)`.

## New save keys introduced

| Key | Type | Purpose |
|-----|------|---------|
| `visitor_next_spawn_utc` | int | Unix timestamp of next spawn |
| `visitor_active_id` | String | ID of currently active visitor |
| `visitor_active_expires_utc` | int | When current visitor's window ends |
| `visitor_collected_ids` | Array[String] | All collected visitor IDs |
| `visitor_paw_prints` | Array[Dict] | Active paw prints with expiry |
| `weather_next_rain_utc` | int | Next rain start time |
| `weather_rain_end_utc` | int | Rain end time |
| `push_notifications_enabled` | bool | Player opt-in state |
| `push_permission_asked` | bool | Whether OS permission was requested |

## Sprite assets needed

Place in `res://assets/sprites/visitors/`:
- `biscuit.png` — common golden cat
- `mochi.png` — common round cat  
- `pretzel.png` — common pretzel-shaped cat
- `cheddar.png` — common orange cat
- `cloudy.png` — rainy day cat (small umbrella)
- `vesper.png` — midnight tuxedo cat
- `paw_print.png` — paw print icon for PawPrint scene Icon node

## Animations needed per visitor

Each visitor sprite sheet should include these named animations in an AnimationPlayer or AnimatedSprite2D:
- `idle` — default looping
- `sniff_display_case` / `steal_donut_attempt` / `stare_judgmentally` / `knock_something_over` / `shake_off_rain` / `adjust_invisible_tie` — idle variant matching `idle_anim` field
- `nervous` — plays when countdown ≤ 10s
- `leave` — exit animation when timer expires
- `befriend` — plays on successful tap

If a named animation isn't present, VisitorCat.gd falls back to `idle`.
