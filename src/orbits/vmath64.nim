import math
import strutils
import random
export math


proc clamp*(n, min, max: float64): float64 =
  if n < min:
    return min
  if n > max:
    return max
  return n

proc sign*(v: float64): float64 =
  ## Returns the sign of a number, -1 or 1.
  if v >= 0:
    return 1.0
  return -1.0

proc quantize*(v: float64, n: float64): float64 =
  result = sign(v) * floor(abs(v) / n) * n

proc lerp*(a: float64, b: float64, v: float64): float64 =
  a * (1.0 - v) + b * v

proc isInf*(n: float): bool =
  classify(n) in {fcInf, fcNegInf}


proc fixAngle*(angle: float64): float64 =
  ## Make angle be from -PI to PI radians
  var angle = angle
  while angle > PI:
    angle -= PI*2
  while angle < -PI:
    angle += PI*2
  return angle


proc angleBetween*(a, b: float64): float64 =
  (b - a).fixAngle


proc turnAngle*(a, b, speed: float64): float64 =
  ## Move from angle a to angle b with step of v
  var
    turn = fixAngle(b - a)
  if abs(turn) < speed:
    return b
  elif turn > speed:
    turn = speed
  elif turn < -speed:
    turn = -speed
  return a + turn



type Vec2* = object
  x*: float64
  y*: float64

proc vec2*(x, y: float64): Vec2 =
  result.x = x
  result.y = y

proc vec2*(a: Vec2): Vec2 =
  result.x = a.x
  result.y = a.y

proc `+`*(a: Vec2, b: Vec2): Vec2 =
  result.x = a.x + b.x
  result.y = a.y + b.y

proc `-`*(a: Vec2, b: Vec2): Vec2 =
  result.x = a.x - b.x
  result.y = a.y - b.y

proc `*`*(a: Vec2, b: float64): Vec2 =
  result.x = a.x * b
  result.y = a.y * b

proc `*`*(a: float64, b: Vec2): Vec2 =
  b * a

proc `/`*(a: Vec2, b: float64): Vec2 =
  result.x = a.x / b
  result.y = a.y / b

proc `+=`*(a: var Vec2, b: Vec2) =
  a.x += b.x
  a.y += b.y

proc `-=`*(a: var Vec2, b: Vec2) =
  a.x -= b.x
  a.y -= b.y

proc `*=`*(a: var Vec2, b: float64) =
  a.x *= b
  a.y *= b

proc `/=`*(a: var Vec2, b: float64) =
  a.x /= b
  a.y /= b

proc zero*(a: var Vec2) =
  a.x = 0
  a.y = 0

proc `-`*(a: Vec2): Vec2 =
  result.x = -a.x
  result.y = -a.y

proc magSq*(a: Vec2): float64 =
  a.x * a.x + a.y * a.y

proc length*(a: Vec2): float64 =
  math.sqrt(a.magSq)

proc `length=`*(a: var Vec2, b: float64) =
  a *= b / a.length

proc normalize*(a: Vec2): Vec2 =
  a / a.length

proc dot*(a: Vec2, b: Vec2): float64 =
  a.x*b.x + a.y*b.y

proc dir*(at: Vec2, to: Vec2): Vec2 =
  result = (at - to).normalize()

proc dir*(th: float64): Vec2 =
  vec2(cos(th), sin(th))

proc dist*(at: Vec2, to: Vec2): float64 =
  (at - to).length

proc lerp*(a: Vec2, b: Vec2, v: float64): Vec2 =
  a * (1.0 - v) + b * v

proc quantize*(v: Vec2, n: float64): Vec2 =
  result.x = sign(v.x) * floor(abs(v.x) / n) * n
  result.y = sign(v.y) * floor(abs(v.y) / n) * n

proc inRect*(v: Vec2, a: Vec2, b: Vec2): bool =
  ## Check to see if v is inside a rectange formed by a and b
  ## It does not matter how a and b are arranged
  let
    min = vec2(min(a.x, b.x), min(a.y, b.y))
    max = vec2(max(a.x, b.x), max(a.y, b.y))
  return v.x > min.x and v.x < max.x and v.y > min.y and v.y < max.y

template `[]`*(a: Vec2, i: int): float64 =
  assert(i == 0 or i == 1)
  when i == 0:
    a.x
  elif i == 1:
    a.y

template `[]=`*(a: Vec2, i: int, b: float64) =
  assert(i == 0 or i == 1)
  when i == 0:
    a.x = b
  elif i == 1:
    a.y = b

proc `$`*(a: Vec2): string =
  return "(" &
    a.x.formatfloat(ffDecimal,4) & ", " &
    a.y.formatfloat(ffDecimal,4) & ")"

proc angle*(a: Vec2): float64 =
  ## Angle of a vec2
  #echo "math.arctan2(" & $a.y & "," & $a.x & ") = " & $math.arctan2(a.y, a.x)
  math.arctan2(a.y, a.x)

proc angleBetween*(a: Vec2, b: Vec2): float64 =
  ## Angle between 2 vec
  fixAngle(math.arctan2(a.y - b.y, a.x - b.x))

proc isInf*(a: Vec2): bool =
  isInf(a.x) or isInf(a.x)


type Vec3* = object
  x*: float64
  y*: float64
  z*: float64

proc vec3*(x, y, z: float64): Vec3 =
  result.x = x
  result.y = y
  result.z = z

proc vec3*(a: Vec3): Vec3 =
  result.x = a.x
  result.y = a.y
  result.z = a.z

const X_DIR* = vec3(1.0, 0.0, 0.0)
const Y_DIR* = vec3(0.0, 1.0, 0.0)
const Z_DIR* = vec3(0.0, 0.0, 1.0)

