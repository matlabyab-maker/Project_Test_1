extends Node3D

var aircraft: Node3D
var speed := 20.0
var heading := 0.0
var pitch := 0.0
var status: Label

func mat(c: Color) -> StandardMaterial3D:
    var m := StandardMaterial3D.new()
    m.albedo_color = c
    m.roughness = 0.9
    return m

func box(parent: Node3D, size: Vector3, pos: Vector3, c: Color) -> MeshInstance3D:
    var n := MeshInstance3D.new()
    var mesh := BoxMesh.new()
    mesh.size = size
    n.mesh = mesh
    n.material_override = mat(c)
    n.position = pos
    parent.add_child(n)
    return n

func _ready():
    var env := WorldEnvironment.new()
    var e := Environment.new()
    e.background_mode = Environment.BG_COLOR
    e.background_color = Color(0.55,0.68,0.82)
    e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    e.ambient_light_energy = 0.8
    env.environment = e
    add_child(env)

    var sun := DirectionalLight3D.new()
    sun.rotation_degrees = Vector3(-48,-30,0)
    sun.shadow_enabled = true
    add_child(sun)

    box(self, Vector3(260,2,260), Vector3(0,-1,0), Color(0.88,0.90,0.92))

    for p in [Vector3(-70,18,-80),Vector3(65,24,-105),Vector3(-95,14,50),Vector3(90,20,55)]:
        var m := MeshInstance3D.new()
        var s := SphereMesh.new()
        s.radius = 45
        s.height = 70
        m.mesh = s
        m.material_override = mat(Color(0.72,0.76,0.80))
        m.position = p
        m.scale = Vector3(1.5,1.0,1.4)
        add_child(m)

    box(self, Vector3(12,0.25,180), Vector3(0,0.12,0), Color(0.18,0.18,0.17))
    box(self, Vector3(22,1,10), Vector3(0,2,35), Color(0.35,0.35,0.34))

    for p in [Vector3(-25,2,-25),Vector3(25,2,-5),Vector3(-28,2,48),Vector3(28,2,70)]:
        box(self, Vector3(10,4,9), p, Color(0.66,0.56,0.45))
        box(self, Vector3(11,1.5,10), p+Vector3(0,2.75,0), Color(0.25,0.20,0.18))

    aircraft = Node3D.new()
    aircraft.position = Vector3(0,22,75)
    add_child(aircraft)
    box(aircraft, Vector3(3.2,2.4,9.0), Vector3.ZERO, Color(0.30,0.36,0.28))
    box(aircraft, Vector3(14,0.35,2.4), Vector3.ZERO, Color(0.42,0.45,0.40))

    var cam := Camera3D.new()
    cam.position = Vector3(0,4,13)
    cam.rotation_degrees = Vector3(-8,180,0)
    aircraft.add_child(cam)
    cam.current = true

    var layer := CanvasLayer.new()
    add_child(layer)
    status = Label.new()
    status.position = Vector2(20,20)
    status.add_theme_font_size_override("font_size",22)
    layer.add_child(status)

func _process(delta):
    if not aircraft: return
    var turn := Input.get_axis("turn_left","turn_right")
    var throttle := Input.get_axis("speed_down","speed_up")
    var pcontrol := Input.get_axis("pitch_down","pitch_up")
    speed = clamp(speed + throttle*12.0*delta,5.0,55.0)
    heading += turn*35.0*delta
    pitch = clamp(pitch + pcontrol*25.0*delta,-25.0,25.0)
    aircraft.rotation_degrees.y = heading
    aircraft.rotation_degrees.x = pitch
    aircraft.position += (-aircraft.global_transform.basis.z)*speed*delta
    status.text = "کوهستان برفی ۱۹۴۲ — دمو سبک\nسرعت: %.1f  |  ارتفاع: %.1f\nW/S سرعت  A/D گردش  Q/E شیب" % [speed,aircraft.position.y]
