import ../src/orbits/simple
import quickcairo, math

var
  surface = imageSurfaceCreate(FORMAT.argb32, 1000, 1000)
  ctx = surface.newContext()

ctx.setSource(0.11, 0.14, 0.42)
ctx.rectangle(0, 0, float surface.width, float surface.height)
ctx.fill()

ctx.setLineWidth(0.1)
ctx.setSource(1, 1, 1, 0.6)
ctx.translate(500, 500)
ctx.scale(10, 10)

for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let pos = planet.posAt(step * float(i))
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

discard surface.writeToPng("tests/orbitsSimple.png")