proc `+`*(a: Vec3, b: Vec3): Vec3 =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z

proc `-`*(a: Vec3, b: Vec3): Vec3 =
  result.x = a.x - b.x
  result.y = a.y - b.y
  result.z = a.z - b.z

proc `-`*(a: Vec3): Vec3 =
  result.x = -a.x
  result.y = -a.y
  result.z = -a.z

proc `*`*(a: Vec3, b: float64): Vec3 =
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b

proc `*`*(a: float64, b: Vec3): Vec3 =
  b * a

proc `/`*(a: Vec3, b: float64): Vec3 =
  result.x = a.x / b
  result.y = a.y / b
  result.z = a.z / b

proc `/`*(a: float64, b: Vec3): Vec3 =
  result.x = a / b.x
  result.y = a / b.y
  result.z = a / b.z

proc `+=`*(a: var Vec3, b: Vec3) =
  a.x += b.x
  a.y += b.y
  a.z += b.z

proc `-=`*(a: var Vec3, b: Vec3) =
  a.x -= b.x
  a.y -= b.y
  a.z -= b.z

proc `*=`*(a: var Vec3, b: float64) =
  a.x *= b
  a.y *= b
  a.z *= b

proc `/=`*(a: var Vec3, b: float64) =
  a.x /= b
  a.y /= b
  a.z /= b

proc zero*(a: var Vec3) =
  a.x = 0
  a.y = 0
  a.z = 0

proc `-`*(a: var Vec3): Vec3 =
  result.x = -a.x
  result.y = -a.y
  result.z = -a.z

proc lengthSqrd*(a: Vec3): float64 =
  a.x * a.x + a.y * a.y + a.z * a.z

proc length*(a: Vec3): float64 =
  math.sqrt(a.lengthSqrd)

proc `length=`*(a: var Vec3, b: float64) =
  a *= b / a.length

proc normalize*(a: Vec3): Vec3 =
  return a / math.sqrt(a.x*a.x + a.y*a.y + a.z*a.z)

proc cross*(a: Vec3, b: Vec3): Vec3 =
  result.x = a.y*b.z - a.z*b.y
  result.y = a.z*b.x - a.x*b.z
  result.z = a.x*b.y - a.y*b.x

proc computeNormal*(a, b, c: Vec3): Vec3 =
  result = cross(c - b, b - a).normalize()

proc dot*(a: Vec3, b: Vec3): float64 =
  a.x*b.x + a.y*b.y + a.z*b.z

proc dir*(at: Vec3, to: Vec3): Vec3 =
  result = (at - to).normalize()

proc dist*(at: Vec3, to: Vec3): float64 =
  (at - to).length

proc lerp*(a: Vec3, b: Vec3, v: float64): Vec3 =
  a * (1.0 - v) + b * v

proc angleBetween*(a, b: Vec3): float64 =
  var dot = dot(a, b)
  dot = dot / (a.length * b.length)
  return arccos(dot)

template `[]`*(a: Vec3, i: int): float64 =
  assert(i == 0 or i == 1 or i == 2)
  when i == 0:
    a.x
  elif i == 1:
    a.y
  elif i == 2:
    a.z

template `[]=`*(a: Vec3, i: int, b: float64) =
  assert(i == 0 or i == 1 or i == 2)
  when i == 0:
    a.x = b
  elif i == 1:
    a.y = b
  elif i == 2:
    a.z = b

proc xy*(a: Vec3): Vec2 =
  vec2(a.x, a.y)

proc xz*(a: Vec3): Vec2 =
  vec2(a.x, a.z)

proc yx*(a: Vec3): Vec2 =
  vec2(a.y, a.x)

proc yz*(a: Vec3): Vec2 =
  vec2(a.y, a.z)

proc zx*(a: Vec3): Vec2 =
  vec2(a.y, a.x)

proc zy*(a: Vec3): Vec2 =
  vec2(a.z, a.y)

proc almostEquals*(a, b: Vec3, precision = 1e-6): bool =
  let c = a - b
  return abs(c.x) < precision and abs(c.y) < precision and abs(c.z) < precision

proc isInf*(a: Vec3): bool =
  isInf(a.x) or isInf(a.x) or isInf(a.z)

proc `$`*(a: Vec3): string =
  return "(" &
    a.x.formatfloat(ffDecimal,8) & ", " &
    a.y.formatfloat(ffDecimal,8) & ", " &
    a.z.formatfloat(ffDecimal,8) & ")"


type Vec4* = object
  x*: float64
  y*: float64
  z*: float64
  w*: float64

proc vec4*(x, y, z, w: float64): Vec4 =
  result.x = x
  result.y = y
  result.z = z
  result.w = w

proc `+`*(a: Vec4, b: Vec4): Vec4 =
  result.x = a.x + b.x
  result.y = a.y + b.y
  result.z = a.z + b.z
  result.w = a.w + b.w

proc `-`*(a: Vec4, b: Vec4): Vec4 =
  result.x = a.x - b.x
  result.y = a.y - b.y
  result.z = a.z - b.z
  result.w = a.w - b.w

proc `-`*(a: Vec4): Vec4 =
  result.x = -a.x
  result.y = -a.y
  result.z = -a.z
  result.w = -a.w

proc `*`*(a: Vec4, b: float64): Vec4 =
  result.x = a.x * b
  result.y = a.y * b
  result.z = a.z * b
  result.w = a.w * b

proc `*`*(a: float64, b: Vec4): Vec4 =
  b * a

