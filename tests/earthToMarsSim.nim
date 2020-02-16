import strformat
import orbits/simple, orbits/spk, orbits/horizon
import cairo, orbits/vmath64, random, math
import print


var
  surface = imageSurfaceCreate(FORMAT_ARGB32, 1000, 1000)
  ctx = surface.create()

ctx.setSourceRGBA(0.11, 0.14, 0.42, 1.0)
ctx.rectangle(0, 0, float surface.getWidth, float surface.getHeight)
ctx.fill()

let scale = 250.0

ctx.translate(500, 500)
ctx.scale(scale, scale)
ctx.setLineWidth(1/scale)

ctx.setSourceRGBA(1, 1, 1, 1)
ctx.arc(0, 0, 0.00464, 0.0, 2.0*PI)
ctx.fill()

type Body = object
  id: int
  pos: Vec3
  vel: Vec3
  mass: float
var bodies: seq[Body]

# sun
var body = Body()
body.id = 0
bodies.add body

downloadSpk("de435.bsp")
ctx.setSourceRGBA(1, 1, 1, 0.15)
var spkFile = readSpk("de435.bsp")
for planet in simpleElements:
  var step = planet.period / 360
  for i in 0..360:
    let time = step * float(i)
    let pos = spkFile.posAt(time, planet.id, 0) / AU
    ctx.lineTo(pos.x, pos.y)
  ctx.closePath()
  ctx.stroke()

  var body = Body()
  body.id = planet.id
  bodies.add body

const HOUR = 60 * 60
const MINUTE = 60
bodies[0].mass = 1.98847E+30
bodies[1].mass = 3.30E+23
bodies[2].mass = 4.87E+24
bodies[3].mass = 5.97E+24
bodies[4].mass = 6.42E+23
bodies[5].mass = 1.90E+27
bodies[6].mass = 5.68E+26
bodies[7].mass = 8.68E+25
bodies[8].mass = 1.02E+26
bodies[9].mass = 1.46E+22




proc minDistance(startTime: float, kick: Vec3, stepTime: float, draw: bool): (float, float) =



  for planet in simpleElements:
    bodies[planet.id].pos = spkFile.posAt(startTime, planet.id, 0)
    bodies[planet.id].vel = spkFile.velAt(startTime, planet.id, 0)

  var spaceCraft = Body()
  spaceCraft.pos = bodies[3].pos
  var prevPos = spaceCraft.pos
  spaceCraft.vel = bodies[3].vel + kick
  spaceCraft.mass = 110 * 1000 # The Martian: Hermes mass: 110 tons

  if draw:
    ctx.setSourceRGBA(1, 1, 1, 1)
    ctx.arc(spaceCraft.pos.x/AU, spaceCraft.pos.y/AU, 3/scale, 0.0, 2.0*PI)
    ctx.fill()

  var minMarsDist = 1E100


  let maxStep = int(JULIAN_YEAR*2/stepTime)
  #let stepTime = 100000.0
  var time = startTime
  var minTime = 0.0
  var minPos = vec3(0,0,0)
  for step in 0..maxStep:

    spaceCraft.pos = spaceCraft.pos + spaceCraft.vel * stepTime

    for other in bodies[0..0]:
      #if other.id != 0:
      #  other.pos = spkFile.posAt(time, other.id, 0)
      let offset = other.pos - spaceCraft.pos
      let dv = G * other.mass / pow(offset.length, 2)
      let direction = offset.normalize()
      spaceCraft.vel = spaceCraft.vel + direction * dv * stepTime

    let
      marsPos = spkFile.posAt(time, 4, 0)
      marsVel = spkFile.velAt(time, 4, 0)
    let (minMars, minSpaceCraftPos, dist) = computeSegToSeg(marsPos, marsPos + marsVel, spaceCraft.pos, prevPos)
    #let dist = distPToS(, spaceCraft.pos, prevPos)

    #let dist = (marsPos - spaceCraft.pos).length
    #print dist, "vs", dist2, abs(dist - dist2) / dist2

    if minMarsDist > dist:
      minMarsDist = dist
      minTime = time
      minPos = minSpaceCraftPos #pointPToS(spkFile.posAt(time, 4, 0), spaceCraft.pos, prevPos)


    prevPos = spaceCraft.pos
    time += stepTime

    if draw:
      #echo dist
      #echo spaceCraft.pos
      ctx.lineTo(spaceCraft.pos.x/AU, spaceCraft.pos.y/AU)

  if draw:
    ctx.stroke()

    let marsPos = spkFile.posAt(minTime, 4, 0)
    ctx.setSourceRGBA(1, 0, 0, 1)
    ctx.arc(marsPos.x/AU, marsPos.y/AU, 5/scale, 0.0, 2.0*PI)
    ctx.fill()

    ctx.setSourceRGBA(1, 1, 1, 1)
    ctx.arc(minPos.x/AU, minPos.y/AU, 3/scale, 0.0, 2.0*PI)
    ctx.fill()

  return (minMarsDist, minTime)



