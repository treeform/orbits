import strformat
import orbits/simple, orbits/spk, orbits/horizon
import cairo, orbits/vmath64

var
  surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
  ctx = surface.create()

ctx.setSourceRGBA(0.11, 0.14, 0.42, 1.0)
ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
ctx.fill()

let scale = 10.0

ctx.translate(500, 500)
ctx.scale(scale, scale)
ctx.setLineWidth(1/scale)

ctx.setSourceRGBA(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

var hz = newHorizonClient()

# simple orbits in red
ctx.setSourceRGBA(1, 0, 0, 1)
for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = planet.posAt(time) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.closePath()
  ctx.stroke()

#spk orbits in blue
downloadSpk("de435.bsp")
ctx.setSourceRGBA(0, 1, 0, 1)
var spkFile = readSpk("de435.bsp")
for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = spkFile.posAt(time, planet.id, 0) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.closePath()
  ctx.stroke()

#horizon orbits in white
ctx.setSourceRGBA(1, 1, 1, 1)
for planet in simpleElements:
  let entries = hz.getOrbitalVectorsSeq(
    fromTime = 0.0,
    toTime = planet.period,
    steps = 360,
    targetId = planet.id,
    observerId = 0)
  for entry in entries:
    let pos = entry.pos / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.closePath()
  ctx.stroke()
hz.close()

discard surface.writeToPng("tests/orbitsHorizon.png")