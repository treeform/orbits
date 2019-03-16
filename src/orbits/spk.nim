## Reads SPICE SPK DAF files. SPK files have .bsp extention.
## You can download many of the SPK files here: https://naif.jpl.nasa.gov/pub/naif/
##
## Based on the work by arrieta:
## https://gist.githubusercontent.com/arrieta/c2b56f1e2277a6fede6d1afbc85095fb/raw/70c43dd28804be9ba9f7c604fe3ad2742f8fa753/spk.py
##


import streams, print, httpclient, strutils, os
import vmath64
import simple

type
  StateVecs = object
    pos: Vec3
    vel: Vec3


iterator range(start, stop, step: int): int =
  var at = start
  if step < 0:
    while at > stop:
      yield at
      at += step
  else:
    while at < stop:
      yield at
      at += step


proc chebyshev(order: int, x: float, data: seq[float]): float =
  # Evaluate a Chebyshev polynomial
  var
    two_x = 2 * x
    bkp2 = data[order]
    bkp1 = two_x * bkp2 + data[order - 1]
  for n in range(order - 2, 0, -1):
    let bk = data[n] + two_x * bkp1 - bkp2
    bkp2 = bkp1
    bkp1 = bk
  return data[0] + x * bkp1 - bkp2


proc der_chebyshev(order: int, x: float, data: seq[float]): float =
  # Evaluate the derivative of a Chebyshev polynomial
  var
    two_x = 2 * x
    bkp2 = float(order) * data[order]
    bkp1 = two_x * bkp2 + float(order - 1) * data[order - 1]
  for n in range(order - 2, 1, -1):
    let bk = float(n) * data[n] + two_x * bkp1 - bkp2
    bkp2 = bkp1
    bkp1 = bk
  return data[1] + two_x * bkp1 - bkp2


type
  Spk = ref object
    records*: seq[Record]
    stream: Stream

  Record* = object
    etbeg*: float64
    etend*: float64
    target*: uint32
    observer*: uint32
    frame*: uint32
    rtype*: uint32
    rbeg*: uint32
    rend*: uint32

proc readSpk*(filename: string): Spk =

  var spk = Spk()

  var f = openFileStream(filename)
  spk.stream = f
  # make sure this is in the right file format
  if f.readStr(7) != "DAF/SPK":
    quit("invalid SPK signature")
  f.setPosition(88)
  # make sure this is little endian
  if f.readStr(8) != "LTL-IEEE":
    quit("SPK file is not little endian")
  f.setPosition(8)
  # make sure number of float64 per record and number of uint32 per record match
  if f.readInt32() != 2:
    quit("SPK file float64 per record does not match")
  if f.readInt32() != 6:
    quit("SPK file number of uint32 per record match")

  f.setPosition(76)
  let
    fward = f.readInt32()
    bward = f.readInt32()

  # extract summary records
  let
    summaryOffset = (fward - 1) * 1024
    summarySize = 2 + (6 + 1) div 2 # integer division
  f.setPosition(summaryOffset)

  while true:
    # read record chunks
    let
      nxt = f.readFloat64()
      prv = f.readFloat64()
      nsum = f.readFloat64()
    for n in 0..<int(nsum):
      var record = Record()
      record.etbeg = f.readFloat64()
      record.etend = f.readFloat64()
      record.target = f.readUInt32()
      record.observer = f.readUInt32()
      record.frame = f.readUInt32()
      record.rtype = f.readUInt32()
      record.rbeg = f.readUInt32()
      record.rend = f.readUInt32()
      spk.records.add record

    # if next chunk is zero we are done
    if int(nxt) == 0:
      break

  return spk


proc stateType2(et: float, order: int, data: seq[float64]): StateVecs =
  let
    tau = (et - data[0]) / data[1]
    deg = order + 1
    factor = 1.0 / data[1] # unscale time dimension
  result.pos.x = chebyshev(order, tau, data[2 + 0 * deg ..< 2 + 1 * deg])
  result.pos.y = chebyshev(order, tau, data[2 + 1 * deg ..< 2 + 2 * deg])
  result.pos.z = chebyshev(order, tau, data[2 + 2 * deg ..< 2 + 3 * deg])
  # type 2 uses derivative on the same polynomial
  result.vel.x = der_chebyshev(order, tau, data[2 + 0 * deg ..< 2 + 1 * deg]) * factor
  result.vel.y = der_chebyshev(order, tau, data[2 + 1 * deg ..< 2 + 2 * deg]) * factor
  result.vel.z = der_chebyshev(order, tau, data[2 + 2 * deg ..< 2 + 3 * deg]) * factor


