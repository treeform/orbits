import strformat, times
import orbits/simple, orbits/spk#, orbits/vmath64
import ../demo/window

let now = epochTime()


downloadSpk("de435.bsp")

var spkFile = readSpk("de435.bsp")

var currentTime = 0.0

start("Solar System from NASA's SPK files that use Chebyshev polynomials")
while true:
  screen.fill(color(0.11, 0.14, 0.42, 1.0))

  let scaleK = 10.0
  var mat = translate(vec2(400, 300)) * scale(vec2(scaleK, scaleK))

  let path = newPath()
  path.circle(0, 0, 0.1)
  screen.fillPath(path, color(1,1,1,1), mat)

  for planet in simpleElements:
    var step = planet.period / 360
    let path = newPath()

    for i in 0..360:
      let time = step * float(i)
      let pos = spkFile.posAt(time, planet.id, 0) / AU
      if i == 0:
        path.moveTo(pos.x.float32, pos.y.float32)
      else:
        path.lineTo(pos.x.float32, pos.y.float32)
    path.closePath()


    var currentPos = spkFile.posAt(currentTime, planet.id, 0) / AU
    let pathBody = newPath()
    pathBody.ellipse(vec3(currentPos).xy, 0.1, 0.1)
    screen.fillPath(pathBody, color(1,1,1,1), mat)

    screen.strokePath(path, color(1, 1, 1, 0.1), mat, strokeWidth = 0.1)

  tick()

  currentTime += 60*60*25 * 7 # week per frame
