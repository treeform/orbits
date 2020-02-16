import strformat, times
import orbits/simple, orbits/spk, orbits/horizon
import cairo, orbits/vmath64

let now = epochTime()

var
  surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
  ctx = surface.create()

ctx.setSourceRGBA(0.11, 0.14, 0.42, 1.0)
ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
ctx.fill()

let scale = 250.0

ctx.translate(500, 500)
ctx.scale(scale, scale)


ctx.selectFontFace("Sans", FONT_SLANT_NORMAL, FONT_WEIGHT_NORMAL)
ctx.setFontSize(12.0/scale)

ctx.setSourceRGBA(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

var hz = newHorizonClient()

# simple orbits in red
ctx.setSourceRGBA(1, 1, 1, 0.1)
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
  ctx.setSourceRGBA(1, 1, 1, 1)
  let id = -143205
  let entries = hz.getOrbitalVectorsSeq(
    1517904000+DAY,
    now,
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


  echo entries[^1].pos.length / AU
  echo entries[^1].vel.length

  let earthOv = hz.getOrbitalVectors(
    now,
    399,
    0)

  let
    vel = int(entries[^1].vel.length)
    dist = int((earthOv.pos - entries[^1].pos).length / 1000 - 6378.1)

  ctx.save()
  ctx.moveTo(pos.x, pos.y)
  ctx.showText("  Starman")
  ctx.restore()
  ctx.save()
  ctx.moveTo(pos.x, pos.y+20/scale)
  ctx.showText(&"  {$vel}m/s")
  ctx.restore()
  ctx.save()
  ctx.moveTo(pos.x, pos.y+40/scale)
  ctx.showText(&"  {$dist}km")
  ctx.restore()

hz.close()

discard surface.writeToPng("tests/starman.png")