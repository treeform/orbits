import strformat, times
import ../src/orbits/simple, ../src/orbits/spk, ../src/orbits/horizon
import quickcairo, ../src/orbits/vmath64

var
  surface = imageSurfaceCreate(FORMAT.argb32, 1000, 1000)
  ctx = surface.newContext()

ctx.setSource(0.11, 0.14, 0.42)
ctx.rectangle(0, 0, float surface.width, float surface.height)
ctx.fill()

let scale = 3.5

ctx.translate(500, 500)
ctx.scale(scale, scale)


ctx.selectFontFace("Sans", FONT_SLANT.normal, FONT_WEIGHT.normal)
ctx.setFontSize(12.0/scale)

ctx.setSource(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

var hz = newHorizonClient()

# simple orbits in red
ctx.setSource(1, 1, 1, 0.1)
ctx.setLineWidth(2/scale)
for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = planet.posAt(time) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.closePath()
  ctx.stroke()

ctx.setLineWidth(1/scale)

block:
  #plot voyager1
  ctx.setSource(1, 1, 1, 1)
  let id = -31
  let entries = hz.getOrbitalVectorsSeq(
    242290800+DAY,
    1552284021,
    1000,
    id,
    0)
  ctx.newPath()
  for entry in entries:
    let pos = entry.pos / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

  let pos = entries[^1].pos / AU
  ctx.lineTo(pos.x, pos.y)
  ctx.showText("  Voyager 1")


block:
  #plot voyager2
  ctx.setSource(1, 1, 1, 1)
  let id = -32
  let entries = hz.getOrbitalVectorsSeq(
    240908400+DAY,
    1552284021,
    1000,
    id,
    0)
  ctx.newPath()
  for entry in entries:
    let pos = entry.pos / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

  let pos = entries[^1].pos / AU
  ctx.lineTo(pos.x, pos.y)
  ctx.showText("  Voyager 2")

block:
  #plot new horizons
  ctx.setSource(1, 1, 1, 1)
  let id = -98
  let entries = hz.getOrbitalVectorsSeq(
    1137657600+DAY,
    1552284021,
    1000,
    id,
    0)
  ctx.newPath()
  for entry in entries:
    let pos = entry.pos / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.stroke()

  let pos = entries[^1].pos / AU
  ctx.lineTo(pos.x, pos.y)
  ctx.showText("  New Horizon")


# block:
#   #plot Dawn
#   ctx.setSource(1, 1, 1, 1)
#   let voyager2Id = -203
#   let entries = hz.getOrbitalVectorsSeq(
#     1190876400 + DAY,
#     1552284021,
#     1000,
#     voyager2Id,
#     0)
#   ctx.newPath()
#   for entry in entries:
#     let pos = entry.pos / AU
#     ctx.lineTo(pos.x, pos.y)
#   ctx.stroke()

#   let pos = entries[^1].pos / AU
#   ctx.lineTo(pos.x, pos.y)
#   ctx.showText("  Dawn")


hz.close()

discard surface.writeToPng("tests/spacecraft.png")