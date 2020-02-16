import strformat
import orbits/simple, orbits/spk, orbits/horizon
import cairo, orbits/vmath64

var
  surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
  ctx = surface.create()

ctx.setSourceRGBA(0.11, 0.14, 0.42, 1.0)
ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
ctx.fill()

let scale = 250.0

ctx.translate(500, 500)
ctx.scale(scale, scale)
ctx.setLineWidth(1/scale)

ctx.setSourceRGBA(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

var hz = newHorizonClient()

type Body = object
  id: int
  pos: Vec3
  vel: Vec3
  mass: float
var bodies: seq[Body]

# sun
var body = Body()
body.id = 0
bodies.add body

# get inital obits from horizon
ctx.setSourceRGBA(1, 1, 1, 0.1)
for planet in simpleElements:
  let entries = hz.getOrbitalVectorsSeq(
    fromTime = 0.0,
    toTime = planet.period,
    steps = 360,
    targetId = planet.id,
    observerId = 0)
  var body = Body()
  body.id = planet.id
  body.pos = entries[0].pos
  body.vel = entries[0].vel
  bodies.add body

  for entry in entries:
    let pos = entry.pos / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.closePath()
  ctx.stroke()

const G = 6.674E-11
const HOUR = 60 * 60
const MINUTE = 60
bodies[0].mass = 1.98847E+30
bodies[1].mass = 3.30E+23
bodies[2].mass = 4.87E+24
bodies[3].mass = 5.97E+24
bodies[4].mass = 6.42E+23
bodies[5].mass = 1.90E+27
bodies[6].mass = 5.68E+26
bodies[7].mass = 8.68E+25
bodies[8].mass = 1.02E+26
bodies[9].mass = 1.46E+22

let maxStep = 1000000
let stepTime = 10.0
for step in 0..maxStep:

  for body in bodies.mitems:
    body.pos = body.pos + body.vel * stepTime

    for other in bodies:
      if body.id == other.id: continue
      let offset = other.pos - body.pos
      let dv = G * other.mass / pow(offset.length, 2)
      let direction = offset.normalize()
      body.vel = body.vel + direction * dv * stepTime


  if step mod (maxStep div 50) == 0:

    for body in bodies:
      ctx.setSourceRGBA(1, 1, 1, step/maxStep + 0.1)
      ctx.arc(body.pos.x/AU, body.pos.y/AU, 3/scale, 0.0, 2.0*PI)
      ctx.fill()


hz.close()


discard surface.writeToPng("tests/orbitsSimulated.png")