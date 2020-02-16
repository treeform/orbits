import orbits/simple, orbits/vmath64, cairo

var
  surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
  ctx = surface.create()

ctx.setSourceRGB(0.11, 0.14, 0.42)
ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
ctx.fill()


let scale = 10.0

ctx.translate(500, 500)
ctx.scale(scale, scale)
ctx.setLineWidth(1/scale)

ctx.setSourceRGBA(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()


for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let pos = planet.posAt(step * float(i)) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

discard surface.writeToPng("tests/orbitsSimple.png")