import math, tables, json
import vmath

type
  OrbitalElements* = object
    id*: int # JPL horizon ID
    name*: string # object name
    om*: float # longitude of the ascending node
    i*: float # inclination to the ecliptic (plane of the Earth's orbit)
    w*: float # argument of perihelion
    a*: float # semi-major axis, or mean distance from Sun
    e*: float # eccentricity (0=circle, 0-1=ellipse, 1=parabola)
    m*: float # mean anomaly (0 at perihelion increases uniformly with time)
    n*: float # Mean motion


  OrbitalVectors* = object
    pos*: Vec3 # position
    vel*: Vec3 # velocity
    time*: float64 # time


const Y2000* = 946684800.0
const J2000* = 2451544.5
const AU* = 149597870700.0
const KM* = 1000.0
const DAY* = 60*60*24


proc toJulianDate*(time: float64): float64 =
  (time - Y2000) / DAY + J2000


const elementsData = staticRead("elements.json")
var simpleElements* = parseJson(elementsData).to(seq[OrbitalElements])

proc period*(oe: OrbitalElements): float =
  return 365.2568984 * pow(oe.a, 1.5) * 24*60*60

proc rev*(x: float): float =
  var rv = x - round(x / 360.0) * 360.0
  if rv < 0.0:
    rv = rv + 360.0
  return rv

proc toRadians*(deg: float): float =
  return PI * deg / 180.0

proc toDegrees*(rad: float): float =
  return rev(180.0 * rad / PI)

proc posAt*(orbitalElements: OrbitalElements, time: float): Vec3 =
  var d = time / (24*60*60)

  var N = orbitalElements.om  # (Long asc. node)
  var i = orbitalElements.i   # (Inclination)
  var w = orbitalElements.w   # (Arg. of perigee)
  var a = orbitalElements.a   # (Mean distance)
  var e = orbitalElements.e   # (Eccentricity)
  var M = orbitalElements.m   # (Mean anomaly)
  M += orbitalElements.n * d  # (Mean motion)

  # Normalize angles
  N = rev(N)
  i = rev(i)
  w = rev(w)
  M = rev(M)

  # Compute the eccentric anomaly E from the mean anomaly M and from the eccentricity e (E and M in degrees):
  var E = M + (180/PI) * e * sin(toRadians(M)) * (1.0 + e * cos(toRadians(M)))
  var error = 1.0
  while error > 0.005:
    var E1 = E - (E - (180/PI) * e * sin(toRadians(E)) - M) / (1 - e * cos(toRadians(E)))
    error = abs(E - E1)
    E = E1

  # Then compute the body's distance r and its true anomaly v from:
  var x = a * (cos(toRadians(E)) - e)
  var y = a * (sqrt(1.0 - e*e) * sin(toRadians(E)))

  # Then we convert this to distance and true anonaly:
  var r = sqrt(x*x + y*y)
  var v = toDegrees(arctan2(y, x))

  var n_rad = toRadians(N)
  var xw_rad = toRadians(v + w)
  var i_rad = toRadians(i)

  # To compute the position in ecliptic coordinates, we apply these formulae:
  var xeclip = r * ( cos(n_rad) * cos(xw_rad) - sin(n_rad) * sin(xw_rad) * cos(i_rad) )
  var yeclip = r * ( sin(n_rad) * cos(xw_rad) + cos(n_rad) * sin(xw_rad) * cos(i_rad) )
  var zeclip = r * sin(xw_rad) * sin(i_rad)

  var RA   = toDegrees(arctan2(yeclip, xeclip))
  var Decl = toDegrees(arcsin(zeclip / r))

  return vec3(xeclip, yeclip, zeclip) * AU
