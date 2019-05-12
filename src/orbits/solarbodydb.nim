## Solor body downloads differnet databases from JPL Propulsion LIbratory
## And combines them into one.


import httpclient, json, os, re, strutils, htmlparser, xmltree, sequtils
import simple, utils
import print

type
  Body = object
    id: int
    parentId: int
    name: string
    meanRadiusM: float
    massKg: float
    albedo: float

    gm: float # G * mass
    equatorialRadiusM: float
    densityKgM3: float
    siderealRotationPeriodS: float
    orbitRotationPeriodS: float
    equatorialGravity: float
    escapeVelocityM: float


var bodies: seq[Body]


proc constantsParser*() =
  downloadFileIfNotExists("https://ssd.jpl.nasa.gov/?constants","cache/constants.html")
  var html = readFile("cache/constants.html").replace("&nbsp;", " ").replace("&#177;","+-").replace("<sup>-11</sup> kg<sup>-1</sup> m<sup>3</sup> s<sup>-2</sup><sub> </sub>", "")
  var values = html.findAll(re"""<td align="left" nowrap>(.*)</td>""")
  proc fix(a: string): string = a.replace("""<td align="left" nowrap>""", "").replace("</td>", "").strip()
  for i, v in values:
    if i + 1 >= values.len: break
    let
      name = fix(v)
      value = fix(values[i+1])
    if name in [
        "speed of light",
        "Julian day",
        "Julian year",
        "Julian century",
        "astronomical unit",
        "mean sidereal day",
        "sidereal year",
        "gravitational constant",
      ]:
      echo name, " = ", value


proc planetsParser*() =
  downloadFileIfNotExists("https://ssd.jpl.nasa.gov/?planet_phys_par","cache/planets.html")
  var html = readFile("cache/planets.html")
  var table = html.cutBy("""    <td align="center" nowrap>(km s<sup>-1</sup>)</td>
  </tr>""",
"""<h3>References</h3>""")
  var text = table.replacef(re"<(\w*)[^>]*>", "")
  text = text.replace("&nbsp;", " ").replace("&#177;","+-")
  text = text.replace(re"\s+", " ")
  text = text.replacef(re"([A-Z][a-z]+)", "\n$1")

  proc p(num: string): float =
    parseFloat(num.split("+-")[0])

  var body = Body()
  body.id = 0
  body.parentId = 0
  body.name = "Solar System Barycenter (SSB)"
  body.massKg = 1.989E30
  body.gm = body.massKg * G
  bodies.add(body)

  body = Body()
  body.id = 10
  body.parentId = 0
  body.name = "Sun"
  body.massKg = 1.989E30
  body.gm = body.massKg * G
  body.equatorialRadiusM = 6.957E8
  body.meanRadiusM = 6.957E8
  body.siderealRotationPeriodS = 25.05*24*60*60
  bodies.add(body)

  var planetId = 1
  for line in text.strip().splitLines():
    var args = line.split(" ")
    # barycenter
    var body = Body()
    body.id = planetId
    body.parentId = planetId
    body.name = args[0] & " Barycenter"
    if planetId == 3: body.name = "Earth-Moot Barycenter"
    if planetId == 9: body.name = "Pluto-Charon Barycenter"
    body.massKg = p(args[5]) * 1E+24
    body.gm = body.massKg * G
    body.orbitRotationPeriodS = p(args[11])*24*60*60*365.25
    bodies.add(body)
    inc planetId

  # body itself
  planetId = 1
  for line in text.strip().splitLines():
    var args = line.split(" ")
    var body = Body()
    body.id = planetId * 100 + 99
    body.parentId = planetId
    body.name = args[0]
    body.equatorialRadiusM = p(args[1])*1000
    body.meanRadiusM = p(args[3])*1000
    body.massKg = p(args[5]) * 1E+24
    body.gm = body.massKg * G
    body.densityKgM3 = p(args[7]) * 1000
    body.siderealRotationPeriodS = p(args[9])*24*60*60
    body.orbitRotationPeriodS = p(args[11])*24*60*60*365.25
    body.albedo = p(args[15])
    body.equatorialGravity = p(args[17])
    body.escapeVelocityM = p(args[19]) * 1000
    bodies.add(body)

    inc planetId


