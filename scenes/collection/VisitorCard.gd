extends PanelContainer

## Single card in the Visitors shelf. Shows collected state or silhouette.

@onready var _sprite: TextureRect = $VBox/Sprite
@onready var _name_label: Label = $VBox/NameLabel
@onready var _bio_label: Label = $VBox/BioLabel
@onready var _silhouette_overlay: ColorRect = $VBox/Sprite/SilhouetteOverlay


func setup(visitor: Dictionary, is_collected: bool) -> void:
	if is_collected:
		var tex := load(visitor.get("sprite", ""))
		if tex:
			_sprite.texture = tex
		_silhouette_overlay.visible = false
		_name_label.text = visitor.get("name", "???")
		_bio_label.text = visitor.get("bio", "")
		_bio_label.visible = true
	else:
		# Silhouette — texture still loads but overlay blacks it out
		var tex := load(visitor.get("sprite", ""))
		if tex:
			_sprite.texture = tex
		_silhouette_overlay.visible = true
		_name_label.text = "???"
		_bio_label.visible = false
