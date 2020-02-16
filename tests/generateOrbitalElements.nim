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

ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

var hz = newHorizonClient()
import json
ctx.setSourceRGBA(1, 1, 1, 1)
var newElements = newSeq[OrbitalElements]()
for planet in simpleElements:
  let elements = hz.getOrbitalElements(
    0.0, planet.id, 0)
  echo planet.name
  var planet2 = elements
  planet2.id = planet.id
  planet2.name = planet.name
  newElements.add(planet2)
  var step = planet2.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = planet2.posAt(time)
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

echo $(%newElements)

hz.close()

discard surface.writeToPng("tests/generatedOE.png")