// Native JXA: identify the built-in display, then maximize only the requested PDF.
// Run with --inspect for read-only display diagnostics (no Accessibility access).
function targetFrame(screens) {
  if (screens.length < 2 || !screens.some(function (s) { return !s.builtIn; })) return null;
  var builtIn = screens.filter(function (s) { return s.builtIn; })[0];
  if (!builtIn) return null; // Closed lid, desktop Mac, or mirroring.
  var top = screens[0].frame.y + screens[0].frame.height;
  var area = builtIn.visibleFrame;
  return {
    x: Math.round(area.x),
    y: Math.round(top - area.y - area.height),
    width: Math.round(area.width),
    height: Math.round(area.height)
  };
}

function displayInfo() {
  ObjC.import('AppKit');
  ObjC.import('CoreGraphics');
  ObjC.bindFunction('CGDisplayIsBuiltin', ['bool', ['unsigned int']]);
  var nativeScreens = $.NSScreen.screens;
  var screens = [];
  function rect(value) {
    return { x: value.origin.x, y: value.origin.y, width: value.size.width, height: value.size.height };
  }
  for (var i = 0; i < nativeScreens.count; i++) {
    var screen = nativeScreens.objectAtIndex(i);
    var id = screen.deviceDescription.objectForKey('NSScreenNumber').unsignedIntValue;
    screens.push({
      builtIn: Boolean($.CGDisplayIsBuiltin(id)),
      frame: rect(screen.frame),
      visibleFrame: rect(screen.visibleFrame)
    });
  }
  return screens;
}

function run(argv) {
  var screens = displayInfo();
  var frame = targetFrame(screens);
  if (argv[0] === '--inspect') return JSON.stringify({ screens: screens, target: frame });
  if (!frame) return '';
  var process = Application('System Events').processes.byName('Preview');
  var windows = process.windows();
  for (var i = 0; i < windows.length; i++) {
    var window = windows[i];
    var url;
    try { url = window.attributes.byName('AXDocument').value(); } catch (_) { continue; }
    if (url !== argv[0]) continue;
    try {
      if (window.attributes.byName('AXFullScreen').value()) {
        return 'Leave macOS full-screen mode to place the PDF on the built-in display.';
      }
    } catch (_) {}
    var position = window.position();
    var size = window.size();
    if (Math.abs(position[0] - frame.x) <= 1 && Math.abs(position[1] - frame.y) <= 1 &&
        Math.abs(size[0] - frame.width) <= 1 && Math.abs(size[1] - frame.height) <= 1) return '';
    // Move before sizing, so macOS applies the target screen's constraints.
    // JXA setters avoid AppleScript's ambiguous dynamic window-property syntax.
    window.position = [frame.x, frame.y];
    window.size = [frame.width, frame.height];
    window.position = [frame.x, frame.y];
    return '';
  }
  return 'Could not find the PDF window for built-in display placement.';
}

if (typeof module !== 'undefined') module.exports = { targetFrame: targetFrame };