proc `/`*(a: Vec4, b: float64): Vec4 =
  result.x = a.x / b
  result.y = a.y / b

  result.z = a.z / b
  result.w = a.w / b

proc `/`*(a: float64, b: Vec4): Vec4 =
  result.x = a / b.x
  result.y = a / b.y
  result.z = a / b.z
  result.w = a / b.w

proc `+=`*(a: var Vec4, b: Vec4) =
  a.x += b.x
  a.y += b.y
  a.z += b.z
  a.w += b.w

proc `-=`*(a: var Vec4, b: Vec4) =
  a.x -= b.x
  a.y -= b.y
  a.z -= b.z
  a.w -= b.w

proc `*=`*(a: var Vec4, b: float64) =
  a.x *= b
  a.y *= b
  a.z *= b
  a.w *= b

proc `/=`*(a: var Vec4, b: float64) =
  a.x /= b
  a.y /= b
  a.z /= b
  a.w /= b

proc zero*(a: var Vec4) =
  a.x = 0
  a.y = 0
  a.z = 0
  a.w = 0

proc xyz*(a: Vec4): Vec3 =
  vec3(a.x, a.y, a.z)

proc `$`*(a: Vec4): string =
  return "(" &
    a.x.formatfloat(ffDecimal,8) & ", " &
    a.y.formatfloat(ffDecimal,8) & ", " &
    a.z.formatfloat(ffDecimal,8) & ", " &
    a.w.formatfloat(ffDecimal,8) & ")"


proc vec3*(a: Vec2, z=0.0): Vec3 =
  vec3(a.x, a.y, z)

proc vec4*(a: Vec3, w=0.0): Vec4 =
  vec4(a.x, a.y, a.z, w)

proc vec4*(a: Vec2, z=0.0, w=0.0): Vec4 =
  vec4(a.x, a.y, z, w)


type Mat3* = array[9, float64]

proc mat3*(a, b, c, d, e, f, g, h, i: float64): Mat3 =
  result[0] = a
  result[1] = b
  result[2] = c
  result[3] = d
  result[4] = e
  result[5] = f
  result[6] = g
  result[7] = h
  result[8] = i


proc mat3*(a: Mat3): Mat3 =
  result = a


proc identity*(a: var Mat3) =
  a[0] = 1
  a[1] = 0
  a[2] = 0
  a[3] = 0
  a[4] = 1
  a[5] = 0
  a[6] = 0
  a[7] = 0
  a[8] = 1


proc mat3*(): Mat3 =
  result.identity()


proc transpose*(a: Mat3): Mat3 =
  result[0] = a[0]
  result[1] = a[3]
  result[2] = a[6]
  result[3] = a[1]
  result[4] = a[4]
  result[5] = a[7]
  result[6] = a[2]
  result[7] = a[5]
  result[8] = a[8]


proc `$`*(a: Mat3): string =
  return "[" &
    a[0].formatfloat(ffDecimal,4) & ", " &
    a[1].formatfloat(ffDecimal,4) & ", " &
    a[2].formatfloat(ffDecimal,4) & ", " &
    a[3].formatfloat(ffDecimal,4) & ", " &
    a[4].formatfloat(ffDecimal,4) & ", " &
    a[5].formatfloat(ffDecimal,4) & ", " &
    a[6].formatfloat(ffDecimal,4) & ", " &
    a[7].formatfloat(ffDecimal,4) & ", " &
    a[8].formatfloat(ffDecimal,4) & "]"

proc `*`*(a: Mat3, b: Mat3): Mat3 =
  let
    a00 = a[0]
    a01 = a[1]
    a02 = a[2]
    a10 = a[3]
    a11 = a[4]
    a12 = a[5]
    a20 = a[6]
    a21 = a[7]
    a22 = a[8]

    b00 = b[0]
    b01 = b[1]
    b02 = b[2]
    b10 = b[3]
    b11 = b[4]
    b12 = b[5]
    b20 = b[6]
    b21 = b[7]
    b22 = b[8]

  result[0] = b00 * a00 + b01 * a10 + b02 * a20
  result[1] = b00 * a01 + b01 * a11 + b02 * a21
  result[2] = b00 * a02 + b01 * a12 + b02 * a22

  result[3] = b10 * a00 + b11 * a10 + b12 * a20
  result[4] = b10 * a01 + b11 * a11 + b12 * a21
  result[5] = b10 * a02 + b11 * a12 + b12 * a22

  result[6] = b20 * a00 + b21 * a10 + b22 * a20
  result[7] = b20 * a01 + b21 * a11 + b22 * a21
  result[8] = b20 * a02 + b21 * a12 + b22 * a22


proc `*`*(m: Mat3, v: Vec3): Vec3 =
  result.x = m[0]*v.x + m[1]*v.y + m[2]*v.z
  result.y = m[3]*v.x + m[4]*v.y + m[5]*v.z
  result.z = m[6]*v.x + m[7]*v.y + m[8]*v.z


proc scale*(a: Mat3, v: Vec2): Mat3 =
  result[0] = v.x * a[0]
  result[1] = v.x * a[1]
  result[2] = v.x * a[2]
  result[3] = v.y * a[3]
  result[4] = v.y * a[4]
  result[5] = v.y * a[5]
  result[6] = a[6]
  result[7] = a[7]
  result[8] = a[8]


proc scale*(a: Mat3, v: Vec3): Mat3 =
  result[0] = v.x * a[0]
  result[1] = v.x * a[1]
  result[2] = v.x * a[2]
  result[3] = v.y * a[3]
  result[4] = v.y * a[4]
  result[5] = v.y * a[5]
  result[6] = v.z * a[6]
  result[7] = v.z * a[7]
  result[8] = v.z * a[8]


