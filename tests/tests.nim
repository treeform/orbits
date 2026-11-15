import print, vmath, segments

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
    #assert $dist == "((19.85163563, 26.21609078, 14.07303667), (26.99000000, 12.39000000, 11.18000000), 15.82677141213224)"
    # pA = [19.851636, 26.216091, 14.073037]
    # pB = [26.990000, 12.390000, 11.180000]
    # d = 15.826771

block:
  let
    offset = 1e12
    result = computeSegToSeg(
      dvec3(offset, 0, 0),
      dvec3(offset + 2, 0, 0),
      dvec3(offset + 1, -1, 1),
      dvec3(offset + 1, 1, 1)
    )
  doAssert result[0] == dvec3(offset + 1, 0, 0)
  doAssert result[1] == dvec3(offset + 1, 0, 1)
  doAssert abs(result[2] - 1.0) < 1e-12
