import net, streams, strutils, os, strutils, strformat
import vmath, print
import simple


type
  HorizonClient* = ref object
    socket: Socket


proc cutBy(main, s1, s2:string): string =
  var starts = main.find(s1) + s1.len
  var ends = main.rfind(s2)
  if starts == -1:
    quit("can't find s1 " & s1)
  if ends == -1:
    quit("can't find s2 " & s2)
  return main[starts..<ends]


proc newHorizonClient*(): HorizonClient =
  ## Connect to JPL Horizon System
  var hz = HorizonClient()
  return hz


proc getOrbitalData*(
    hz: HorizonClient,
    format: string,
    fromTime: string,
    toTime: string,
    duration: string,
    targetId,
    observerId: int
  ): string =
  let fileKey = (&"cache/{format} {fromTime} {toTime} {duration} {$targetId} {$observerId}.txt"
    ).replace(":", " ").replace("-", " ")
  if existsFile(fileKey):
    echo "reading from cache:", fileKey
    return readFile(fileKey)

  if hz.socket == nil:
    hz.socket = newSocket()
    hz.socket.connect("horizons.jpl.nasa.gov", Port(6775))

  var
    running = true
    backBuffer = ""
    prevLen = 0

  proc promt(p: string): bool =
    return backBuffer.endsWith(p)

  proc send(p: string)=
    hz.socket.send(p & "\n")
    echo p

  while running:
    try:
      while true:
        var chars = hz.socket.recv(1, 10)
        backBuffer &= chars
    except TimeoutError:
      discard

    if prevLen == backBuffer.len:
      continue
    prevLen = backBuffer.len

    var backLines = backBuffer.split("\n")
    var lastLine = backLines[backLines.len - 1]

    if promt("Horizons> "):
      send($targetId)
    if "Select ..." in lastLine and promt("<cr>: "):
      send("E")
    if promt("Observe, Elements, Vectors  [o,e,v,?] : "):
      send(format)
    if "Coordinate" in lastLine and "center" in lastLine and promt("] : "):
      send("@" & $observerId)
    if " Use previous center" in lastLine and promt("] : "):
      send("n")
    if promt("Reference plane [eclip, frame, body ] : "):
      #send("eclip")
      send("frame")

    if promt("] : ") and "Starting TDB [>=" in lastLine:
      send(fromTime)
    if promt("] : ") and "Ending   TDB [<=" in lastLine:
      send(toTime)
    if promt("Output interval [ex: 10m, 1h, 1d, ? ] : "):
      send(duration)
    if promt("Accept default output [ cr=(y), n, ?] : "):
      send("y")
    if "Scroll & Page: space" in lastLine:
      hz.socket.send(" ")
    if promt(">>> Select... [A]gain, [N]ew-case, [F]tp, [M]ail, [R]edisplay, ? : "):
      var orbitText = backBuffer.cutBy(
        "$$SOE",
        "$$EOE")

      var text = orbitText.strip()

      for blk in backBuffer.split("*******************************************************************************"):
        if "Output units" in blk:
          text = blk & "*** START ***\n" & text

      var start = 0
      while true:
        var badBlock = text.find("\x1B[", start)
        if badBlock == -1:
          break
        var endBadBlock = text.find("\27[m\27[K\13\27[K", badBlock+2)
        start = endBadBlock + 3
        text.delete(badBlock, endBadBlock+10)

      writeFile(fileKey, text)
      echo "cached data in:", fileKey
      result = text
      send("n")
      running = false

proc parseOrbitalVectors*(data: string): seq[OrbitalVectors] =
  var unit = AU
  var header, text: string
  var parts = data.split("*** START ***\n")
  header = parts[0]
  assert parts.len == 2
  text = parts[1]
  if "Output units    : KM-D" in header:
    unit = KM

  var orbitData = newSeq[OrbitalVectors]()
  var entry: OrbitalVectors

  var i = 0
  for line in text.split("\n"):
    if i mod 4 == 0:
      var oddTime : float64 = parseFloat(line[0..15])
      var time = Y2000 + (oddTime - J2000) * DAY
      entry.time = time

    if line.startsWith(" X"):
      var p = vec3(
        parseFloat(line[4..25].strip()),
        parseFloat(line[30..51].strip()),
        parseFloat(line[56..77].strip()))
      p = p * unit
      entry.pos = p

    if line.startsWith(" VX"):
      var v = vec3(
        parseFloat(line[4..25].strip()),
        parseFloat(line[30..51].strip()),
        parseFloat(line[56..77].strip()))
      v = v * unit / DAY
      entry.vel = v
      orbitData.add(entry)

    if line.startsWith("VX"):
      var v = vec3(
        parseFloat(line[3..24].strip()),
        parseFloat(line[29..50].strip()),
        parseFloat(line[55..76].strip()))
      v = v * unit / DAY
      orbitData.add(entry)

    inc i

  return orbitData


proc close*(hz: HorizonClient) =
  if hz.socket != nil:
    hz.socket.close()


# proc getOrbitalVectors*(
#     hz: HorizonClient,
#     fromTime: string,
#     toTime: string,
#     duration: string,
#     targetId,
#     observerId: int
#   ): seq[OrbitalVectors] =
#   let fileKey = (&"cache/ov{fromTime} {toTime} {duration} {$targetId} {$observerId}.txt"
#     ).replace(":", " ").replace("-", " ")
#   if not existsFile("cache"):
#     createDir("cache")
#   if existsFile(fileKey):
#     echo "reading from cache:", fileKey
#     return parseOrbitalVectors(readFile(fileKey))

