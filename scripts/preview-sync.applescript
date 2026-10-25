-- Usage: osascript preview-sync.applescript PDF_PATH PDF_URL PHYSICAL_PAGE [DISPLAY_SCRIPT]
-- A page of 0 refreshes without navigation. Reuse the document window so zoom
-- and window geometry survive. UI actions require the terminal's existing
-- Accessibility permission, as did the previous Preview refresh script.
on run argv
  set pdfPath to item 1 of argv
  set pdfURL to item 2 of argv
  set pageNumber to (item 3 of argv) as integer
  set previousProcess to missing value
  set targetWindow to missing value
  set placementNote to ""
  set navigationStarted to false

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
        repeat 100 times
          if frontmost then exit repeat
          delay 0.01
        end repeat
        -- Briefly allow Preview to reload after activation; avoid a long fixed wait.
        delay 0.05

        -- Optional placement runs before opening the navigation sheet. Failure
        -- to move a window must not interrupt otherwise working PDF sync.
        if (count of argv) >= 4 and item 4 of argv is not "" then
          set placementNote to my placePDF(item 4 of argv, pdfURL)
        end if

        -- Preview disables Go to Page for a single-page PDF.
        set canNavigate to enabled of menu item "Go to Page…" of menu 1 of menu bar item "Go" of menu bar 1
        if pageNumber > 0 and canNavigate then
          if not frontmost then error "Preview lost focus; navigation cancelled"
          set targetWindow to my findPDFWindow(pdfURL)
          if exists sheet 1 of targetWindow then error "Preview has a dialog open; navigation cancelled"
          set navigationStarted to true
          set reportedPage to my openPageDialog(pdfURL)
          -- On PDF reload, Preview can retain currentPage while resetting its
          -- scroll position to page one. Going to that same page is then a no-op.
          -- A real page transition resets PDFKit's stale navigation state.
          if reportedPage is (pageNumber as text) then
            if pageNumber > 1 then
              set neighboringPage to pageNumber - 1
            else
              set neighboringPage to 2
            end if
            my submitPage(pdfURL, neighboringPage)
            my openPageDialog(pdfURL)
          end if
          my submitPage(pdfURL, pageNumber)
        end if

        -- Navigation never restores window geometry after the sheet closes.
      end tell
    end tell
  on error messageText number messageNumber
    if navigationStarted then my cancelPageDialog(pdfURL)
    my restoreFocus(previousProcess)
    error messageText number messageNumber
  end try
  my restoreFocus(previousProcess)
  return placementNote
end run

-- System Events resolves windows by their title. Page navigation changes that
-- title, so never carry a window reference across a submitted page change.
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

on openPageDialog(pdfURL)
  tell application "System Events" to tell process "Preview"
    if not frontmost then error "Preview lost focus; navigation cancelled"
    -- Invoking the menu action avoids a shortcut being lost during sheet animation.
    repeat 150 times
      if enabled of menu item "Go to Page…" of menu 1 of menu bar item "Go" of menu bar 1 then exit repeat
      delay 0.01
    end repeat
    click menu item "Go to Page…" of menu 1 of menu bar item "Go" of menu bar 1
    repeat 150 times
      set liveWindow to my findPDFWindow(pdfURL)
      if liveWindow is not missing value then
        try
          if exists sheet 1 of liveWindow then
            if exists text field 1 of sheet 1 of liveWindow then return value of text field 1 of sheet 1 of liveWindow
          end if
        end try
      end if
      delay 0.01
    end repeat
    error "Preview did not show Go to Page"
  end tell
end openPageDialog

on submitPage(pdfURL, pageNumber)
  tell application "System Events" to tell process "Preview"
    set liveWindow to my findPDFWindow(pdfURL)
    if liveWindow is missing value then error "Could not find the PDF during navigation"
    tell sheet 1 of liveWindow
      set value of text field 1 to pageNumber as text
      click button "OK"
    end tell
    repeat 150 times
      set liveWindow to my findPDFWindow(pdfURL)
      if liveWindow is not missing value then
        try
          if not (exists sheet 1 of liveWindow) then return
        end try
      end if
      delay 0.01
    end repeat
    error "Preview did not finish page navigation"
  end tell
end submitPage

on cancelPageDialog(pdfURL)
  try
    set liveWindow to my findPDFWindow(pdfURL)
    if liveWindow is missing value then return
    tell application "System Events" to tell process "Preview"
      tell sheet 1 of liveWindow
        if exists static text "Go to page:" then click button "Cancel"
      end tell
    end tell
  end try
end cancelPageDialog

on placePDF(displayScript, pdfURL)
  try
    return do shell script "/usr/bin/osascript -l JavaScript " & quoted form of displayScript & " " & quoted form of pdfURL
  on error placementError
    return "Built-in display placement: " & placementError
  end try
end placePDF

on restoreFocus(previousProcess)
  if previousProcess is missing value then return
  try
    tell application "System Events"
      if frontmost of process "Preview" then set frontmost of previousProcess to true
    end tell
  end try
end restoreFocus
