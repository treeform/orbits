import
  boxy, opengl, pixie, vmath, windy

export pixie, vmath, windy

var
  screen*: Image
  mouseWheelDelta*: float32
  window: Window
  renderer: Boxy

proc start*(title: string) =
  ## Opens a fixed-size window for the software-rendered demo image.
  screen = newImage(800, 600)
  window = newWindow(title, ivec2(800, 600), style = Decorated)
  window.makeContextCurrent()
  loadExtensions()
  renderer = newBoxy()

proc isKeyDown*(key: Button): bool =
  ## Reports whether a key is held in the most recent event poll.
  window.buttonDown[key]

proc tick*() =
  ## Presents the current image and polls keyboard, wheel and close events.
  renderer.beginFrame(window.size)
  renderer.addImage("screen", screen, mipmaps = false)
  renderer.drawImage("screen", rect = rect(vec2(0), window.size.vec2))
  renderer.endFrame()
  window.swapBuffers()
  pollEvents()
  mouseWheelDelta = window.scrollDelta.y
  if window.closeRequested:
    window.close()
    quit(0)