proc rotationMat3*(angle: float64): Mat3 =
  # create a matrix from an angle
  let
    sin = sin(angle)
    cos = cos(angle)
  result[0] = cos
  result[1] = -sin
  result[2] = 0

  result[3] = sin
  result[4] = cos
  result[5] = 0

  result[6] = 0
  result[7] = 0
  result[8] = 1


proc rotate*(a: Mat3, angle: float64): Mat3 =
  # rotates a matrix by an angle
  a * rotationMat3(angle)


proc `*`*(a: Mat3, b: Vec2): Vec2 =
  result.x = a[0]*b.x + a[1]*b.y + a[6]
  result.y = a[3]*b.x + a[4]*b.y + a[7]


type Mat4* = array[16, float64]


proc mat4*(v0, v1, Vec2, Vec3, Vec4, v5, v6, v7, v8, v9, v10, v11, v12, v13, v14, v15: float64): Mat4 =
  result[0] = v0
  result[1] = v1
  result[2] = Vec2
  result[3] = Vec3
  result[4] = Vec4
  result[5] = v5
  result[6] = v6
  result[7] = v7
  result[8] = v8
  result[9] = v9
  result[10] = v10
  result[11] = v11
  result[12] = v12
  result[13] = v13
  result[14] = v14
  result[15] = v15


proc mat4*(a: Mat4): Mat4 =
  result = a


proc identity*(): Mat4 =
  result[0] = 1
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = 1
  result[6] = 0
  result[7] = 0
  result[8] = 0
  result[9] = 0
  result[10] = 1
  result[11] = 0
  result[12] = 0
  result[13] = 0
  result[14] = 0
  result[15] = 1


proc mat4*(): Mat4 =
  return identity()


proc transpose*(a: Mat4): Mat4 =
  result[0] = a[0]
  result[1] = a[4]
  result[2] = a[8]
  result[3] = a[12]

  result[4] = a[1]
  result[5] = a[5]
  result[6] = a[9]
  result[7] = a[13]

  result[8] = a[2]
  result[9] = a[6]
  result[10] = a[10]
  result[11] = a[14]

  result[12] = a[3]
  result[13] = a[7]
  result[14] = a[11]
  result[15] = a[15]


proc determinant*(a: Mat4): float64 =
  var
     a00 = a[0]
     a01 = a[1]
     a02 = a[2]
     a03 = a[3]
     a10 = a[4]
     a11 = a[5]
     a12 = a[6]
     a13 = a[7]
     a20 = a[8]
     a21 = a[9]
     a22 = a[10]
     a23 = a[11]
     a30 = a[12]
     a31 = a[13]
     a32 = a[14]
     a33 = a[15]

  return (
    a30*a21*a12*a03 - a20*a31*a12*a03 - a30*a11*a22*a03 + a10*a31*a22*a03 +
    a20*a11*a32*a03 - a10*a21*a32*a03 - a30*a21*a02*a13 + a20*a31*a02*a13 +
    a30*a01*a22*a13 - a00*a31*a22*a13 - a20*a01*a32*a13 + a00*a21*a32*a13 +
    a30*a11*a02*a23 - a10*a31*a02*a23 - a30*a01*a12*a23 + a00*a31*a12*a23 +
    a10*a01*a32*a23 - a00*a11*a32*a23 - a20*a11*a02*a33 + a10*a21*a02*a33 +
    a20*a01*a12*a33 - a00*a21*a12*a33 - a10*a01*a22*a33 + a00*a11*a22*a33
  )


proc inverse*(a: Mat4): Mat4 =
  var
     a00 = a[0]
     a01 = a[1]
     a02 = a[2]
     a03 = a[3]
     a10 = a[4]
     a11 = a[5]
     a12 = a[6]
     a13 = a[7]
     a20 = a[8]
     a21 = a[9]
     a22 = a[10]
     a23 = a[11]
     a30 = a[12]
     a31 = a[13]
     a32 = a[14]
     a33 = a[15]

  var
    b00 = a00*a11 - a01*a10
    b01 = a00*a12 - a02*a10
    b02 = a00*a13 - a03*a10
    b03 = a01*a12 - a02*a11
    b04 = a01*a13 - a03*a11
    b05 = a02*a13 - a03*a12
    b06 = a20*a31 - a21*a30
    b07 = a20*a32 - a22*a30
    b08 = a20*a33 - a23*a30
    b09 = a21*a32 - a22*a31
    b10 = a21*a33 - a23*a31
    b11 = a22*a33 - a23*a32

  # Calculate the invese determinant
  var invDet = 1.0/(b00*b11 - b01*b10 + b02*b09 + b03*b08 - b04*b07 + b05*b06)

  result[ 0] = ( a11*b11 - a12*b10 + a13*b09)*invDet
  result[ 1] = (-a01*b11 + a02*b10 - a03*b09)*invDet
  result[ 2] = ( a31*b05 - a32*b04 + a33*b03)*invDet
  result[ 3] = (-a21*b05 + a22*b04 - a23*b03)*invDet
  result[ 4] = (-a10*b11 + a12*b08 - a13*b07)*invDet
  result[ 5] = ( a00*b11 - a02*b08 + a03*b07)*invDet
  result[ 6] = (-a30*b05 + a32*b02 - a33*b01)*invDet
  result[ 7] = ( a20*b05 - a22*b02 + a23*b01)*invDet
  result[ 8] = ( a10*b10 - a11*b08 + a13*b06)*invDet
  result[ 9] = (-a00*b10 + a01*b08 - a03*b06)*invDet
  result[10] = ( a30*b04 - a31*b02 + a33*b00)*invDet
  result[11] = (-a20*b04 + a21*b02 - a23*b00)*invDet
  result[12] = (-a10*b09 + a11*b07 - a12*b06)*invDet
  result[13] = ( a00*b09 - a01*b07 + a02*b06)*invDet
  result[14] = (-a30*b03 + a31*b01 - a32*b00)*invDet
  result[15] = ( a20*b03 - a21*b01 + a22*b00)*invDet