ctx.setSourceRGBA(1,1,1,1)

var
  bestTime = 1552696987.0
  bestKick = vec3(0, 0, 0)
  bestMinDist = 1E30
  curTime = bestTime
  curKick = bestKick
  curMinDist = 1E30




# let dayScan = 365

# let startTime = 1552715293.0
# randomize()
# var minTime: float

# bestKick = vec3(0, 0, 0)
# bestMinDist = 1E30
# for i in 0..dayScan:
#   curTime = startTime + float(i) * DAY*2

#   let dv = 3700.0
#   curKick = spkFile.velAt(curTime, 3, 0).normalize() * dv
#   (curMinDist, minTime) = minDistance(curTime, curKick, 10000, false)

#   if curMinDist < bestMinDist:
#     bestMinDist = curMinDist
#     bestTime = curTime
#     bestKick = curKick
#     let dv = bestKick.length()
#     print "best scan day: ", bestMinDist, bestTime, dv, bestKick


bestMinDist=3670923806.137688
bestTime=1594878493.0
bestKick=vec3(3383.63238149, 1497.00765049, 0.03649411)


# var
#   vecTime: float
#   vecKick: Vec3
# for accuracy in [20000]:
#   print accuracy
#   let maxSearch = accuracy
#   var a = 1.0
#   var g = 0.10
#   for i in 0..maxSearch:
#     # random search
#     let
#       vecTimeD = DAY * rand(-1.0..1.0)
#       vecKickD = vec3(rand(-1.0..1.0), rand(-1.0..1.0), rand(-0.1..0.1)) * rand(0.0..100.0)

#     vecTime = vecTime * (1-a) + vecTimeD * a
#     vecKick = vecKick * (1-a) + vecKickD * a

#     curTime = bestTime + vecTime * g
#     curKick = bestKick + vecKick * g

#     (curMinDist, minTime) = minDistance(curTime, curKick, float(accuracy), false)

#     if curMinDist < bestMinDist:
#       bestMinDist = curMinDist
#       bestTime = curTime
#       bestKick = curKick

#       vecTime *= -0.2
#       vecKick *= -0.2

#       a = 0.0
#       let dv = bestKick.length()
#       print "best search: ", accuracy, i, g, bestMinDist, bestTime, dv, bestKick

#     a = min(1.0, a + 0.01)





# var
#   adj: array[4, float]

# let accuracy = 20000

# for i in 0..1000:
#   adj[0] = 0
#   adj[1] = 0
#   adj[2] = 0
#   adj[3] = 0

#   for pick in 0..<4:
#     adj[pick] = rand(-1.0 .. +1.0)

#     curTime = bestTime + adj[0]
#     curKick.x = bestKick.x + adj[1]
#     curKick.y = bestKick.y + adj[2]
#     curKick.z = bestKick.z + adj[3]
#     (curMinDist, minTime) = minDistance(curTime, curKick, float(accuracy), false)

#     if curMinDist < bestMinDist:
#       print "adjusting +1", pick

#       while curMinDist < bestMinDist:
#         bestMinDist = curMinDist
#         bestTime = curTime
#         bestKick = curKick
#         let dv = bestKick.length()
#         print "  best search: ", accuracy, bestMinDist, bestTime, dv, bestKick