#   if hz.socket == nil:
#     hz.socket = newSocket()
#     hz.socket.connect("horizons.jpl.nasa.gov", Port(6775))

#   var
#     running = true
#     backBuffer = ""
#     prevLen = 0

#   proc promt(p: string): bool =
#     return backBuffer.endsWith(p)

#   proc send(p: string)=
#     hz.socket.send(p & "\n")
#     echo p

#   while running:
#     try:
#       while true:
#         var chars = hz.socket.recv(1, 10)
#         backBuffer &= chars
#     except TimeoutError:
#       discard

#     if prevLen == backBuffer.len:
#       continue
#     prevLen = backBuffer.len

#     var backLines = backBuffer.split("\n")
#     var lastLine = backLines[backLines.len - 1]

#     if promt("Horizons> "):
#       send($targetId)
#     if "Select ..." in lastLine and promt("<cr>: "):
#       send("E")
#     if promt("Observe, Elements, Vectors  [o,e,v,?] : "):
#       send("v")
#     if "Coordinate" in lastLine and "center" in lastLine and promt("] : "):
#       send("@" & $observerId)
#     if " Use previous center" in lastLine and promt("] : "):
#       send("n")
#     if promt("Reference plane [eclip, frame, body ] : "):
#       #send("eclip")
#       send("frame")

#     if promt("] : ") and "Starting TDB [>=" in lastLine:
#       send(fromTime)
#     if promt("] : ") and "Ending   TDB [<=" in lastLine:
#       send(toTime)
#     if promt("Output interval [ex: 10m, 1h, 1d, ? ] : "):
#       send(duration)
#     if promt("Accept default output [ cr=(y), n, ?] : "):
#       send("y")
#     if "Scroll & Page: space" in lastLine:
#       hz.socket.send(" ")
#     if promt(">>> Select... [A]gain, [N]ew-case, [F]tp, [M]ail, [R]edisplay, ? : "):
#       var orbitText = backBuffer.cutBy(
#         "$$SOE",
#         "$$EOE")

#       var text = orbitText.strip()

#       for blk in backBuffer.split("*******************************************************************************"):
#         if "Output units" in blk:
#           text = blk & "*** START ***\n" & text

#       var start = 0
#       while true:
#         var badBlock = text.find("\x1B[", start)
#         if badBlock == -1:
#           break
#         var endBadBlock = text.find("\27[m\27[K\13\27[K", badBlock+2)
#         start = endBadBlock + 3
#         text.delete(badBlock, endBadBlock+10)

#       writeFile(fileKey, text)
#       echo "cached data in:", fileKey
#       result = parseOrbitalVectors(text)
#       send("n")
#       running = false


proc getOrbitalVectors*(
    hz: HorizonClient,
    fromTime: float64,
    toTime: float64,
    steps: int,
    targetId: int,
    observerId: int
  ): seq[OrbitalVectors] =
  let data = hz.getOrbitalData(
    "v",
    "JD " & $toJulianDate(fromTime),
    "JD " & $toJulianDate(toTime),
    $steps,
    targetId,
    observerId
  )
  return parseOrbitalVectors(data)


proc parseOrbitalElements*(data: string): seq[OrbitalElements] =
  var unit = AU
  var header, text: string
  var parts = data.split("*** START ***\n")
  header = parts[0]
  assert parts.len == 2
  text = parts[1]
  if "Output units    : KM-D" in header:
    unit = KM

  var orbitData = newSeq[OrbitalElements]()
  var entry: OrbitalElements

  var i = 0
  var
    EC, QR, IN, OM, W, Tp, N, MA, TA, A, AD, PR: float

  for line in text.split("\n"):
    if i mod 5 == 0:
      var oddTime : float64 = parseFloat(line[0..15])
      var time = Y2000 + (oddTime - J2000) * DAY
      #entry.time = time

    if line.startsWith(" EC="):
      EC = parseFloat(line[4..25].strip())
      QR = parseFloat(line[30..51].strip())
      IN = parseFloat(line[56..77].strip())

    if line.startsWith(" OM="):
      OM = parseFloat(line[4..25].strip())
      W = parseFloat(line[30..51].strip())
      Tp = parseFloat(line[56..77].strip())

    if line.startsWith(" N ="):
      N = parseFloat(line[4..25].strip())
      MA = parseFloat(line[30..51].strip())
      TA = parseFloat(line[56..77].strip())

    if line.startsWith(" A ="):
      A = parseFloat(line[4..25].strip())
      AD = parseFloat(line[30..51].strip())
      PR = parseFloat(line[56..77].strip())

      entry.om = OM # longitude of the ascending node
      entry.i = IN # inclination to the ecliptic (plane of the Earth's orbit)
      entry.w = W # argument of perihelion
      entry.a = A # semi-major axis, or mean distance from Sun
      entry.e = EC # eccentricity (0=circle, 0-1=ellipse, 1=parabola)
      entry.m = MA # mean anomaly (0 at perihelion increases uniformly with time)
      entry.n = N # mean motion

      orbitData.add entry

    inc i

  return orbitData


proc getOrbitalElements*(
    hz: HorizonClient,
    fromTime: float64,
    toTime: float64,
    steps: int,
    targetId: int,
    observerId: int
  ): seq[OrbitalElements] =
  let data = hz.getOrbitalData(
    "v",
    "JD " & $toJulianDate(fromTime),
    "JD " & $toJulianDate(toTime),
    $steps,
    targetId,
    observerId
  )
  return parseOrbitalElements(data)