proc `*`*(a, b: Mat4): Mat4 =
  var
    a00 = a[0]
    a01 = a[1]
    a02 = a[2]
    a03 = a[3]
    a10 = a[4]
    a11 = a[5]
    a12 = a[6]
    a13 = a[7]
    a20 = a[8]
    a21 = a[9]
    a22 = a[10]
    a23 = a[11]
    a30 = a[12]
    a31 = a[13]
    a32 = a[14]
    a33 = a[15]

  var
    b00 = b[0]
    b01 = b[1]
    b02 = b[2]
    b03 = b[3]
    b10 = b[4]
    b11 = b[5]
    b12 = b[6]
    b13 = b[7]
    b20 = b[8]
    b21 = b[9]
    b22 = b[10]
    b23 = b[11]
    b30 = b[12]
    b31 = b[13]
    b32 = b[14]
    b33 = b[15]

  result[ 0] = b00*a00 + b01*a10 + b02*a20 + b03*a30
  result[ 1] = b00*a01 + b01*a11 + b02*a21 + b03*a31
  result[ 2] = b00*a02 + b01*a12 + b02*a22 + b03*a32
  result[ 3] = b00*a03 + b01*a13 + b02*a23 + b03*a33
  result[ 4] = b10*a00 + b11*a10 + b12*a20 + b13*a30
  result[ 5] = b10*a01 + b11*a11 + b12*a21 + b13*a31
  result[ 6] = b10*a02 + b11*a12 + b12*a22 + b13*a32
  result[ 7] = b10*a03 + b11*a13 + b12*a23 + b13*a33
  result[ 8] = b20*a00 + b21*a10 + b22*a20 + b23*a30
  result[ 9] = b20*a01 + b21*a11 + b22*a21 + b23*a31
  result[10] = b20*a02 + b21*a12 + b22*a22 + b23*a32
  result[11] = b20*a03 + b21*a13 + b22*a23 + b23*a33
  result[12] = b30*a00 + b31*a10 + b32*a20 + b33*a30
  result[13] = b30*a01 + b31*a11 + b32*a21 + b33*a31
  result[14] = b30*a02 + b31*a12 + b32*a22 + b33*a32
  result[15] = b30*a03 + b31*a13 + b32*a23 + b33*a33


proc `*`*(a: Mat4, b: Vec3): Vec3 =
  result.x = a[0]*b.x + a[4]*b.y + a[8]*b.z + a[12]
  result.y = a[1]*b.x + a[5]*b.y + a[9]*b.z + a[13]
  result.z = a[2]*b.x + a[6]*b.y + a[10]*b.z + a[14]


proc right*(a: Mat4): Vec3 =
  result.x = a[0]
  result.y = a[1]
  result.z = a[2]


proc `right=`*(a: var Mat4, b: Vec3) =
  a[0] = b.x
  a[1] = b.y
  a[2] = b.z


proc up*(a: Mat4): Vec3 =
  result.x = a[4]
  result.y = a[5]
  result.z = a[6]


proc `up=`*(a: var Mat4, b: Vec3) =
  a[4] = b.x
  a[5] = b.y
  a[6] = b.z


proc fov*(a: Mat4): Vec3 =
  result.x = a[8]
  result.y = a[9]
  result.z = a[10]


proc `fov=`*(a: var Mat4, b: Vec3) =
  a[8] = b.x
  a[9] = b.y
  a[10] = b.z


proc pos*(a: Mat4): Vec3 =
  result.x = a[12]
  result.y = a[13]
  result.z = a[14]


proc `pos=`*(a: var Mat4, b: Vec3) =
  a[12] = b.x
  a[13] = b.y
  a[14] = b.z


proc rotationOnly*(a: Mat4): Mat4 =
  result = a
  result.pos = vec3(0,0,0)


proc dist*(a, b: Mat4): float64 =
    var
      x = a[12] - b[12]
      y = a[13] - b[13]
      z = a[14] - b[14]
    return sqrt(x*x + y*y + z*z)

#[
proc translate*(a: Mat4, v: Vec3): Mat4 =
  var
    a00 = a[0]
    a01 = a[1]
    a02 = a[2]
    a03 = a[3]
    a10 = a[4]
    a11 = a[5]
    a12 = a[6]
    a13 = a[7]
    a20 = a[8]
    a21 = a[9]
    a22 = a[10]
    a23 = a[11]

  result[0] = a00
  result[1] = a01
  result[2] = a02
  result[3] = a03
  result[4] = a10
  result[5] = a11
  result[6] = a12
  result[7] = a13
  result[8] = a20
  result[9] = a21
  result[10] = a22
  result[11] = a23

  result[12] = a00*v.x + a10*v.y + a20*v.z + a[12]
  result[13] = a01*v.x + a11*v.y + a21*v.z + a[13]
  result[14] = a02*v.x + a12*v.y + a22*v.z + a[14]
  result[15] = a03*v.x + a13*v.y + a23*v.z + a[15]
]#


proc translate*(v: Vec3): Mat4 =
  result[0] = 1
  result[5] = 1
  result[10] = 1
  result[15] = 1
  result[12] = v.x
  result[13] = v.y
  result[14] = v.z


