-- Usage: osascript preview-sync.applescript PDF_PATH PDF_URL PHYSICAL_PAGE
-- A page of 0 refreshes without navigation. Reuse the document window so zoom
-- and window geometry survive. UI actions require the terminal's existing
-- Accessibility permission, as did the previous Preview refresh script.
on run argv
  set pdfPath to item 1 of argv
  set pdfURL to item 2 of argv
  set pageNumber to (item 3 of argv) as integer
  set previousProcess to missing value
  set targetWindow to missing value

  try
    tell application "System Events"
      set previousProcess to first application process whose frontmost is true
      if exists process "Preview" then
        tell process "Preview"
          repeat with candidate in windows
            try
              if (value of attribute "AXDocument" of candidate) is pdfURL then
                set targetWindow to contents of candidate
                exit repeat
              end if
            end try
          end repeat
        end tell
      end if
    end tell

    if targetWindow is missing value then
      tell application "Preview" to open (POSIX file pdfPath)
    end if
    tell application "Preview" to activate

    tell application "System Events"
      tell process "Preview"
        -- Wait for the requested PDF instead of typing into an arbitrary window.
        repeat 40 times
          repeat with candidate in windows
            try
              if (value of attribute "AXDocument" of candidate) is pdfURL then
                set targetWindow to contents of candidate
                exit repeat
              end if
            end try
          end repeat
          if targetWindow is not missing value then exit repeat
          delay 0.025
        end repeat
        if targetWindow is missing value then error "Could not find the requested PDF window"
        perform action "AXRaise" of targetWindow
        delay 0.15

        -- Preview disables Go to Page for a single-page PDF.
        set canNavigate to enabled of menu item "Go to Page…" of menu 1 of menu bar item "Go" of menu bar 1
        if pageNumber > 0 and canNavigate then
          if not frontmost then error "Preview lost focus; navigation cancelled"
          if exists sheet 1 of targetWindow then error "Preview has a dialog open; navigation cancelled"
          keystroke "g" using {command down, option down}
          repeat 40 times
            if exists sheet 1 of targetWindow then exit repeat
            delay 0.025
          end repeat
          if not (exists sheet 1 of targetWindow) then error "Preview did not show Go to Page"
          tell sheet 1 of targetWindow
            set value of text field 1 to pageNumber as text
            click button "OK"
          end tell
        end if

        -- Keep the existing window's geometry untouched. Writing AX position or
        -- size back can fail for tiled/full-screen windows or stale references
        -- after the navigation sheet closes, even when navigation succeeded.
      end tell
    end tell
  on error messageText number messageNumber
    my restoreFocus(previousProcess)
    error messageText number messageNumber
  end try
  my restoreFocus(previousProcess)
end run

on restoreFocus(previousProcess)
  if previousProcess is missing value then return
  try
    tell application "System Events"
      if frontmost of process "Preview" then set frontmost of previousProcess to true
    end tell
  end try
end restoreFocus
