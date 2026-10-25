// Resolve the cursor's PDF page and vertical text position from SyncTeX candidates.
// PDFKit reads text only; this helper never activates or controls an application.
function normalize(text, source) {
  text = text.replace(/\u00ad/g, '').replace(/([A-Za-z])-\s*\n\s*([A-Za-z])/g, '$1$2');
  text = text.replace(/\ufb01/g, 'fi').replace(/\ufb02/g, 'fl');
  if (source) {
    text = text.replace(/(^|[^\\])%[^\n]*/g, '$1');
    text = text.replace(/\\(?:begin|end|label)\{[^}]*\}/g, ' ');
    text = text.replace(/\\[A-Za-z]+\*?/g, '');
  }
  return text.toLowerCase();
}

function tokens(text) {
  var expression = /[a-z0-9\u00c0-\uffff]+/g;
  var result = [], match;
  while ((match = expression.exec(text))) result.push({ word: match[0], start: match.index, end: expression.lastIndex });
  return result;
}

function occurrences(words, needle) {
  var result = [];
  outer: for (var i = 0; i <= words.length - needle.length; i++) {
    for (var j = 0; j < needle.length; j++) if (words[i + j] !== needle[j]) continue outer;
    result.push(i);
  }
  return result;
}

function indexedPDFTokens(text) {
  var normalized = '', offsets = [];
  for (var i = 0; i < text.length; i++) {
    var character = text[i];
    if (character === '\u00ad') continue;
    if (character === '-' && i > 0 && /[A-Za-z]/.test(text[i - 1])) {
      var continuation = text.slice(i + 1).match(/^\s*\n\s*(?=[A-Za-z])/);
      if (continuation) { i += continuation[0].length; continue; }
    }
    var replacement = (character === '\ufb01' ? 'fi' : character === '\ufb02' ? 'fl' : character).toLowerCase();
    for (var j = 0; j < replacement.length; j++) {
      normalized += replacement[j]; offsets.push(i);
    }
  }
  return tokens(normalized).map(function (token) {
    token.index = offsets[token.start];
    token.length = offsets[token.end - 1] - token.index + 1;
    return token;
  });
}

function resolveTarget(pages, before, after) {
  var prefix = normalize(before, true);
  var suffix = normalize(after, true);
  var source = tokens(prefix + suffix);
  if (!source.length) return null;
  var target = source.length - 1;
  for (var i = 0; i < source.length; i++) {
    if (source[i].end > prefix.length) { target = i; break; }
  }
  var sourceWords = source.map(function (t) { return t.word; });
  var outputWords = [], outputTargets = [];
  pages.forEach(function (page) {
    indexedPDFTokens(page.text).forEach(function (token) {
      outputWords.push(token.word);
      outputTargets.push({ page: page.page, index: token.index, length: token.length });
    });
  });
  // Context may cross the PDF page boundary. Match the cursor's token within it,
  // rather than assigning the whole paragraph to the first matching page.
  var radii = [8, 6, 4, 2, 1, 0];
  for (var r = 0; r < radii.length; r++) {
    var left = Math.max(0, target - radii[r]);
    var needle = sourceWords.slice(left, Math.min(source.length, target + radii[r] + 1));
    var hits = occurrences(outputWords, needle);
    if (!hits.length) continue;
    if (hits.length === 1) return outputTargets[hits[0] + target - left];
    // For repeated filler/prose, use the corresponding occurrence only when
    // counts agree. Otherwise leave uncertain math/macro matches to SyncTeX.
    var sourceHits = occurrences(sourceWords, needle);
    if (hits.length === sourceHits.length) {
      var ordinal = sourceHits.indexOf(left);
      if (ordinal >= 0) return outputTargets[hits[ordinal] + target - left];
    }
  }
  return null;
}

function resolvePage(pages, before, after) {
  var target = resolveTarget(pages, before, after);
  return target ? target.page : null;
}

var loadedDocument;
function readPages(path, requested) {
  ObjC.import('PDFKit');
  var document = $.PDFDocument.alloc.initWithURL($.NSURL.fileURLWithPath(path));
  loadedDocument = document;
  var result = [];
  for (var i = 0; i < Number(document.pageCount); i++) {
    if (requested && requested.indexOf(i + 1) < 0) continue;
    var page = document.pageAtIndex(i);
    var text = ObjC.unwrap(page.string) || '';
    var label = ObjC.unwrap(page.label);
    var lines = text.split('\n');
    while (lines.length && lines[lines.length - 1].trim() === '') lines.pop();
    if (lines.length && lines[lines.length - 1].trim() === label) lines.pop();
    result.push({ page: i + 1, text: lines.join('\n') });
  }
  return result;
}

function run(argv) {
  if (argv[0] === '--inspect') return JSON.stringify(readPages(argv[1]));
  ObjC.import('Foundation');
  var data = $.NSFileHandle.fileHandleWithStandardInput.readDataToEndOfFile;
  var input = JSON.parse(ObjC.unwrap($.NSString.alloc.initWithDataEncoding(data, $.NSUTF8StringEncoding)));
  var pages = readPages(argv[0], input.pages);
  var target = resolveTarget(pages, input.before, input.after);
  var selected = target || input.fallback;
  if (!selected || !selected.page) return JSON.stringify({ page: null });
  var result = { page: selected.page };
  var page = loadedDocument.pageAtIndex(selected.page - 1);
  var bounds = page.boundsForBox(0);
  if (target) {
    var selection = page.selectionForRange($.NSMakeRange(target.index, target.length));
    var rectangle = selection.boundsForPage(page);
    if (rectangle.size.height > 0) {
      result.y = (bounds.origin.y + bounds.size.height - rectangle.origin.y - rectangle.size.height / 2) / bounds.size.height;
    }
  } else if (typeof selected.y === 'number') {
    result.y = selected.y / bounds.size.height;
  }
  if (typeof result.y === 'number') result.y = Math.max(0, Math.min(1, result.y));
  return JSON.stringify(result);
}

if (typeof module !== 'undefined') module.exports = { resolvePage: resolvePage, resolveTarget: resolveTarget };
