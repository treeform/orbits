import vmath

proc det[T: SomeFloat](a, v1, v2: GVec3[T]): T =
  ## Computes the scalar triple product.
  return
    a.x * (v1.y * v2.z - v1.z * v2.y) +
    a.y * (v1.z * v2.x - v1.x * v2.z) +
    a.z * (v1.x * v2.y - v1.y * v2.x)

proc computeLineToLine*[T: SomeFloat](
  a0, a1, b0, b1: GVec3[T],
  clampA0, clampA1, clampB0, clampB1: bool
): (GVec3[T], GVec3[T], T) =
  ## Computes closest points using the existing line-clamping rules.

  let
    a = a1 - a0
    b = b1 - b0
    aNorm = a.normalize()
    bNorm = b.normalize()
    cross = cross(aNorm, bNorm)
    denom = pow(cross.length, 2)

  if denom < 0.00001:
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
      return (GVec3[T](), GVec3[T](), d)
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
        pB = b0
      elif t1 > b.length and clampB1:
        pB = b1

    let d = (pA - pB).length

    return (pA, pB, d)

proc computeSegToSeg*[T: SomeFloat](
  a0, a1, b0, b1: GVec3[T]
): (GVec3[T], GVec3[T], T) =
  ## Computes closest points with both segment ends clamped.
  computeLineToLine(a0, a1, b0, b1, true, true, true, true)
