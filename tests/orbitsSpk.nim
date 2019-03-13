import ../src/orbits/simple, ../src/orbits/spk
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

ctx.setSource(1, 0, 0, 1)
for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = planet.posAt(time) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

ctx.setSource(1, 1, 1, 1)

downloadSpk("de435.bsp")

var spkFile = readSpk("de435.bsp")
for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = spkFile.posAt(time, planet.id, 0) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()


ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

discard surface.writeToPng("tests/orbitsSpk.png")