proc scale*(v: Vec3): Mat4 =
  result[0] = v.x
  result[5] = v.y
  result[10] = v.z
  result[15] = 1


proc close*(a: Mat4, b: Mat4): bool =
  for i in 0..15:
    if abs(a[i] - b[i]) > 0.001:
      return false
  return true


proc hrp*(m: Mat4): Vec3 =
  var heading, pitch, roll: float64
  if m[1] > 0.998: # singularity at north pole
    heading = arctan2(m[2], m[10])
    pitch = PI / 2
    roll = 0
  elif m[1] < -0.998:  # singularity at sresulth pole
    heading = arctan2(m[2], m[10])
    pitch = -PI / 2
    roll = 0
  else:
    heading =arctan2(-m[8], m[0])
    pitch = arctan2(-m[6], m[5])
    roll = arcsin(m[4])
  result.x = heading
  result.y = pitch
  result.z = roll


proc frustum*(left, right, bottom, top, near, far: float64): Mat4 =
  var
    rl = (right - left)
    tb = (top - bottom)
    fn = (far - near)
  result[0] = (near*2) / rl
  result[1] = 0
  result[2] = 0
  result[3] = 0
  result[4] = 0
  result[5] = (near*2) / tb
  result[6] = 0
  result[7] = 0
  result[8] = (right + left) / rl
  result[9] = (top + bottom) / tb
  result[10] = -(far + near) / fn
  result[11] = -1
  result[12] = 0
  result[13] = 0
  result[14] = -(far*near*2) / fn
  result[15] = 0


proc perspective*(fovy, aspect, near, far: float64): Mat4 =
  var
    top = near * tan(fovy*PI / 360.0)
    right = top * aspect
  return frustum(-right, right, -top, top, near, far)


proc ortho*(left, right, bottom, top, near, far: float64): Mat4 =
    var
      rl = (right - left)
      tb = (top - bottom)
      fn = (far - near)
    result[0] = 2 / rl
    result[1] = 0
    result[2] = 0
    result[3] = 0
    result[4] = 0
    result[5] = 2 / tb
    result[6] = 0
    result[7] = 0
    result[8] = 0
    result[9] = 0
    result[10] = -2 / fn
    result[11] = 0
    result[12] = -(left + right) / rl
    result[13] = -(top + bottom) / tb
    result[14] = -(far + near) / fn
    result[15] = 1


proc lookAt*(eye, center, up: Vec3): Mat4 =
    var
      eyex = eye[0]
      eyey = eye[1]
      eyez = eye[2]
      upx = up[0]
      upy = up[1]
      upz = up[2]
      centerx = center[0]
      centery = center[1]
      centerz = center[2]

    if eyex == centerx and eyey == centery and eyez == centerz:
        return identity()

    var
      # vec3.direction(eye, center, z)
      z0 = eyex - center[0]
      z1 = eyey - center[1]
      z2 = eyez - center[2]

    # normalize (no check needed for 0 because of early return)
    var len = 1/sqrt(z0*z0 + z1*z1 + z2*z2)
    z0 *= len
    z1 *= len
    z2 *= len

    var
      # vec3.normalize(vec3.cross(up, z, x))
      x0 = upy*z2 - upz*z1
      x1 = upz*z0 - upx*z2
      x2 = upx*z1 - upy*z0
    len = sqrt(x0*x0 + x1*x1 + x2*x2)
    if len == 0:
        x0 = 0
        x1 = 0
        x2 = 0
    else:
        len = 1/len
        x0 *= len
        x1 *= len
        x2 *= len

    var
      # vec3.normalize(vec3.cross(z, x, y))
      y0 = z1*x2 - z2*x1
      y1 = z2*x0 - z0*x2
      y2 = z0*x1 - z1*x0

    len = sqrt(y0*y0 + y1*y1 + y2*y2)
    if len == 0:
        y0 = 0
        y1 = 0
        y2 = 0
    else:
        len = 1/len
        y0 *= len
        y1 *= len
        y2 *= len

    result[0] = x0
    result[1] = y0
    result[2] = z0
    result[3] = 0
    result[4] = x1
    result[5] = y1
    result[6] = z1
    result[7] = 0
    result[8] = x2
    result[9] = y2
    result[10] = z2
    result[11] = 0
    result[12] = -(x0*eyex + x1*eyey + x2*eyez)
    result[13] = -(y0*eyex + y1*eyey + y2*eyez)
    result[14] = -(z0*eyex + z1*eyey + z2*eyez)
    result[15] = 1


proc tofloat64*(m: Mat4): array[16, float64] =
   return [
      float64 m[0],  float64 m[1],  float64 m[2],  float64 m[3],
      float64 m[4],  float64 m[5],  float64 m[6],  float64 m[7],
      float64 m[8],  float64 m[9],  float64 m[10], float64 m[11],
      float64 m[12], float64 m[13], float64 m[14], float64 m[15]
   ]


proc `$`*(a: Mat4): string =
  return "[" &
    a[0].formatfloat(ffDecimal, 5) & ", " &
    a[1].formatfloat(ffDecimal, 5) & ", " &
    a[2].formatfloat(ffDecimal, 5) & ", " &
    a[3].formatfloat(ffDecimal, 5) & ",\n" &
    a[4].formatfloat(ffDecimal, 5) & ", " &
    a[5].formatfloat(ffDecimal, 5) & ", " &
    a[6].formatfloat(ffDecimal, 5) & ", " &
    a[7].formatfloat(ffDecimal, 5) & ",\n " &
    a[8].formatfloat(ffDecimal, 5) & ", " &
    a[9].formatfloat(ffDecimal, 5) & ", " &
    a[10].formatfloat(ffDecimal, 5) & ", " &
    a[11].formatfloat(ffDecimal, 5) & ",\n" &
    a[12].formatfloat(ffDecimal, 5) & ", " &
    a[13].formatfloat(ffDecimal, 5) & ", " &
    a[14].formatfloat(ffDecimal, 5) & ", " &
    a[15].formatfloat(ffDecimal, 5) & "]"


