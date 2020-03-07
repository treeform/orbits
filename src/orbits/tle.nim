## Downoads TLE data from celestrak.com / NORAD and combines them into 1 file


import httpclient, json, os, re, strutils, htmlparser, xmltree, sequtils, strformat
import simple, utils, tables, algorithm
import print


const cacheDir = "D:/cache"


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

type
  SatInfo = object
    id: int
    name: string
    cosparId: string
    orbit: string
    orbitDecayedDate: string
    landedDate: string
    periapsis: float
    apoapsis: float
    inclination: float
    category: string
    country: string
    launchDate: string
    launchSite: string
    launchVehicle: string
    description: string
    mass: int
    image: string
    intrinsicBrightness: string
    maxBrightness: string

var satInfos: Table[int, SatInfo]

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
  downloadFileIfNotExists("https://www.celestrak.com/NORAD/elements/", cacheDir / "tle.html")
  var html = readFile(cacheDir / "tle.html")
  for line in html.split("\n"):
    if "<a href=\"" in line:
      let tleFile = line.cutBy("<a href=\"", "\">")
      if tleFile.endsWith(".txt"):
        let tleFileUrl = "https://www.celestrak.com/NORAD/elements/" & tleFile
        echo tleFileUrl
        downloadFileIfNotExists(tleFileUrl, cacheDir / "" & tleFile)
        readTLE( cacheDir / "" & tleFile)


proc heavensAbove(id: int) =
  downloadFileIfNotExists(&"https://www.heavens-above.com/satinfo.aspx?satid={id}", cacheDir / &"satinfo_{id}.html")
  var html = readFile(cacheDir / &"satinfo_{id}.html")
  var satInfo = SatInfo()
  for line in html.split("\n"):

    let satID = line.cutBy("<span id=\"ctl00_cph1_lblSatID\">", "</span>")
    if satID.len > 0:
      #print satID
      satInfo.id = parseInt(satID)
    let cosparId = line.cutBy("<span id=\"ctl00_cph1_lblIntDesig\">", "</span>").strip()
    if cosparId.len > 0:
      #print cosparId
      satInfo.cosparId = cosparId
    let name = line.cutBy("<span id=\"ctl00_cph1_lblOIGName\">", "</span>")
    if name.len > 0:
      #print name
      satInfo.name = name
    var orbit = line.cutBy("<span id=\"ctl00_cph1_lblOrbit\">", "</span>")
    if orbit.len > 0:
      orbit = orbit.replace("&nbsp;", " ")
      #print orbit
      satInfo.orbit = orbit
      if orbit.startsWith("decayed"):
        var orbitDecayedDate = orbit[8 .. ^1]
        #print orbitDecayedDate
        satInfo.orbitDecayedDate = orbitDecayedDate
      if orbit.startsWith("landed"):
        var landedDate = orbit[7 .. ^1]
        #print landedDate
        satInfo.landedDate = landedDate
      if " x " in orbit:
        let orbitParts = orbit.split(" ")
        var periapsis = orbitParts[2]
        var apoapsis = orbitParts[0]
        var inclination = orbitParts[4].replace("\xC2\xB0", "")
        #print periapsis, apoapsis, inclination
        satInfo.periapsis = parseFloat periapsis.replace(",", "")
        satInfo.apoapsis = parseFloat apoapsis.replace(",", "")
        satInfo.inclination = parseFloat inclination

    let category = line.cutBy("<span id=\"ctl00_cph1_lblCategory\"><tr><td>Category </td><td>", "</td></tr></span>").strip()
    if category.len > 0:
      #print category
      satInfo.category = category
    let country = line.cutBy("<td>Country/organisation of origin </td><td>", "</td></tr></span>")
    if country.len > 0:
      #print country
      satInfo.country = country
    let launchDate = line.cutBy("<span id=\"ctl00_cph1_lblLaunchDate\">", "</span>")
    if launchDate.len > 0:
      #print launchDate
      satInfo.launchDate = launchDate
    var launchSite = line.cutBy("Launch site</td><td>", "</td></tr></span>")
    if launchSite.len > 0:
      launchSite = launchSite.replace("<br />", "")
      #print launchSite
      satInfo.launchSite = launchSite
    let launchVehicle = line.cutBy("<span id=\"ctl00_cph1_lblaunchVehicle\">", "</span>")
    if launchVehicle.len > 0:
      #print launchVehicle
      satInfo.launchVehicle = launchVehicle
    let description = line.cutBy("Description</strong><br /><table width=\"600\"><tr><td>", "</td></tr></table></span>")
    if description.len > 0:
      #print description
      satInfo.description = description
    let mass = line.cutBy("Mass </td><td>", "</td>")
    if mass.len > 0:
      #print mass
      satInfo.mass = parseInt mass.split(" ")[0]
    var image = line.cutBy("<img id=\"ctl00_cph1_imgSat\" src=\"", "\"")
    if image.len > 0:
      image = "https://www.heavens-above.com/" & image
      #print image
      satInfo.image = image
    var intrinsicBrightness = line.cutBy("Intrinsic brightness (Magnitude) </td><td>", "</td>")
    if intrinsicBrightness.len > 0:
      if intrinsicBrightness == "?":
        intrinsicBrightness = ""
      #print intrinsicBrightness
      satInfo.intrinsicBrightness = intrinsicBrightness
    var maxBrightness = line.cutBy("Maximum brightness (Magnitude)</td><td>", "</td>")
    if maxBrightness.len > 0:
      #print maxBrightness
      satInfo.maxBrightness = maxBrightness

  print satInfo.id, satInfo.name

  satInfos[satInfo.id] = satInfo


proc q(s: string): string =
  if "," in s or " " in s:
    return "\"" & s & "\""

proc q(s: SomeNumber): string =
  $s

proc writeSatelliteHistorical() =
  var data = "id,name,cosparId,orbit,orbitDecayedDate,landedDate,periapsis,apoapsis,inclination,category,country,launchDate,launchSite,launchVehicle,description,mass,image,intrinsicBrightness,maxBrightness\n"
  for id in toSeq(satInfos.keys).sorted:
    let satInfo = satInfos[id]
    data.add q satInfo.id
    data.add ","
    data.add q satInfo.name
    data.add ","
    data.add q satInfo.cosparId
    data.add ","
    data.add q satInfo.orbit
    data.add ","
    data.add q satInfo.orbitDecayedDate
    data.add ","
    data.add q satInfo.landedDate
    data.add ","
    data.add q satInfo.periapsis
    data.add ","
    data.add q satInfo.apoapsis
    data.add ","
    data.add q satInfo.inclination
    data.add ","
    data.add q satInfo.category
    data.add ","
    data.add q satInfo.country
    data.add ","
    data.add q satInfo.launchDate
    data.add ","
    data.add q satInfo.launchSite
    data.add ","
    data.add satInfo.launchVehicle
    data.add ","
    data.add q satInfo.description
    data.add ","
    data.add q satInfo.mass
    data.add ","
    data.add q satInfo.image
    data.add ","
    data.add q satInfo.intrinsicBrightness
    data.add ","
    data.add q satInfo.maxBrightness
    data.add "\n"

  writeFile("db/satelliteHistorical.csv", data)


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

  data = "satnum,name,group,classification,intldesg\n"
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
    data.add "\n"
  writeFile("db/satelliteNames.csv", data)

# downloadTLEIndex()
# writeTLE()

for id in 1 .. 18723:
  #print "-------------"
  heavensAbove(id)
  writeSatelliteHistorical()