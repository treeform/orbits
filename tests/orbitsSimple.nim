import ../src/orbits/simple
import quickcairo, ../src/orbits/vmath64

var
  surface = imageSurfaceCreate(FORMAT.argb32, 1000, 1000)
  ctx = surface.newContext()

ctx.setSource(0.11, 0.14, 0.42)
ctx.rectangle(0, 0, float surface.width, float surface.height)
ctx.fill()


let scale = 10.0

ctx.translate(500, 500)
ctx.scale(scale, scale)
ctx.setLineWidth(1/scale)

ctx.setSource(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()


for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let pos = planet.posAt(step * float(i)) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

discard surface.writeToPng("tests/orbitsSimple.png")