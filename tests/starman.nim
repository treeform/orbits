import strformat, times
import ../src/orbits/simple, ../src/orbits/spk, ../src/orbits/horizon
import quickcairo, vmath

let now = epochTime()

var
  surface = imageSurfaceCreate(FORMAT.argb32, 1000, 1000)
  ctx = surface.newContext()

ctx.setSource(0.11, 0.14, 0.42)
ctx.rectangle(0, 0, float surface.width, float surface.height)
ctx.fill()

let scale = 250.0

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
  ctx.setSource(1, 1, 1, 1)
  let id = -143205
  let entries = hz.getOrbitalVectors(
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

  let entriesEarth = hz.getOrbitalVectors(
    now,
    1552284021 + DAY,
    10,
    399,
    0)

  let
    vel = int(entries[^1].vel.length)
    dist = int((entriesEarth[0].pos - entries[^1].pos).length / 1000 - 6378.1)

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