## Downoads TLE data from celestrak.com / NORAD and combines them into 1 file


import httpclient, json, os, re, strutils, htmlparser, xmltree, sequtils
import simple, utils, tables, algorithm
import print



type
  TLE = object
    name: string
    group: string
    satnum: int
    classification: char
    intldesg: string
    epochdays: float
    ndot: float
    nddot: float
    bstar: float
    ephtype: char
    elnum: int
    inclo: float
    nodeo: float
    ecco: float
    argpo: float
    mo: float
    no_kozai: float
    revnum: int
    year: int
    nexp: int
    ibexp: int

var tles: Table[int, TLE]


proc parseFloat2(f: string): float =
  var f = f.strip()
  var sign: char
  if f[0] == '-':
    sign = f[0]
    f = f[1 .. ^1]
  if f[0] == '.':
    f = "0" & f
  result = parseFloat(f)
  if sign == '-':
    result = -result


proc parseInt2(i: string): int =
  parseInt(i.strip())


proc readTLE(tleFile: string) =
  let f = readFile(tleFile)

  var tle: TLE

  var two_digit_year: int
  var nexp: int
  var ibexp: int

  var i = 0
  for line in f.split("\n"):
    if i mod 3 == 0: # name line
      tle = TLE()
      tle.name = line.strip()
      tle.group = tleFile[6 .. ^5]
      echo line
    if i mod 3 == 1: # 1st line
      echo line

      tle.satnum = parseInt2(line[2 ..< 7])
      tle.classification = line[7]
      if tle.classification == ' ':
        tle.classification = 'U'
      tle.intldesg = line[9 ..< 17].strip()
      let twoDigitYear = parseInt2(line[18 ..< 20])
      if twoDigitYear < 57:
        tle.year = 2000 + twoDigitYear
      else:
        tle.year = 1900 + twoDigitYear
      tle.epochdays = parseFloat2(line[20 ..< 32])
      tle.ndot = parseFloat2(line[33 ..< 43])
      tle.nddot = parseFloat2(line[44] & '.' & line[45 ..< 50])
      tle.nexp = parseInt2(line[50 ..< 52])
      tle.bstar = parseFloat2(line[53] & '.' & line[54 ..< 59])
      tle.ibexp = parseInt2(line[59 ..< 61])
      tle.ephtype = line[62]
      tle.elnum = parseInt2(line[64 ..< 68])

    if i mod 3 == 2: # 2nd line
      echo line

      if tle.satnum != parseInt2(line[2 ..< 7]):
          raise newException(ValueError, "Object numbers in lines 1 and 2 do not match")

      tle.inclo = parseFloat2(line[8 ..< 16])
      tle.nodeo = parseFloat2(line[17 ..< 25])
      tle.ecco = parseFloat2("0." & line[26 ..< 33].replace(' ', '0'))
      tle.argpo = parseFloat2(line[34 ..< 42])
      tle.mo = parseFloat2(line[43 ..< 51])
      tle.no_kozai = parseFloat2(line[52 ..< 63])
      tle.revnum = parseInt2(line[63 ..< 68])

      tles[tle.satnum] = tle
    inc i


proc downloadTLEIndex() =
  downloadFileIfNotExists("https://www.celestrak.com/NORAD/elements/","cache/tle.html")
  var html = readFile("cache/tle.html")
  for line in html.split("\n"):
    if "<a href=\"" in line:
      let tleFile = line.cutBy("<a href=\"", "\">")
      if tleFile.endsWith(".txt"):
        let tleFileUrl = "https://www.celestrak.com/NORAD/elements/" & tleFile
        echo tleFileUrl
        downloadFileIfNotExists(tleFileUrl,"cache/" & tleFile)
        readTLE("cache/" & tleFile)


proc writeTLE() =
  var data = "satnum,name,group,classification,intldesg,year,epochdays,ndot,nddot,bstar,ephtype,elnum,inclo,nodeo,ecco,argpo,mo,no_kozai,revnum\n"
  for name in toSeq(tles.keys).sorted:
    let tle = tles[name]
    data.add $tle.satnum
    data.add ","
    data.add tle.name
    data.add ","
    data.add tle.group
    data.add ","
    data.add tle.classification
    data.add ","
    data.add tle.intldesg
    data.add ","
    data.add $tle.year
    data.add ","
    data.add $tle.epochdays
    data.add ","
    data.add $tle.ndot
    data.add ","
    data.add $tle.nddot
    data.add ","
    data.add $tle.bstar
    data.add ","
    data.add tle.ephtype
    data.add ","
    data.add $tle.elnum
    data.add ","
    data.add $tle.inclo
    data.add ","
    data.add $tle.nodeo
    data.add ","
    data.add $tle.ecco
    data.add ","
    data.add $tle.argpo
    data.add ","
    data.add $tle.mo
    data.add ","
    data.add $tle.no_kozai
    data.add ","
    data.add $tle.revnum
    data.add ","
    data.add $tle.ibexp
    data.add ","
    data.add $tle.revnum
    data.add "\n"

  writeFile("db/satellite.csv", data)

downloadTLEIndex()
writeTLE()