import orbits/vmath64
import print


proc det(a, v1, v2: Vec3): float =
  return
    a.x * (v1.y * v2.z - v1.z * v2.y) +
    a.y * (v1.z * v2.x - v1.x * v2.z) +
    a.z * (v1.x * v2.y - v1.y * v2.x)


proc computeLineToLine(
    a0, a1, b0, b1: Vec3,
    clampA0, clampA1, clampB0, clampB1: bool
  ): (Vec3, Vec3, float) =

  let
    a = a1 - a0
    b = b1 - b0
    aNorm = a.normalize()
    bNorm = b.normalize()
    cross = cross(aNorm, bNorm)
    denom = pow(cross.length, 2)

  if denom == 0:
      let
        d0 = dot(aNorm, b0 - a0)
      if clampA0 or clampA1 or clampB0 or clampB1:
          let d1 = dot(aNorm, b1 - a0)
          if d0 <= 0 and 0 >= d1:
              if clampA0 and clampB1:
                  if abs(d0) < abs(d1):
                      return (b0, a0, (b0 - a0).length)
                  else:
                      return (b1, a0, (b1 - a0).length)
          elif d0 >= a.length and a.length <= d1:
              if clampA1 and clampB0:
                  if abs(d0) < abs(d1):
                      return (b0, a1, (b0 - a1).length)
                  else:
                      return (b1, a1, (b1 - a1).length)
      else:
        let d = (aNorm * d0 + a0 - b0).length
        return (vec3(0,0,0), vec3(0,0,0), d)
  else:
    let
      t = b0 - a0
      det0 = det(t, bNorm, cross)
      det1 = det(t, aNorm, cross)
      t0 = det0 / denom
      t1 = det1 / denom
    var
      pA = a0 + aNorm * t0
      pB = b0 + bNorm * t1

    if clampA0 or clampA1 or clampB0 or clampB1:
      if t0 < 0 and clampA0:
        pA = a0
      elif t0 > a.length and clampA1:
        pA = a1
      if t1 < 0 and clampB0:
        pB = b0;
      elif t1 > b.length and clampB1:
        pB = b1;

    var d = (pA - pB).length

    return (pA, pB, d)


proc computeSegToSeg(a0, a1, b0, b1: Vec3): (Vec3, Vec3, float) =
  computeLineToLine(a0, a1, b0, b1, true, true, true, true)



when isMainModule:
  proc almostEquals(a, b: float): bool = abs(a - b) < 0.00001

  block:
    let
      a1 = vec3(0, 0, 0)
      a0 = vec3(0, 1, 0)
      b0 = vec3(1, 0, 0)
      b1 = vec3(1, 1, 0)
    let r = computeLineToLine(a0, a1, b0, b1, false, false, false, false)
    assert r[0] == vec3(0, 0, 0)
    assert r[1] == vec3(0, 0, 0)
    assert r[2] == 1.0


  block:
    let
      a1 = vec3(0, 0, 0)
      a0 = vec3(0, 1, 0)
      b0 = vec3(100, 0, 0)
      b1 = vec3(100, 1, 0)
    let r = computeLineToLine(a0, a1, b0, b1, false, false, false, false)
    assert r[0] == vec3(0, 0, 0)
    assert r[1] == vec3(0, 0, 0)
    assert r[2] == 100.0


  block:
    let
      a1 = vec3(0, -7, 0)
      a0 = vec3(0, -13, 0)
      b0 = vec3(0, 25, 0)
      b1 = vec3(0, 26, 0)
    let r = computeLineToLine(a0, a1, b0, b1, false, false, false, false)
    assert r[0] == vec3(0, 0, 0)
    assert r[1] == vec3(0, 0, 0)
    assert r[2] == 0

    let r2 = computeLineToLine(a0, a1, b0, b1, true, true, true, true)
    assert r2[0] == vec3(0, 25, 0)
    assert r2[1] == vec3(0, -7, 0)
    assert r2[2] == 32

  block:
    let
      a1 = vec3(0, 0, 0)
      a0 = vec3(1, 1, 1)
      b0 = vec3(-1, -1, -1)
      b1 = vec3(-2, -2, -2)
    let r = computeLineToLine(a0, a1, b0, b1, true, true, true, true)
    assert r[0] == vec3(-1, -1, -1)
    assert r[1] == vec3(0, 0, 0)
    assert almostEquals(r[2], 1.732050807568877)

  block:
    let
      a1 = vec3(13.43, 21.77, 46.81)
      a0 = vec3(27.83, 31.74, -26.60)
      b0 = vec3(77.54, 7.53, 6.22)
      b1 = vec3(26.99, 12.39, 11.18)
    let dist = computeLineToLine(a0, a1, b0, b1, true, true, true, true)
    #let dist = computeLineToLine(a0, a1, b0, b1, false, false, false, false)
    assert $dist == "((19.85163563, 26.21609078, 14.07303667), (26.99000000, 12.39000000, 11.18000000), 15.82677141213224)"
    # pA = [19.851636, 26.216091, 14.073037]
    # pB = [26.990000, 12.390000, 11.180000]
    # d = 15.826771
