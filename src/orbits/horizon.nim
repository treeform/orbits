import net, streams, strutils, os, strutils, strformat
import vmath, print
import simple


type
  HorizonClient* = ref object
    socket: Socket
    debug*: bool # turn on debug spam

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
  hz.debug = false
  return hz


proc getOrbitalData*(
    hz: HorizonClient,
    format: string,
    fromTime: string,
    toTime: string,
    duration: string,
    targetId,
    observerId: int,
    cordinates: string,
    reference: string = "eclip"
  ): string =
  let fileKey = (&"cache/{format} {fromTime} {toTime} {duration} {$targetId} {$observerId} {cordinates} {reference}.txt"
    ).replace(":", " ").replace("-", " ").replace(",", "_")
  if existsFile(fileKey):
    if hz.debug:
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
    if hz.debug:
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

    if hz.debug:
      echo lastLine

    if promt("Horizons> "):
      send($targetId)
    if "Select ..." in lastLine and promt("<cr>: "):
      send("E")
    if promt("Observe, Elements, Vectors  [o,e,v,?] : "):
      send(format)

    if cordinates != "":
      # rotation
      if "Coordinate" in lastLine and "center" in lastLine and promt("] : "):
        send("c@" & $targetId)
      # tons of stuff don't have rotation information, just skip it then
      if backLines.len > 3:
        if "Cannot find station file" in backLines[^3] or "No rotational model for center body" in backLines[^3] or "Cannot find central body matching" in backLines[^3]:
          send "x"
          return ""
      if "Cylindrical or Geodetic input" in lastLine and promt("] : "):
        send("g")
      if "Specify geodetic" in lastLine and promt("} : "):
        send(cordinates)
      if "Confirm selected station" in lastLine and promt("--> "):
        send("y")
    else:
      # position
      if "Coordinate" in lastLine and "center" in lastLine and promt("] : "):
        send("@" & $observerId)

    if " Use previous center" in lastLine and promt("] : "):
      send("n")
    if promt("Reference plane [eclip, frame, body ] : "):
      #send("eclip")
      send(reference)

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
      if hz.debug:
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
      var p = dvec3(
        parseFloat(line[4..25].strip()),
        parseFloat(line[30..51].strip()),
        parseFloat(line[56..77].strip()))
      p = p * unit
      entry.pos = p

    if line.startsWith(" VX"):
      var v = dvec3(
        parseFloat(line[4..25].strip()),
        parseFloat(line[30..51].strip()),
        parseFloat(line[56..77].strip()))
      v = v * unit / DAY
      entry.vel = v
      orbitData.add(entry)

    if line.startsWith("VX"):
      var v = dvec3(
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


proc getOrbitalVectorsSeq*(
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
    observerId,
    ""
  )
  return parseOrbitalVectors(data)


proc getOrbitalVectors*(
    hz: HorizonClient,
    time: float64,
    targetId: int,
    observerId: int
  ): OrbitalVectors =
  let data = hz.getOrbitalData(
    "v",
    "JD " & $toJulianDate(time),
    "JD " & $toJulianDate(time + DAY),
    "2",
    targetId,
    observerId,
    ""
  )
  return parseOrbitalVectors(data)[0]


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

      entry.o = OM # longitude of the ascending node
      entry.i = IN # inclination to the ecliptic (plane of the Earth's orbit)
      entry.w = W # argument of perihelion
      entry.a = A # semi-major axis, or mean distance from Sun
      entry.e = EC # eccentricity (0=circle, 0-1=ellipse, 1=parabola)
      entry.m = MA # mean anomaly (0 at perihelion increases uniformly with time)
      entry.n = N # mean motion

      orbitData.add entry

    inc i

  return orbitData


proc getOrbitalElementsSeq*(
    hz: HorizonClient,
    fromTime: float64,
    toTime: float64,
    steps: int,
    targetId: int,
    observerId: int
  ): seq[OrbitalElements] =
  ## Get a sequence of OrbitalElements
  let data = hz.getOrbitalData(
    "e",
    "JD " & $toJulianDate(fromTime),
    "JD " & $toJulianDate(toTime),
    $steps,
    targetId,
    observerId,
    ""
  )
  return parseOrbitalElements(data)


proc getOrbitalElements*(
    hz: HorizonClient,
    time: float64,
    targetId: int,
    observerId: int
  ): OrbitalElements =
  ## Get a single set of OrbitalElements at a given time
  let data = hz.getOrbitalData(
    "e",
    "JD " & $toJulianDate(time),
    "JD " & $toJulianDate(time+DAY),
    "2",
    targetId,
    observerId,
    ""
  )
  return parseOrbitalElements(data)[0]


proc getRadius*(
    hz: HorizonClient,
    time: float64,
    targetId: int
  ): float =
  ## Gets the radius of the body in meters
  let data = hz.getOrbitalData(
    "v",
    "JD " & $toJulianDate(time),
    "JD " & $toJulianDate(time+DAY),
    "2",
    targetId,
    targetId,
    "0,0,0"
  )
  var ov = parseOrbitalVectors(data)[0]
  return ov.pos.length


proc getRotationAxis*(
    hz: HorizonClient,
    time: float64,
    targetId: int
  ): DVec3 =
  ## Get a normalized vector that the body rotation around.
  let data = hz.getOrbitalData(
    "v",
    "JD " & $toJulianDate(time),
    "JD " & $toJulianDate(time+DAY),
    "2",
    targetId,
    targetId,
    "0,-90,0",
    "eclip"
  )
  var ov = parseOrbitalVectors(data)[0]
  return ov.pos.normalize()


proc getRotationAngularSpeed*(
    hz: HorizonClient,
    time: float64,
    targetId: int
  ): float =
  ## Get the rotation angular speed in rad/second
  let timeScale: float = 60 * 60
  let data = hz.getOrbitalData(
    "v",
    "JD " & $toJulianDate(time),
    "JD " & $toJulianDate(time + timeScale * 25),
    "1h",
    targetId,
    targetId,
    "0,0,0"
  )
  for i in 0..<24:
    let
      vec1 = parseOrbitalVectors(data)[i].pos
      vec2 = parseOrbitalVectors(data)[i+1].pos
    result += vec1.angleBetween(vec2) / timeScale
  result = result / 24
