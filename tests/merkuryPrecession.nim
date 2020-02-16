# import orbits/simple, orbits/complex
# import cairo, math

# var
#   surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
#   ctx = surface.create()

# ctx.setSourceRGBA(0.11, 0.14, 0.42, 1.0)
# ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
# ctx.fill()

# ctx.translate(500, 500)
# ctx.scale(1000, 1000)

# ctx.setSourceRGBA(1, 1, 1, 1)
# ctx.setLineWidth(0.001)

# # draw orbit of merkury 10 times showing shift over 500y
# let shiftBy = 500.0 * (60*60*24*365)
# for j in 0..10:
#   ctx.setSourceRGBA(1, 1, 1, float(j) / 10 * 0.8 + 0.2)
#   let planet = complexElements[0] # merkury
#   var step = planet.period / 360
#   for i in 0..360:
#     let pos = planet.posAt(step * float(i) + float(j) * shiftBy)
#     ctx.lineTo(pos.x, pos.y)
#   ctx.stroke()

# ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
# ctx.fill()

# discard surface.writeToPng("tests/merkuryPrecession.png")


import orbits/simple, orbits/spk
import cairo, orbits/vmath64

var
  surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
  ctx = surface.create()

ctx.setSourceRGBA(0.11, 0.14, 0.42, 1.0)
ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
ctx.fill()

ctx.translate(500, 500)
ctx.scale(1000, 1000)

ctx.setSourceRGBA(1, 1, 1, 1)
ctx.setLineWidth(0.001)

ctx.setSourceRGBA(1, 1, 1, 1)
var spkFile = readSpk("de435.bsp")

# draw orbit of merkury 5 times showing shift over 10 earth years
let shiftBy = 10.0 * (60*60*24*365)
for j in 0..5:
  ctx.setSourceRGBA(1, 1, 1, float(j) / 5 * 0.8 + 0.2)
  let planetId = 1 # merkury
  var step = simpleElements[0].period / 360
  for i in 0..360:
    let time = step * float(i) + shiftBy * float(j)
    let pos = spkFile.posAt(time, planetId, 0) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

discard surface.writeToPng("tests/merkuryPrecession.png")