type Quat* = object
  x*: float64
  y*: float64
  z*: float64
  w*: float64


proc quat*(x, y, z, w: float64): Quat =
  result.x = x
  result.y = y
  result.z = z
  result.w = w


proc conjugate*(q: Quat): Quat =
  result.w =  q.w
  result.x = -q.x
  result.y = -q.y
  result.z = -q.z


proc length*(q: Quat): float64 =
  return sqrt(
    q.w * q.w +
    q.x * q.x +
    q.y * q.y +
    q.z * q.z)


proc normalize*(q: Quat): Quat =
  var m = q.length
  result.x = q.x / m
  result.y = q.y / m
  result.z = q.z / m
  result.w = q.w / m


proc xyz*(q: Quat): Vec3 =
  result.x = q.x
  result.y = q.y
  result.z = q.z


proc `xyz=`*(q: var Quat, v: Vec3) =
  q.x = v.x
  q.y = v.y
  q.z = v.z


proc `*`*(a, b: Quat): Quat =
  ## Multiply the quaternion by a quaternion
  #[
  var q = quat(0,0,0,0)
  q.w = dot(a.xyz, b.xyz)
  var va = cross(a.xyz, b.xyz)
  var vb = a.xyz * b.w
  var vc = b.xyz * a.w
  va = va + vb
  q.xyz = va + vc
  return q.normalize()
  ]#

  result.x = a.x * b.w + a.w * b.x + a.y * b.z - a.z * b.y
  result.y = a.y * b.w + a.w * b.y + a.z * b.x - a.x * b.z
  result.z = a.z * b.w + a.w * b.z + a.x * b.y - a.y * b.x
  result.w = a.w * b.w - a.x * b.x - a.y * b.y - a.z * b.z

proc `*`*(q: Quat, v: float64): Quat =
  ## Multiply the quaternion by a float64
  result.x = q.x * v
  result.y = q.y * v
  result.z = q.z * v
  result.w = q.w * v


proc `*`*(q: Quat, v: Vec3): Vec3 =
  ## Multiply the quaternion by a vector
  var
    x = v.x
    y = v.y
    z = v.z

    qx = q.x
    qy = q.y
    qz = q.z
    qw = q.w

    ix =  qw * x + qy * z - qz * y
    iy =  qw * y + qz * x - qx * z
    iz =  qw * z + qx * y - qy * x
    iw = -qx * x - qy * y - qz * z

  result.x = ix * qw + iw * -qx + iy * -qz - iz * -qy
  result.y = iy * qw + iw * -qy + iz * -qx - ix * -qz
  result.z = iz * qw + iw * -qz + ix * -qy - iy * -qx


proc mat3*(q: Quat): Mat3 =
  var xx     = q.x * q.x
  var xy     = q.x * q.y
  var xz     = q.x * q.z
  var xw     = q.x * q.w

  var yy     = q.y * q.y
  var yz     = q.y * q.z
  var yw     = q.y * q.w

  var zz     = q.z * q.z
  var zw     = q.z * q.w

  result[0]  = 1 - 2 * ( yy + zz )
  result[1]  =     2 * ( xy - zw )
  result[2]  =     2 * ( xz + yw )

  result[3]  =     2 * ( xy + zw )
  result[4]  = 1 - 2 * ( xx + zz )
  result[5]  =     2 * ( yz - xw )

  result[6]  =     2 * ( xz - yw )
  result[7]  =     2 * ( yz + xw )
  result[8]  = 1 - 2 * ( xx + yy )



proc mat4*(q: Quat): Mat4 =
  var xx     = q.x * q.x
  var xy     = q.x * q.y
  var xz     = q.x * q.z
  var xw     = q.x * q.w

  var yy     = q.y * q.y
  var yz     = q.y * q.z
  var yw     = q.y * q.w

  var zz     = q.z * q.z
  var zw     = q.z * q.w

  result[0]  = 1 - 2 * ( yy + zz )
  result[1]  =     2 * ( xy - zw )
  result[2]  =     2 * ( xz + yw )

  result[4]  =     2 * ( xy + zw )
  result[5]  = 1 - 2 * ( xx + zz )
  result[6]  =     2 * ( yz - xw )

  result[8]  =     2 * ( xz - yw )
  result[9]  =     2 * ( yz + xw )
  result[10] = 1 - 2 * ( xx + yy )

  result[3]  = 0
  result[7]  = 0
  result[11] = 0
  result[12] = 0
  result[13] = 0
  result[14] = 0
  result[15] = 1.0


proc reciprocalSqrt*(x: float64): float64 =
 return 1.0/sqrt(x)


proc quat*(m: Mat4): Quat =
  var
    m00 = m[0]
    m01 = m[4]
    m02 = m[8]

    m10 = m[1]
    m11 = m[5]
    m12 = m[9]

    m20 = m[2]
    m21 = m[6]
    m22 = m[10]

  var q : Quat
  var t : float64

  if m22 < 0:
    if m00 > m11:
      t = 1 + m00 - m11 - m22
      q = quat(t, m01 + m10, m20 + m02, m12 - m21)
    else:
      t = 1 - m00 + m11 - m22
      q = quat(m01 + m10, t, m12 + m21, m20 - m02)
  else:
    if m00 < - m11:
      t = 1 - m00 - m11 + m22
      q = quat(m20 + m02, m12 + m21, t, m01 - m10)
    else:
      t = 1 + m00 + m11 + m22
      q = quat(m12 - m21, m20 - m02, m01 - m10, t)
  q = q * (0.5 / sqrt(t))

  echo abs(q.length - 1.0)
  assert abs(q.length - 1.0) < 0.001
  return q


