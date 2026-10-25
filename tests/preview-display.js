// Run with node tests/preview-display.js. No desktop interaction.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { targetFrame } = require('../scripts/preview-display.js');

const internal = {
  builtIn: true,
  frame: { x: -1728, y: -37, width: 1728, height: 1117 },
  visibleFrame: { x: -1728, y: -37, width: 1728, height: 1085 },
};
const external = {
  builtIn: false,
  frame: { x: 0, y: 0, width: 1920, height: 1080 },
  visibleFrame: { x: 0, y: 0, width: 1920, height: 1050 },
};
assert.equal(targetFrame([]), null);
assert.equal(targetFrame([internal]), null);
assert.equal(targetFrame([external]), null);
assert.equal(targetFrame([external, external]), null);
assert.deepEqual(targetFrame([external, internal]), { x: -1728, y: 32, width: 1728, height: 1085 });
assert.deepEqual(targetFrame([external, internal], 'external'), { x: 0, y: 30, width: 1920, height: 1050 });
assert.deepEqual(targetFrame([external], 'external'), { x: 0, y: 30, width: 1920, height: 1050 });
assert.equal(targetFrame([internal], 'external'), null);
const primaryInternal = {
  builtIn: true,
  frame: { x: 0, y: 0, width: 1728, height: 1117 },
  visibleFrame: { x: 0, y: 70, width: 1728, height: 1015 },
};
assert.deepEqual(targetFrame([primaryInternal, external]), { x: 0, y: 32, width: 1728, height: 1015 });

const url = 'file:///tmp/test.pdf';
const moves = [];
let currentPosition = [0, 0];
let currentSize = [800, 600];
const target = {
  attributes: { byName: (key) => ({ value: () => key === 'AXDocument' ? url : false }) },
  get position() { return () => currentPosition; },
  get size() { return () => currentSize; },
  set position(value) { currentPosition = Array.from(value); moves.push(['position', currentPosition]); },
  set size(value) { currentSize = Array.from(value); moves.push(['size', currentSize]); },
};
const unrelated = {
  attributes: { byName: () => ({ value: () => 'file:///tmp/unrelated.pdf' }) },
  set position(_) { assert.fail('Unrelated PDF window moved'); },
};
const context = vm.createContext({
  Application: () => ({ processes: { byName: () => ({ windows: () => [unrelated, target] }) } }),
});
vm.runInContext(fs.readFileSync(require.resolve('../scripts/preview-display.js'), 'utf8'), context);
context.displayInfo = () => [external, internal];
assert.equal(context.run([url]), '');
assert.deepEqual(moves, [
  ['position', [-1728, 32]], ['size', [1728, 1085]], ['position', [-1728, 32]],
]);
moves.length = 0;
assert.equal(context.run([url]), '');
assert.equal(moves.length, 0, 'Already-positioned window was resized again');
assert.equal(context.run([url, 'external']), '');
assert.deepEqual(moves, [
  ['position', [0, 30]], ['size', [1920, 1050]], ['position', [0, 30]],
]);
moves.length = 0;
context.displayInfo = () => [internal];
assert.equal(context.run([url]), '');
assert.equal(moves.length, 0, 'Single-display window was moved');
assert.equal(context.run([url, 'external']), '');
assert.equal(moves.length, 0, 'Exit with no external display moved the window');
console.log('PASS: display selection, coordinate conversion, PDF targeting, single-screen no-op');
