import strformat, times
import orbits/simple, orbits/spk, orbits/horizon
import pixie/demo, vmath

let now = epochTime()

const
  planetScale = 0.25

downloadSpk("de435.bsp")

var
  spkFile = readSpk("de435.bsp")
  hz = newHorizonClient()
  slide = 0
  currentTime = 0.0
  keyWait = false
  scaleK = 10.0

let
  spkfilesImage = readImage("demo/spkfiles.png")
  horizonsysImage = readImage("demo/horizonsys.png")

hz.debug = false

var font = readFont("demo/Anton-Regular.ttf")
font.size = 20
font.paint.color = color(1, 1, 1, 1).rgbx

var font2 = readFont("demo/Anton-Regular.ttf")
font2.size = 10
font2.paint.color = color(1, 1, 1, 1).rgbx

start("Orbits demo.")
while true:

  scaleK += mouseWheelDelta * 0.2

  scaleK = clamp(scaleK, 1.0, 20.0)

  screen.fill(color(0.11, 0.14, 0.42, 1.0))

  case slide
  of 0:
    let text = "Totally fake Solar System."
    screen.fillText(font.typeset(text), vec2(10, 10))

    var mat = translate(vec2(400, 300)) * scale(vec2(scaleK, scaleK))

    var path: Path
    path.circle(vec2(0, 0), 0.1)
    screen.fillPath(path, color(1,1,1,1), mat)

    for planet in simpleElements:
      var step = planet.period / 360
      var path: Path

      let dist = planet.posAt(0).length

      for i in 0..360:
        let th = float(i).toRadians()
        let pos = dvec3(sin(th), cos(th), 0) * dist / AU
        if i == 0:
          path.moveTo(pos.x.float32, pos.y.float32)
        else:
          path.lineTo(pos.x.float32, pos.y.float32)
      path.closePath()

      let th = (-currentTime*10 + planet.period)/ JULIAN_YEAR
      var currentPos = dvec3(sin(th), cos(th), 0) * dist / AU
      var pathBody: Path
      pathBody.circle(vec3(currentPos).xy, planetScale)
      screen.fillPath(pathBody, color(1,1,1,1), mat)

      screen.strokePath(path, color(1, 1, 1, 0.1), mat, strokeWidth = 1.5)

  of 1:
    let text = "Solar System with Ecliptical Model."
    screen.fillText(font.typeset(text), vec2(10, 10))

    var mat = translate(vec2(400, 300)) * scale(vec2(scaleK, scaleK))

    var path: Path
    path.circle(vec2(0, 0), 0.1)
    screen.fillPath(path, color(1,1,1,1), mat)

    for planet in simpleElements:
      var step = planet.period / 360
      var path: Path

      for i in 0..360:
        let time = step * float(i)
        let pos = planet.posAt(time) / AU
        if i == 0:
          path.moveTo(pos.x.float32, pos.y.float32)
        else:
          path.lineTo(pos.x.float32, pos.y.float32)
      path.closePath()

      var currentPos = planet.posAt(currentTime) / AU
      var pathBody: Path
      pathBody.circle(vec3(currentPos).xy, planetScale)
      screen.fillPath(pathBody, color(1,1,1,1), mat)

      screen.strokePath(path, color(1, 1, 1, 0.1), mat, strokeWidth = 0.5)

  of 2:
    screen.draw(spkfilesImage)

  of 3:
    let text = "Solar System with NASA's Chebyshev polynomials."
    screen.fillText(font.typeset(text), vec2(10, 10))

    var mat = translate(vec2(400, 300)) * scale(vec2(scaleK, scaleK))

    var path: Path
    path.circle(vec2(0, 0), 0.1)
    screen.fillPath(path, color(1,1,1,1), mat)

    for planet in simpleElements:
      var step = planet.period / 360
      var firstPos: DVec3
      var path: Path

      for i in 0..360:
        let time = step * float(i)
        let pos = spkFile.posAt(time, planet.id, 0) / AU
        if i == 0:
          path.moveTo(pos.x.float32, pos.y.float32)
          firstPos = pos
        else:
          path.lineTo(pos.x.float32, pos.y.float32)
      path.lineTo(firstPos.x.float32, firstPos.y.float32)
      path.closePath()

      var currentPos = spkFile.posAt(currentTime, planet.id, 0) / AU
      var pathBody: Path
      pathBody.circle(vec3(currentPos).xy, planetScale)
      screen.fillPath(pathBody, color(1,1,1,1), mat)

      screen.strokePath(path, color(1, 1, 1, 0.1), mat, strokeWidth = 0.25)

  of 4:
    screen.draw(horizonsysImage, mat=scale(vec2(0.8)))

  of 5:
    let text = "Solar System with NASA's Horizon System."
    screen.fillText(font.typeset(text), vec2(10, 10))

    var mat = translate(vec2(400, 300)) * scale(vec2(scaleK, scaleK))

    var path: Path
    path.circle(vec2(0, 0), 0.1)
    screen.fillPath(path, color(1,1,1,1), mat)

    proc drawOrbit(id: int, color: Color) =

      let elements = hz.getOrbitalElements(
        time = 0.0,
        targetId = id,
        observerId = 0
      )

      let period = elements.period

      var firstPos: DVec3
      var path: Path

      let entries = hz.getOrbitalVectorsSeq(
        fromTime = 0.0,
        toTime = period,
        steps = 360,
        targetId = id,
        observerId = 0)
      for i, entry in entries:
        let pos = entry.pos / AU
        if i == 0:
          path.moveTo(pos.x.float32, pos.y.float32)
          firstPos = pos
        else:
          path.lineTo(pos.x.float32, pos.y.float32)
      path.lineTo(firstPos.x.float32, firstPos.y.float32)
      path.closePath()

      var currentPos = entries.posAt(currentTime mod period) / AU
      var pathBody: Path
      pathBody.circle(vec3(currentPos).xy, planetScale)
      screen.fillPath(pathBody, color(1,1,1,1), mat)

      screen.strokePath(path, color, mat, strokeWidth = 0.1)

    for planet in simpleElements:
      drawOrbit(planet.id, color(1, 1, 1, 0.1))

    # for id in [2000001]:
    #   drawOrbit(id, color(1, 0, 0, 0.1))

    block:
      #plot voyager1
      let id = -31
      let entries = hz.getOrbitalVectorsSeq(
        242290800+DAY,
        1552284021,
        1000,
        id,
        0)
      var path: Path
      for entry in entries:
        let pos = entry.pos / AU
        path.lineTo(pos.x.float32, pos.y.float32)
      screen.strokePath(path, color(1,1,1,1), mat, strokeWidth = 0.1)
      let pos = entries[^1].pos / AU
      screen.fillText(font2, "  Voyager 1", mat * vec2(pos.x.float32, pos.y.float32))

    block:
      #plot voyager2
      let id = -32
      let entries = hz.getOrbitalVectorsSeq(
        240908400+DAY,
        1552284021,
        1000,
        id,
        0)
      var path: Path
      for entry in entries:
        let pos = entry.pos / AU
        path.lineTo(pos.x.float32, pos.y.float32)
      screen.strokePath(path, color(1,1,1,1), mat, strokeWidth = 0.1)
      let pos = entries[^1].pos / AU
      screen.fillText(font2, "  Voyager 2", mat * vec2(pos.x.float32, pos.y.float32))

    block:
      #plot voyager2
      let id = -98
      let entries = hz.getOrbitalVectorsSeq(
        1137657600+DAY,
        1552284021,
        1000,
        id,
        0)
      var path: Path
      for entry in entries:
        let pos = entry.pos / AU
        path.lineTo(pos.x.float32, pos.y.float32)
      screen.strokePath(path, color(1,1,1,1), mat, strokeWidth = 0.1)
      let pos = entries[^1].pos / AU
      screen.fillText(font2, "  New Horizon", mat * vec2(pos.x.float32, pos.y.float32))


    # for id in [136199]:
    #   drawOrbit(id, color(1, 0, 0, 0.9))

  else:
    discard

  if isKeyDown(KEY_RIGHT) or isKeyDown(KEY_SPACE):
    if not keyWait:
      keyWait = true
      slide = min(slide.ord + 1, 5)
  elif isKeyDown(KEY_LEFT):
    if not keyWait:
      keyWait = true
      slide = max(slide.ord - 1, 0)
  else:
    keyWait = false

  tick()

  currentTime += 60*60*25 * 1 # day per frame