#         adj[0] *= 1.2
#         adj[1] *= 1.2
#         adj[2] *= 1.2
#         adj[3] *= 1.2

#         curTime = bestTime + adj[0]
#         curKick.x = bestKick.x + adj[1]
#         curKick.y = bestKick.y + adj[2]
#         curKick.z = bestKick.z + adj[3]
#         (curMinDist, minTime) = minDistance(curTime, curKick, float(accuracy), false)

#       adj[0] *= 0.5
#       adj[1] *= 0.5
#       adj[2] *= 0.5
#       adj[3] *= 0.5
#       print "end"

#     # flip
#     adj[0] *= -1
#     adj[1] *= -1
#     adj[2] *= -1
#     adj[3] *= -1

#     curTime = bestTime + adj[0]
#     curKick.x = bestKick.x + adj[1]
#     curKick.y = bestKick.y + adj[2]
#     curKick.z = bestKick.z + adj[3]
#     (curMinDist, minTime) = minDistance(curTime, curKick, float(accuracy), false)

#     if curMinDist < bestMinDist:
#       print "adjusting -1", pick

#       while curMinDist < bestMinDist:
#         bestMinDist = curMinDist
#         bestTime = curTime
#         bestKick = curKick
#         let dv = bestKick.length()
#         print "  best search: ", accuracy, bestMinDist, bestTime, dv, bestKick

#         adj[0] *= 1.2
#         adj[1] *= 1.2
#         adj[2] *= 1.2
#         adj[3] *= 1.2

#         curTime = bestTime + adj[0]
#         curKick.x = bestKick.x + adj[1]
#         curKick.y = bestKick.y + adj[2]
#         curKick.z = bestKick.z + adj[3]
#         (curMinDist, minTime) = minDistance(curTime, curKick, float(accuracy), false)

#       print "end"




# let accuracy = 10000
# print accuracy
# let maxSearch = 1000
# var a = 1.0

# for i in 0..maxSearch:
#   # random search
#   let
#     #vecTime = DAY * rand(-1.0..1.0)
#     vecKick = vec3(rand(-1.0..1.0), rand(-1.0..1.0), rand(-0.1..0.1)) * rand(0.0..10.0)

#   let a = 1.0 - pow(i/maxSearch, 1)

#   #curTime = bestTime + vecTime * a
#   curKick = bestKick + vecKick * a

#   (curMinDist, minTime) = minDistance(curTime, curKick, float(accuracy), false)

#   if curMinDist < bestMinDist:
#     bestMinDist = curMinDist
#     bestTime = curTime
#     bestKick = curKick
#     let dv = bestKick.length()
#     print "best search: ", accuracy, bestMinDist, bestTime, dv, bestKick, i, a








# best vector search
for accuracy in [10000, 1000, 100, 10, 1]:
  bestMinDist = minDistance(bestTime, bestKick, float(accuracy), false)[0]
  print accuracy, bestMinDist

  for k in 0..1000:
    let a = 100 / pow(float(k+1), 2)
    if a < 10: break

    for i in 0..100:
      let adjs = @[
        vec3( 1,  0,  0) * a,
        vec3( 0,  1,  0) * a,
        vec3( 0,  0,  1) * a,
        vec3(-1,  0,  0) * a,
        vec3( 0, -1,  0) * a,
        vec3( 0,  0, -1) * a
      ]
      var dists = @[0.0,0,0,0,0,0]

      for i in 0..<6:
        dists[i] = minDistance(bestTime, bestKick + adjs[i], float(accuracy), false)[0]
        #print dists[i], "vs", bestMinDist

      var
        minDist = bestMinDist
        minI = -1
      for i in 0..<6:
        if dists[i] < minDist:
          minI = i
          minDist = dists[i]
      if minI == -1:
        echo "<=="
        break

      bestKick = bestKick + adjs[minI]
      bestMinDist = dists[minI]
      echo "better!", bestMinDist, adjs[minI]




discard minDistance(bestTime, bestKick, 10000, true)

discard surface.writeToPng("tests/earthToMarsSim.png")

