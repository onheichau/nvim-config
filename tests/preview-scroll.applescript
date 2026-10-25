-- Usage: osascript tests/preview-scroll.applescript /path/to/compiled-preview-sync.scpt
-- Loads the real production math handler; no application UI is accessed.
on run argv
  set helperScript to load script (POSIX file (item 1 of argv))
  my checkClose(helperScript's centeredScroll(0, 100, 1600, 0.9, 100, 900, 4800), 990 / 3900)
  my checkClose(helperScript's centeredScroll(0, 100, 1600, 0.3, 100, 900, 4800), 0)
  my checkClose(helperScript's centeredScroll(0, 100, 1600, 0, 100, 900, 4800), 0)
  my checkClose(helperScript's centeredScroll(0, 4100, 1600, 1, 100, 900, 4800), 1)
  my checkClose(helperScript's centeredScroll(0.4, 100, 800, 0.9, 100, 900, 800), 0.4)
  return "PASS: lower-page centering, stable visible text, scroll limits, fully visible page"
end run

on checkClose(actualValue, expectedValue)
  set difference to actualValue - expectedValue
  if difference < 0 then set difference to -difference
  if difference > 0.00001 then error "Scroll calculation mismatch"
end checkClose
