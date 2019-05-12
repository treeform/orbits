import flippy, vmath, random, print, chroma, json, strutils
import quickcairo


type Star = object
  id: int
  name: string
  otherName: string
  th: float
  ph: float
  luma: float
  pos: Vec3

type StarTri = object
  aID, bID, cID: int
  ab, bc, ca: float

var brightStars: seq[Star]
var starTris: seq[StarTri]

proc toRad(v: float): float =
  v / 180 * PI


proc readBrightStars() =
  let brightStarsJson = parseJson(readFile("src/orbits/brightstars.json"))
  var id = 0
  for star in brightStarsJson:
    var star = Star(
      name: star[0].getStr().replace("\xC3\x8E\xC2", "\xCE"),
      otherName: star[1].getStr(),
      ph: star[2].getFloat(),
      th: star[3].getFloat() + 90,
      luma: star[4].getFloat()
    )
    #if "U" notin star.name: continue
    #if star.luma > 5: continue
    star.id = id
    star.pos = -vec3(
      sin(star.th.toRad) * cos(star.ph.toRad),
      sin(star.th.toRad) * sin(star.ph.toRad),
      cos(star.th.toRad)
    )
    brightStars.add star
    inc id



proc normalize(tri: var StarTri) =
  let maxDist = max([tri.ab, tri.bc, tri.ca])
  tri.ab /= maxDist
  tri.bc /= maxDist
  tri.ca /= maxDist
  # sort tri
  if tri.ca > tri.bc:
    (tri.bId, tri.cId) = (tri.cId, tri.bId)
    (tri.bc, tri.ca) = (tri.ca, tri.bc)
  if tri.bc > tri.ab:
    (tri.aId, tri.bId) = (tri.bId, tri.aId)
    (tri.ab, tri.bc) = (tri.bc, tri.ab)


proc genStarTris() =
  const minDist = 0.2
  for a in brightStars:
    for b in brightStars:
      if a.id != b.id:
        var ab = dist(a.pos, b.pos)
        if ab < minDist:
          #print "star pair", a.id, b.id, ab
          for c in brightStars:
            if a.id != c.id and b.id != c.id:
              var bc = dist(b.pos, c.pos)
              if bc < minDist:
                #print "  star tri", a.id, b.id, c.id, ab, bc
                var ca = dist(c.pos, a.pos)
                var tri = StarTri(
                  aID: a.id, bID: b.id, cID: c.id,
                  ab: ab, bc: bc, ca: ca
                )
                tri.normalize()
                if brightStars[tri.aID].otherName == "Dubhe" and
                  brightStars[tri.bID].otherName == "Megrez" and
                  brightStars[tri.cID].otherName == "Merak":
                  starTris.add tri

  print "genreated: ", starTris.len

proc drawMilkyWay() =
  var
    surface = imageSurfaceCreate(FORMAT.argb32, 1000, 500)
    ctx = surface.newContext()
  ctx.selectFontFace("Sans", FONT_SLANT.normal, FONT_WEIGHT.normal)
  ctx.setFontSize(12.0)

  ctx.setSource(0.11, 0.14, 0.42, 1)
  ctx.rectangle(0, 0, float surface.width, float surface.height)
  ctx.fill()

  for star in brightStars:
    var s = 2/(star.luma + 1.44 + 1)
    let
      x = (star.ph / 360) * 1000
      y = (star.th / 180) * 500
    ctx.setSource(1, 1, 1, 1)
    ctx.newPath()
    ctx.arc(
      x,
      y,
      s,
      0.0, 2.0*PI)
    ctx.fill()
    ctx.closePath()

  discard surface.writeToPng("tests/milkyway.png")


proc drawStars3d() =

  # 3d
  var
    surface = imageSurfaceCreate(FORMAT.argb32, 1000, 1000)
    ctx = surface.newContext()
  ctx.setSource(0.11, 0.14, 0.42, 0.75)
  ctx.rectangle(0, 0, float surface.width, float surface.height)
  ctx.fill()

  ctx.translate(500, 500)

  var lookAtPos: Vec3
  for star in brightStars:
    if star.otherName == "Polaris":
      lookAtPos = star.pos

  var proj = perspective(40, 1, 0.01, 20)
  var mat = lookAt(-lookAtPos, vec3(0,0,0), vec3(0,0,1))
  #var mat = rotateX(0.toRad)
  for star in brightStars:
    var pos = proj * mat * star.pos
    pos.x /= pos.z
    pos.y /= pos.z
    if pos.z < 0: continue
    #if "UMi" notin star.name and "UMa" notin star.name: continue
    var s = 10/(star.luma + 1.44 + 1)
    ctx.setSource(1, 1, 1, 1)

    ctx.newPath()
    ctx.arc(
      pos.x*500,
      pos.y*500,
      s,
      0.0, 2.0*PI)
    ctx.fill()
    ctx.closePath()

    if star.otherName in ["Polaris", "Pherkad", "Kochab", "Yildun", "Kochab"]: #,    "Dubhe", "Merak", "Megrez", "Phecda", "Alioth", "Alcor", "Mizar", "Alkaid"]:
      ctx.setSource(1, 0, 0, 0.5)
      ctx.newPath()
      ctx.arc(
        pos.x*500,
        pos.y*500,
        10,
        0.0, 2.0*PI)
      ctx.stroke()
      ctx.closePath()

    if star.otherName in ["Dubhe", "Merak", "Megrez", "Phecda", "Alioth", "Alcor", "Mizar", "Alkaid"]:
      ctx.setSource(0, 1, 0, 0.5)
      ctx.newPath()
      ctx.arc(
        pos.x*500,
        pos.y*500,
        10,
        0.0, 2.0*PI)
      ctx.stroke()
      ctx.closePath()

  discard surface.writeToPng("tests/brightstars3d.png")