proc stateType3(et: float, order: int, data: seq[float64]): StateVecs =
  let
    tau = (et - data[0]) / data[1]
    deg = order + 1
  result.pos.x = chebyshev(order, tau, data[2 + 0 * deg ..< 2 + 1 * deg])
  result.pos.y = chebyshev(order, tau, data[2 + 1 * deg ..< 2 + 2 * deg])
  result.pos.z = chebyshev(order, tau, data[2 + 2 * deg ..< 2 + 3 * deg])
  # type 3 stores its own velocity seperelty
  result.vel.x = chebyshev(order, tau, data[2 + 3 * deg ..< 2 + 4 * deg])
  result.vel.y = chebyshev(order, tau, data[2 + 4 * deg ..< 2 + 5 * deg])
  result.vel.z = chebyshev(order, tau, data[2 + 5 * deg ..< 2 + 6 * deg])


proc toEclip(sv: StateVecs): StateVecs =
  ## SPK files store everything in earth equatorial cordiantes JPL horizon calls "frame"
  ## But we like sun equatorial cordiantes which JPL horizon calls "ecliptic"
  let EarthObliquity = 23.4368 # axial tilt
  let m = rotate(EarthObliquity / 180 * PI, vec3(1,0,0))
  result.pos = m * sv.pos
  result.vel = m * sv.vel


proc stateVecAt*(spk: Spk, time: float64, target, observer: uint32): StateVecs =
  ## get orbital state: position and velocity
  var foundIndex = -1
  for i, record in spk.records:
    if record.target == target and record.observer == observer:
      if record.etbeg <= time and time <= record.etend:
        foundIndex = i
        break

  if foundIndex == -1:
    quit("No record found covering that et/target/observer combination")

  let record = spk.records[foundIndex]
  let offset = (record.rend - 4) * 8
  var f = spk.stream

  f.setPosition(int offset)
  let
    init = f.readFloat64()
    intlen = f.readFloat64()
    rsize = f.readFloat64()
    n = f.readFloat64()

  let internal_offset = floor((time - init) / intlen) * rsize
  let record_offset = 8 * (int(record.rbeg) + int(internal_offset))

  var order: int
  if record.rtype == 2:
    order = (int(rsize) - 2) div 3 - 1
  elif record.rtype == 3:
    order = (int(rsize) - 2) div 6 - 1
  else:
    quit("Only Types I and II are implemented")

  f.setPosition(record_offset - 8)
  var data: seq[float64]
  for i in 0..int(rsize):
    data.add f.readFloat64()

  if record.rtype == 2:
    return toEclip(stateType2(time, order, data))
  if record.rtype == 3:
    return toEclip(stateType3(time, order, data))
  else:
    quit("Only type 3 is implemented")


proc posAt*(spk: Spk, time: float64, target, observer: int): Vec3 =
  let years30 = 30 * 365.2568984 * 24*60*60
  let sv = spk.stateVecAt(time - years30, uint32 target, uint32 observer)
  return vec3(sv.pos.x, sv.pos.y, sv.pos.z) * 1000


proc velAt*(spk: Spk, time: float64, target, observer: int): Vec3 =
  let years30 = 30 * 365.2568984 * 24*60*60
  let sv = spk.stateVecAt(time - years30, uint32 target, uint32 observer)
  return vec3(sv.vel.x, sv.vel.y, sv.vel.z) * 1000


const allSpkUrls = staticRead("spkfiles.txt").splitLines()
proc downloadSpk*(fileName: string) =
  ## This function will download a unkown file
  if fileExists(fileName):
    return
  for url in allSpkUrls:
    if url.endsWith(fileName):
      echo "downloading: ", url
      var client = newHttpClient()
      client.downloadFile(url, fileName)
