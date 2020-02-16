import orbits/solvers, print


print MACHINE_EPSILON

block:
  func f1(x: float): float = x * x + x - 1
  for i in 0 .. 10:
    let x = float(i)/10.0
    print x, f1(x)
  echo goldenSectionSearch(0, 1, f1)

  func f2(x: float): float = - x * x + x
  for i in 0 .. 10:
    let x = float(i)/10.0
    print x, f2(x)
  echo goldenSectionSearch(0.1, 1, f2)


  func f3(x: float): float = x * x - x
  for i in 0 .. 10:
    let x = float(i)/10.0
    print x, f3(x)
  echo goldenSectionSearch(0.0, 1, f3)

block:
  proc f1(x: float): float = x * x + x
  proc f2(x: float): float = 2 * x + 1
  for i in 0 .. 10:
    let x = float(i)/10.0
    print x, f1(x), f2(x)
  echo newtonsRoot(0.1, f1, f2)