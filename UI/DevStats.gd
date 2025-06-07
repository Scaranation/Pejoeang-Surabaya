extends Control

@onready var fps_label: Label = $FPSLabel
@onready var memory_label: Label = $MemoryLabel
@onready var vram_label: Label = $VRAMLabel
@onready var os_label: Label = $OSLabel

func _process(_delta: float) -> void:
	# FPS Counter
	fps_label.text = "FPS: " + str(Engine.get_frames_per_second())

	# Memory Usage (RAM) in MB
	var memory_usage = OS.get_static_memory_usage() / (1024 * 1024)
	memory_label.text = "RAM Usage: " + str(memory_usage) + " MB"

	# VRAM Usage (GPU Memory) in MB
	var vram_usage = RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / (1024 * 1024)
	vram_label.text = "VRAM Usage: " + str(vram_usage) + " MB"