proc analyzeImage() =

  const keepBrightSpots = 50

  var img = loadImage("tests/bigdipper.png")
  var mipmaps: seq[Image]
  while img.width > 50 and img.height > 50:
    mipmaps.add img
    img = img.minifyBy2()
    print img.width
  echo "minified"

  var
    image = imageSurfaceCreateFromPng("tests/bigdipper.png")
    surface = imageSurfaceCreate(FORMAT.argb32, image.width, image.height)
    ctx = surface.newContext()

  ctx.setSourceSurface(image, 0, 0)
  ctx.paint()

  ctx.selectFontFace("Sans", FONT_SLANT.normal, FONT_WEIGHT.normal)
  ctx.setFontSize(12.0)

  ctx.setSource(0.11, 0.14, 0.42, 0.75)
  ctx.rectangle(0, 0, float surface.width, float surface.height)
  ctx.fill()

  ctx.setSource(1, 1, 1, 1)
  ctx.setLineWidth(1)

  proc luma(rgba: ColorRGBA): float =
    return (float(rgba.r)/255.0 + float(rgba.g)/255.0 + float(rgba.b)/255.0)/3.0

  type Spot = object
    x, y: int
    luma: float

  proc pos(spot: Spot): Vec2 =
    vec2(float spot.x, float spot.y)

  proc `pos=`(spot: var Spot, pos: Vec2) =
    spot.x = int pos.x
    spot.y = int pos.y

  # find the brighest spot the the lowest mip level
  var brightestN: seq[Spot]
  proc insertSort(brightest: var seq[Spot], spot: Spot, num: int) =
    for i, s in brightest:
      if spot.luma > s.luma:
        brightest.insert(spot, i)
        if brightest.len > num:
          brightest.setLen(num)
        return
    if brightest.len < num:
      brightest.add(spot)
  let mostBlurLevel = mipmaps.len - 1
  let mostBlur = mipmaps[^1]
  for x in 0 ..< mostBlur.width:
    for y in 0 ..< mostBlur.height:
      let spot = Spot(x:x, y:y, luma:luma(mostBlur.getRgba(x, y)))
      brightestN.insertSort(spot, keepBrightSpots)


  # adjust each spot in accuracy as we walk up the mip levels
  for spot in brightestN.mitems:
    for mipLevel in 0..<mipmaps.len - 1:
      var
        bestX, bestY: int
        bestLuma = 0.0
      for a in -2..3:
        for b in -2..3:
          let
            thisX = spot.x * 2 + a
            thisY = spot.y * 2 + b
            thisLuma = luma(mipmaps[^(mipLevel + 2)].getRgbaSafe(thisX, thisY))
          if bestLuma < thisLuma:
            bestLuma = thisLuma
            bestX = thisX
            bestY = thisY
      spot.x = bestX
      spot.y = bestY
      spot.luma = bestLuma


  # combine spots as some of them are so close they should merge
  var merged: seq[Spot]
  for a, spotA in brightestN:
    var spotA = spotA
    var merge = true
    for b, spotB in merged:
      if dist(vec2(float spotA.x, float spotA.y), vec2(float spotB.x, float spotB.y)) < 10:
        merge = false
        if spotB.luma > spotA.luma:
          spotA.luma = spotB.luma
    if merge:
      merged.add spotA

  brightestN = merged

  for spot in brightestN:

    ctx.newPath()
    ctx.setLineWidth(spot.luma*2)
    ctx.arc(
      float spot.x,
      float spot.y,
      10,
      0.0, 2.0*PI)
    ctx.stroke()
    ctx.closePath()

    # ctx.save()
    # ctx.moveTo(float spot.x + 15, float spot.y)
    # ctx.showText("Luma: " & $spot.luma)
    # ctx.restore()

  print brightestN.len
  discard surface.writeToPng("tests/bigdipper_stars.png")


  var
    thisTri: StarTri
  thisTri.aID = 0
  thisTri.bID = 1
  thisTri.cID = 2
  thisTri.ab = dist(brightestN[0].pos, brightestN[1].pos)
  thisTri.bc = dist(brightestN[1].pos, brightestN[2].pos)
  thisTri.ca = dist(brightestN[2].pos, brightestN[0].pos)
  thisTri.normalize()

  print thisTri
  var posTrans = -brightestN[thisTri.aID].pos + vec2(float surface.width, float surface.height) / 2.0
  print posTrans
  for b in brightestN.mitems:
    b.pos = (b.pos + posTrans)

  ctx.setSource(0.11, 0.14, 0.42, 1)
  ctx.rectangle(0, 0, float surface.width, float surface.height)
  ctx.fill()

  ctx.save()
  ctx.setSourceSurface(image, 0, 0)
  ctx.paint()
  ctx.setSource(0.11, 0.14, 0.42, 0.75)
  ctx.rectangle(0, 0, float surface.width, float surface.height)
  ctx.fill()
  ctx.restore()

  ctx.translate(-posTrans.x, -posTrans.y)

  ctx.setSource(1, 1, 1, 1)
  ctx.setLineWidth(1)
  for i, id in [thisTri.aID, thisTri.bID, thisTri.cID]:
    let spot = brightestN[id]
    ctx.newPath()
    print spot
    ctx.arc(
      float spot.x,
      float spot.y,
      10,
      0.0, 2.0*PI)
    ctx.stroke()
    ctx.closePath()
    ctx.save()
    ctx.moveTo(float spot.x + 15, float spot.y)
    ctx.showText("    #" & $i)
    ctx.restore()

  for spot in brightestN:
    ctx.newPath()
    ctx.arc(
      float spot.x,
      float spot.y,
      5,
      0.0, 2.0*PI)
    ctx.stroke()
    ctx.closePath()

  var goodPixDist = float(max(surface.width, surface.height)) * 0.01
  var bestError = 1000.0
  var bestMatches = 0
  var bestMat: Mat4
  var bestTri: StarTri
  for tri in starTris:

    let minError = pow(thisTri.bc - tri.bc, 2) + pow(thisTri.ca - tri.ca, 2)
    print minError
    if true or minError < 0.8:
      bestError = minError
      # solve for matrix that:
      # brightestN[tri.aID].pos == mat * brightStars[tri.aID]
      # brightestN[tri.aID].pos == mat * brightStars[tri.aID]
      # brightestN[tri.aID].pos == mat * brightStars[tri.aID]

      # look at first star
      var mat = lookAt(brightStars[tri.aID].pos, vec3(0,0,0), vec3(0,0,1))


      # make sure rotation between first and second screen spot
      # match the rotation between first and second star
      let
        posA = mat * brightStars[tri.aID].pos
        posB = mat * brightStars[tri.bID].pos
        starAngle = arctan2(posB.y - posA.y, posB.x - posA.x)
        spotA = brightestN[thisTri.aID].pos
        spotB = brightestN[thisTri.bID].pos
        spotAngle = arctan2(spotB.y - spotA.y, spotB.x - spotA.x)
      mat = rotateZ(starAngle - spotAngle) * mat

      # make sure that the distance between first and second spot
      # match the distance between frist and second star
      let zoom = dist(brightestN[thisTri.aID].pos, brightestN[thisTri.bID].pos)
      let zoom2 = dist(mat * brightStars[tri.aID].pos, mat * brightStars[tri.bID].pos)
      mat = scaleMat((zoom/zoom2)) * mat

      # translate the stars into screen center
      mat = translate(vec3(float(surface.width)/2.0,  float(surface.height)/2.0, 0.0)) * mat

      # compute error of the thrid star and spot

      var error = dist((mat * brightStars[tri.cID].pos).xy, brightestN[thisTri.cID].pos)

      if error < goodPixDist:
        # test all stars against bright spots
        var matches = 0
        for star in brightStars:
          var pos = mat * star.pos
          for spot in brightestN:
            if dist(spot.pos, pos.xy) < goodPixDist:
              inc matches
        if matches > bestMatches:
          bestMatches = matches
          bestMat = mat
          bestTri = tri
          print bestMatches

  for i, id in [bestTri.aId, bestTri.bId, bestTri.cId]:
    let star = brightStars[id]
    var pos = bestMat * star.pos
    ctx.setSource(0, 1, 0, 1)
    ctx.newPath()
    ctx.arc(
      pos.x,
      pos.y,
      goodPixDist/2,
      0.0, 2.0*PI)
    ctx.stroke()
    ctx.closePath()
    ctx.save()
    ctx.moveTo(float pos.x, float pos.y - 20)
    ctx.showText($i)
    ctx.restore()

  for star in brightStars:
    var pos = bestMat * star.pos
    ctx.setSource(1, 0, 0, 1)
    ctx.newPath()
    ctx.arc(
      pos.x,
      pos.y,
      goodPixDist,
      0.0, 2.0*PI)
    ctx.stroke()
    ctx.closePath()
    if star.otherName != "":
      ctx.save()
      ctx.moveTo(float pos.x + 15, float pos.y)
      ctx.showText("    " & star.otherName)
      ctx.restore()

  discard surface.writeToPng("tests/matching.png")




readBrightStars()
drawMilkyWay()
# drawStars3d()
# genStarTris()
# analyzeImage()