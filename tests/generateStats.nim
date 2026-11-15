import strformat
import orbits/simple, orbits/spk, orbits/horizon
import vmath

var hz = newHorizonClient()

# mercury 58.6462 days (sidereal)
# venus   243.018 days (sidereal, retrograde)
# earth   0.99726968 days
# mars    1.02595676 days
# jupiter 0.41354 days


# mercury   0.01
# venus     177.36
# earth     23.45
# mars      25.19
# jupiter   3.13
# saturn    26.73
# uranus    97.77
# neptue    28.32
# pluto     122.53


hz.debug = false

for planetId in [199, 299, 399, 499, 599, 699, 799, 899, 999]:
  echo planetId
  echo "  radius:", hz.getRadius(Y2000, planetId), " m"
  let
    axis = hz.getRotationAxis(Y2000, planetId)
    inclination = arccos(clamp(axis.normalize().z, -1.0, 1.0))
  echo "  axis:", axis, " unit vector ", inclination / PI * 180, " deg"
  var speed = hz.getRotationAngularSpeed(Y2000, planetId)
  echo "  angular speed:", speed, " rad/s ", (2*PI/speed)/DAY, " days"


hz.close()
