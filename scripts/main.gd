extends Node3D

# Lightweight 3D proof-of-concept for the requested optimization strategy.
# No external textures/models/audio: geometry is procedural and shared.

var plane: Node3D
var camera: Camera3D
var speed := 32.0
var heading := 0.0
var pitch := 0.0
var altitude := 120.0
var time_passed := 0.0

func _ready():
    _build_world()
    _build_plane()
    _build_camera()
    _build_ui()

func mat(c: Color) -> StandardMaterial3D:
    var m = StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.9
    return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color):
    var mi = MeshInstance3D.new()
    var bm = BoxMesh.new()
    bm.size = size
    mi.mesh = bm
    mi.material_override = mat(color)
    mi.position = pos
    parent.add_child(mi)
    return mi

func cyl(parent: Node3D, pos: Vector3, radius: float, height: float, color: Color):
    var mi = MeshInstance3D.new()
    var cm = CylinderMesh.new()
    cm.top_radius = radius
    cm.bottom_radius = radius
    cm.height = height
    mi.mesh = cm
    mi.material_override = mat(color)
    mi.position = pos
    parent.add_child(mi)
    return mi

func _build_world():
    var world = Node3D.new()
    world.name = "World"
    add_child(world)

    # One large simple ground plane: the main optimization test.
    var ground = MeshInstance3D.new()
    var pm = PlaneMesh.new()
    pm.size = Vector2(1800, 1800)
    ground.mesh = pm
    ground.material_override = mat(Color(0.78, 0.84, 0.88))
    world.add_child(ground)

    # Low-cost mountain masses. Real project would replace these with streamed LOD terrain.
    for i in range(10):
        var x = -650.0 + i * 145.0
        var z = -260.0 - (i % 3) * 110.0
        var h = 180.0 + (i % 4) * 35.0
        cyl(world, Vector3(x, h * 0.35, z), 130.0 + (i % 2) * 30.0, h, Color(0.42,0.47,0.50))

    # Shared road strips: very light geometry.
    box(world, Vector3(0, 0.8, 40), Vector3(1100, 1.6, 18), Color(0.12,0.12,0.13))
    box(world, Vector3(-260, 0.9, 130), Vector3(18, 1.8, 360), Color(0.12,0.12,0.13))
    box(world, Vector3(270, 0.9, -80), Vector3(18, 1.8, 330), Color(0.12,0.12,0.13))

    # Bridge.
    box(world, Vector3(0, 17, -120), Vector3(250, 10, 20), Color(0.28,0.29,0.30))
    for x in [-95,-45,5,55,105]:
        box(world, Vector3(x, 7, -120), Vector3(10, 20, 18), Color(0.25,0.26,0.27))

    # A few varied houses, reused simple geometry.
    var houses = [
        Vector3(-110, 12, 30), Vector3(-45, 10, 15), Vector3(90, 11, 55),
        Vector3(150, 13, 10), Vector3(-170, 9, 85), Vector3(185, 10, 95)
    ]
    for p in houses:
        box(world, p, Vector3(28, 20, 24), Color(0.62,0.50,0.40))
        # tiny roof cap, still a shared primitive
        box(world, p + Vector3(0, 12, 0), Vector3(31, 4, 27), Color(0.18,0.20,0.22))

    # Sparse trees near roads; distant world remains empty/light.
    for i in range(30):
        var x = -500 + (i * 83) % 980
        var z = -10 + (i * 137) % 260
        cyl(world, Vector3(x, 8, z), 2.2, 16, Color(0.20,0.15,0.10))
        cyl(world, Vector3(x, 19, z), 7.0, 14, Color(0.10,0.28,0.14))

    var sun = DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-55, -30, 0)
    sun.light_energy = 1.0
    world.add_child(sun)

    var env = WorldEnvironment.new()
    var e = Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.48,0.62,0.76)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_color = Color(0.72,0.78,0.86)
    e.ambient_light_energy = 0.8
    env.environment = e
    world.add_child(env)

func _build_plane():
    plane = Node3D.new()
    plane.name = "Ju52_Player"
    add_child(plane)
    plane.position = Vector3(0, altitude, 180)

    # Minimal procedural aircraft silhouette.
    box(plane, Vector3(0,0,0), Vector3(5.5,1.4,18), Color(0.32,0.38,0.35))
    box(plane, Vector3(0,0,-1), Vector3(22,0.5,5), Color(0.38,0.43,0.40))
    box(plane, Vector3(0,0,7), Vector3(9,0.5,4), Color(0.30,0.35,0.33))
    for x in [-7.5,7.5]:
        cyl(plane, Vector3(x,0,0), 1.3, 0.8, Color(0.18,0.18,0.18))

func _build_camera():
    camera = Camera3D.new()
    camera.current = true
    add_child(camera)

func _process(delta):
    time_passed += delta
    var turn = Input.get_axis("turn_left","turn_right")
    var climb = Input.get_axis("pitch_down","pitch_up")
    var throttle = Input.get_axis("throttle_down","throttle_up")
    heading -= turn * delta * 0.75
    pitch = clamp(pitch + climb * delta * 0.35, -0.45, 0.45)
    speed = clamp(speed + throttle * delta * 12.0, 8.0, 70.0)

    var forward = Vector3(sin(heading), sin(pitch), -cos(heading))
    plane.position += forward * speed * delta
    plane.position.y = clamp(plane.position.y, 35.0, 500.0)

    var target = plane.position
    var cam_back = -forward.normalized() * 45.0 + Vector3(0, 16, 0)
    camera.position = target + cam_back
    camera.look_at(target + forward * 20.0, Vector3.UP)

func _build_ui():
    var layer = CanvasLayer.new()
    add_child(layer)
    var panel = ColorRect.new()
    panel.position = Vector2(18,18)
    panel.size = Vector2(315,72)
    panel.color = Color(0.02,0.03,0.04,0.72)
    layer.add_child(panel)
    var label = Label.new()
    label.position = Vector2(30,27)
    label.text = "کوهستان برفی ۱۹۴۲ — Demo سبک\nW/S سرعت   A/D گردش   Q/E بالا/پایین"
    label.add_theme_font_size_override("font_size", 17)
    layer.add_child(label)

    var note = Label.new()
    note.position = Vector2(18, 675)
    note.text = "نمونه آزمایشی: Plan + هندسه کم‌حجم + مدل‌های مشترک"
    note.add_theme_font_size_override("font_size", 15)
    layer.add_child(note)
