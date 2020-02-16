import math

func computeMachineEpsilon(): float =
  ## Return a number you can add to 1.0 and still get 1.0
  result = 1.0
  while true:
    result *= 0.5
    if (1.0 + result) == 1.0:
      break

const
  GOLDEN_RATIO* = (1 + sqrt(5.0)) / 2
  MACHINE_EPSILON* = computeMachineEpsilon()


proc isNaN*(x: float): bool = x.classify == fcNaN
proc isInf*(x: float): bool = x.classify == fcInf


proc newtonsRoot*(x0: float, f, df: proc(x: float): float): float =
  ## Finds the root of f(x) near x0 given df(x) = f'(x)
  var
    x0 = x0
    x = 0.0
  while true:
    x = x0 - f(x0) / df(x0)
    if isNaN(x) or abs(x - x0) < 1e-6: # Close enough
      return x
    x0 = x


proc goldenSectionSearch*(x1, x2: float, f: proc(x: float): float, epsilon=MACHINE_EPSILON): float =
  # Finds the minimum of f(x) between x1 and x2. Returns x.
  # See: http://en.wikipedia.org/wiki/Golden_section_search

  let
    k = 2 - GOLDEN_RATIO
  var
    x3 = x2
    x2 = x1 + k * (x3 - x1)
    x1 = 0.0
    x = 0.0

    y2 = f(x2)
    y = 0.0

  while true:
    if (x3 - x2) > (x2 - x1):
      x = x2 + k * (x3 - x2)
    else:
      x = x2 - k * (x2 - x1)

    if (x3 - x1) <= (epsilon * (x2 + x)): # Close enough
      return (x3 + x1) / 2

    y = f(x)
    if y < y2:
      if (x3 - x2) > (x2 - x1):
        x1 = x2
      else:
        x3 = x2
      x2 = x
      y2 = y
    else:
      if (x3 - x2) > (x2 - x1):
        x3 = x
      else:
        x1 = x