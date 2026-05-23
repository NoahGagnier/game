class_name CutsceneSlide
extends Resource

# One slide in the cutscene. Set these in the Inspector on the Cutscene node.

# The image to display. For animated slides this is the spritesheet.
@export var texture: Texture2D

# Set to true if this slide is animated (spritesheet).
@export var is_animated: bool = false

# --- Animated slide settings (ignored if is_animated = false) ---
# Number of frames in the spritesheet (laid out horizontally).
@export var frame_count: int = 1
# Frames per second for the animation.
@export var fps: float = 8.0

# How long this slide stays on screen (seconds). For animated slides this
# should be long enough to show the full animation, or set it to
# (frame_count / fps) to play exactly once.
@export var duration: float = 3.0

# If true, fades to black before the next slide. If false, cuts instantly.
@export var fade_out: bool = true

# Text that types out while this slide is shown. Leave empty for no text.
@export_multiline var text: String = ""
