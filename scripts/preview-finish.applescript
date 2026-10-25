-- Detached exit-only action. Editing-time refresh/navigation is independent.
-- Arguments: PDF_PATH PDF_URL DISPLAY_SCRIPT PREVIOUS_REFRESH_PID
on run argv
  set pdfPath to item 1 of argv
  set pdfURL to item 2 of argv
  set displayScript to item 3 of argv
  set previousPID to (item 4 of argv) as integer

  -- Let any already-running refresh return focus before the final handoff.
  -- This waits in the detached helper instead of delaying Neovim's exit.
  if previousPID > 0 then
    do shell script "attempts=0; while /bin/kill -0 " & previousPID & " 2>/dev/null && [ $attempts -lt 160 ]; do /bin/sleep 0.025; attempts=$((attempts+1)); done"
  end if
  try
    do shell script "/usr/bin/test -r " & quoted form of pdfPath
  on error
    return
  end try

  do shell script "/usr/bin/open -a Preview " & quoted form of pdfPath
  tell application "Preview" to activate
  repeat 120 times
    set pdfWindow to my findPDFWindow(pdfURL)
    if pdfWindow is not missing value then exit repeat
    delay 0.025
  end repeat
  if pdfWindow is missing value then return

  try
    do shell script "/usr/bin/osascript -l JavaScript " & quoted form of displayScript & " " & quoted form of pdfURL & " external"
  end try
  -- Deliberately leave the PDF focused instead of restoring the terminal.
  tell application "Preview" to activate
  set pdfWindow to my findPDFWindow(pdfURL)
  if pdfWindow is not missing value then
    tell application "System Events" to perform action "AXRaise" of pdfWindow
  end if
end run

on findPDFWindow(pdfURL)
  tell application "System Events" to tell process "Preview"
    repeat with candidate in windows
      try
        if (value of attribute "AXDocument" of candidate) is pdfURL then return contents of candidate
      end try
    end repeat
  end tell
  return missing value
end findPDFWindow