proc satellitesParser*() =
  downloadFileIfNotExists("https://ssd.jpl.nasa.gov/?sat_phys_par","cache/satellites.html")
  var html = readFile("cache/satellites.html")
  var table = html.cutBy("""<a href="?lunar_doc">JPL lunar constants and models technical document</a>
is also available.
</p>""",
"""<H3><A NAME="legend">Table Column Headings</A></H3>""")
  table = table.replace("<TD ALIGN=left>", "name:")
  var text = table.replacef(re"<(\w*)[^>]*>", "")
  text = text.replace("&nbsp;", " ").replace("&nbsp", " ").replace("&#177;","+-")
  text = text.replace(re"\s+", " ")
  text = text.replace("name:", "\n")
  text = text.replacef(re"\]([^\]]*GM \(km3/sec2\))", "]\n---- $1")
  text = "---- " & text
  #text = text.replacef(re"([A-Z][a-z//\d]+)", "\n$1")
  #var moons = text.split("GeometricAlbedo")
  echo text

  var
    planetId = 2
    moonId = 1

  for line in text.strip().splitLines():
    if line.startsWith("----"):
      inc planetId
      moonId = 1
      continue
    var args = line.split(" ")
    if args[0].startsWith("S/20"):
      args[0].add " " & args[1]
      args.delete(1)

    proc p(num: string): float =
      if num == "?": return 0
      parseFloat(num.split(re"(\+\-|\[)")[0])
    var body = Body()
    body.id = planetId * 100 + moonId
    body.parentId = planetId
    body.name = args[0]
    body.gm = p(args[1]) * 1000000000.0
    body.massKg = body.gm / G
    body.meanRadiusM = p(args[2])*1000
    body.densityKgM3 = p(args[3])*1000
    body.albedo = p(args[5])
    bodies.add(body)
    inc moonId


proc smallBodyParser*() =
  var filePath = "cache/smallBody.csv"
  if not existsFile(filePath):
    var client = newHttpClient()
    let url = "https://ssd.jpl.nasa.gov/sbdb_query.cgi"
    var data = newMultipartData()
    data["obj_group"] = "all"
    data["obj_kind"] = "all"
    data["obj_numbered"] = "all"
    data["OBJ_field"] = "0"
    data["OBJ_op"] = "0"
    data["OBJ_value"] = ""
    data["ORB_field"] = "0"
    data["ORB_op"] = "0"
    data["ORB_value"] = ""
    data["c_fields"] = "AbAeAtApArBgBhBiBjBkBlBmBnBoBr"
    data["table_format"] = "CSV"
    data["max_rows"] = "500"
    data["format_option"] = "full"
    data["query"] = "Generate Table"
    data[".cgifields"] = "format_option"
    data[".cgifields"] = "field_list"
    data[".cgifields"] = "obj_kind"
    data[".cgifields"] = "obj_group"
    data[".cgifields"] = "obj_numbered"
    data[".cgifields"] = "ast_orbit_class"
    data[".cgifields"] = "table_format"
    data[".cgifields"] = "OBJ_field_set"
    data[".cgifields"] = "ORB_field_set"
    data[".cgifields"] = "preset_field_set"
    data[".cgifields"] = "com_orbit_class"
    var csv = client.postContent(url, multipart=data)
    writeFile(filePath, csv)
  var csv = readFile(filePath)
  var i = 0
  for line in csv.splitLines()[0..100]:
    if i == 0:
      inc i
      continue
    var args = line.split(",")
    #echo args
    proc p(num: string): float =
      if num == "": return 0
      let num2 = num.split(re"[^\d.+-eE]")[0]
      if num2 == "": return 0
      parseFloat(num2)

    var body = Body()
    body.id = parseInt(args[0])
    body.name = args[1]
    body.gm = p(args[2]) * 1000000000.0
    body.massKg = body.gm / G
    body.meanRadiusM = p(args[3])/2*1000
    body.albedo = p(args[4])
    bodies.add(body)

    inc i


proc writeBodyDb() =
  var s = "id,parentId,name,massKg,meanRadiusM,albedo,gm,equatorialRadiusM,densityKgM3,siderealRotationPeriodS,orbitRotationPeriodS,equatorialGravity,escapeVelocityM\n"
  for body in bodies:
    s.add $body.id & ","
    s.add $body.parentId & ","
    s.add body.name & ","
    s.add $body.massKg & ","
    s.add $body.meanRadiusM & ","
    s.add $body.albedo & ","
    s.add $body.gm & ","
    s.add $body.equatorialRadiusM & ","
    s.add $body.densityKgM3 & ","
    s.add $body.siderealRotationPeriodS & ","
    s.add $body.orbitRotationPeriodS & ","
    s.add $body.equatorialGravity & ","
    s.add $body.escapeVelocityM & ","
    s.add "\n"
  writeFile("cache/body.db", s)

#constantsParser()
planetsParser()
satellitesParser()
smallBodyParser()

writeBodyDb()