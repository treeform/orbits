import strformat, times
import orbits/simple, orbits/spk, orbits/horizon
import pixie/demo, vmath

downloadSpk("de435.bsp")

var spkFile = readSpk("de435.bsp")

var fromTime = 1517904000.float64 + DAY # starman launch date
let toTime = epochTime()
let id = -143205 # starman ID

var currentTime = fromTime

var hz = newHorizonClient()
let hzStarManVecs = hz.getOrbitalVectorsSeq(
  fromTime,
  toTime,
  1000,
  id,
  0
)

proc computePos(entries: seq[OrbitalVectors], time: float64): DVec3 =
  for i, entry in entries:
    if entry.time < time:
      continue
    assert entries[i-1].time < time and entries[i].time > time
    let
      a = entries[i-1]
      b = entries[i]
      timeDelta = a.time - b.time
    return lerp(b.pos, a.pos, (time - a.time)/timeDelta)

start("Where is SpaceX's Starman?")
while true:
  screen.fill(color(0.11, 0.14, 0.42, 1.0))

  let scaleK = 100.0
  var mat = translate(vec2(400, 300)) * scale(vec2(scaleK, scaleK))

  var path: Path
  path.circle(vec2(0, 0), 0.1)
  screen.fillPath(path, color(1,1,1,1), mat)

  for planet in simpleElements:
    var step = planet.period / 360
    var path: Path

    for i in 0..360:
      let time = step * float(i)
      let pos = spkFile.posAt(time, planet.id, 0) / AU
      if i == 0:
        path.moveTo(pos.x.float32, pos.y.float32)
      else:
        path.lineTo(pos.x.float32, pos.y.float32)
    path.closePath()
    screen.strokePath(path, color(1, 1, 1, 0.1), mat, strokeWidth = 0.01)

    var currentPos = spkFile.posAt(currentTime, planet.id, 0) / AU
    var pathBody: Path
    pathBody.circle(vec3(currentPos).xy, 0.01)
    screen.fillPath(pathBody, color(1,1,1,1), mat)

  # drawing the starman
  block:
    var path: Path
    for i, entry in hzStarManVecs:
      let pos = entry.pos / AU
      if i == 0:
        path.moveTo(pos.x.float32, pos.y.float32)
      else:
        path.lineTo(pos.x.float32, pos.y.float32)
    path.closePath()
    screen.strokePath(path, color(1, 1, 1, 0.1), mat, strokeWidth = 0.02)

    var currentPos = computePos(hzStarManVecs, currentTime) / AU
    var pathBody: Path
    pathBody.circle(vec3(currentPos).xy, 0.02)
    screen.fillPath(pathBody, color(1,1,1,1), mat)

  tick()

  currentTime += 60*60*25 # day per frame

  currentTime = min(currentTime, toTime)
  if isKeyDown(KEY_SPACE):
    currentTime = fromTime