proc fromAxisAngle*(axis: Vec3, angle: float64): Quat =
  var a = axis.normalize()
  var s = sin(angle / 2)
  result.x = a.x * s
  result.y = a.y * s
  result.z = a.z * s
  result.w = cos(angle / 2)


proc toAxisAngle*(q: Quat, axis: var Vec3, angle: var float64) =
  var cosAngle = q.w
  angle = arccos(cosAngle) * 2.0
  var sinAngle = sqrt(1.0 - cosAngle * cosAngle)

  if abs(sinAngle) < 0.0005:
    sinAngle = 1.0

  axis.x = q.x / sinAngle
  axis.y = q.y / sinAngle
  axis.z = q.z / sinAngle


proc quat*(heading, pitch, roll: float64): Quat =
  var t0 = cos(heading * 0.5)
  var t1 = sin(heading * 0.5)
  var t2 = cos(roll * 0.5)
  var t3 = sin(roll * 0.5)
  var t4 = cos(pitch * 0.5)
  var t5 = sin(pitch * 0.5)
  result.w = t0 * t2 * t4 + t1 * t3 * t5
  result.x = t0 * t3 * t4 - t1 * t2 * t5
  result.y = t0 * t2 * t5 + t1 * t3 * t4
  result.z = t1 * t2 * t4 - t0 * t3 * t5


proc hrp*(q: Quat): Vec3 =
  var ysqr = q.y * q.y
  # roll
  var t0 = +2.0 * (q.w * q.x + q.y * q.z)
  var t1 = +1.0 - 2.0 * (q.x * q.x + ysqr)
  result.z = arctan2(t0, t1)
  # pitch
  var t2 = +2.0 * (q.w * q.y - q.z * q.x)
  if t2 > 1.0:
    t2 = 1.0
  if t2 < -1.0:
    t2 = -1.0
  result.y = arcsin(t2)
  # heading
  var t3 = +2.0 * (q.w * q.z + q.x * q.y)
  var t4 = +1.0 - 2.0 * (ysqr + q.z * q.z)
  result.x = arctan2(t3, t4)


proc `$`*(a: Quat): string =
  return "q(" &
    a.x.formatfloat(ffDecimal,8) & ", " &
    a.y.formatfloat(ffDecimal,8) & ", " &
    a.z.formatfloat(ffDecimal,8) & ", " &
    a.w.formatfloat(ffDecimal,8) & ")"



proc rotate*(angle: float64, axis: Vec3): Mat4 =
  fromAxisAngle(axis, angle).mat4()


proc rotateX*(angle: float64): Mat4 =
  return rotate(angle, vec3(1, 0, 0))


proc rotateY*(angle: float64): Mat4 =
  return rotate(angle, vec3(0, 1, 0))


proc rotateZ*(angle: float64): Mat4 =
  return rotate(angle, vec3(0, 0, 1))


proc scaleMat*(scale: Vec3): Mat4 =
  result[0] = scale.x
  result[5] = scale.y
  result[10] = scale.z
  result[15] = 1.0


proc scaleMat*(scale: float64): Mat4 =
  return scaleMat(vec3(scale, scale, scale))


type Rect* = object
  x*: float64
  y*: float64
  w*: float64
  h*: float64

proc rect*(x, y, w, h: float64): Rect =
  result.x = x
  result.y = y
  result.w = w
  result.h = h

proc rect*(pos, size: Vec2): Rect =
  result.x = pos.x
  result.y = pos.y
  result.w = size.x
  result.h = size.y

proc xy*(rect: Rect): Vec2 =
  ## Gets the xy as a vec2
  vec2(rect.x, rect.y)

proc wh*(rect: Rect): Vec2 =
  ## Gets the wh as a vec2
  vec2(rect.w, rect.h)

proc intersects*(rect: Rect, pos: Vec2): bool =
  ## Checks if point is inside the rectangle
  (rect.x <= pos.x and pos.x <= rect.x + rect.w) and (
   rect.y <= pos.y and pos.y <= rect.y + rect.h)

proc `$`*(a: Rect): string =
  return "(" &
    $a.x & ", " &
    $a.y & ": " &
    $a.w & " x " &
    $a.h & ")"


## Line and segments
proc computeLineToLine*(
    a0, a1, b0, b1: Vec3,
    clampA0, clampA1, clampB0, clampB1: bool
  ): (Vec3, Vec3, float) =

  proc det(a, v1, v2: Vec3): float =
    return
      a.x * (v1.y * v2.z - v1.z * v2.y) +
      a.y * (v1.z * v2.x - v1.x * v2.z) +
      a.z * (v1.x * v2.y - v1.y * v2.x)

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


proc computeSegToSeg*(a0, a1, b0, b1: Vec3): (Vec3, Vec3, float) =
  computeLineToLine(a0, a1, b0, b1, true, true, true, true)


proc computePointToSeg*(point, a, b: Vec3): (Vec3, float) =
  ##  Point between Point to Segment
  let
    d = (b - a) / b.dist(a)
    v = point - a
    t = v.dot(d)
    pointPToS = a + t * d
  return (pointPToS, pointPToS.dist(point))

