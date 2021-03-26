import os, strutils, puppy

proc cutBy*(text, startStr, endStr: string): string =
  let a = text.find(startStr)
  if a == -1:
    return
  let b = text.find(endStr, start=a + startStr.len)
  if b == -1:
    return
  return text[a + startStr.len ..< b]


proc downloadFileIfNotExists*(url, filePath: string) =
  let dir = filePath.splitPath.head
  if not existsDir(dir):
    createDir(dir)
  if existsFile(filePath):
    return
  writeFile(puppy.fetch(url), filePath)
