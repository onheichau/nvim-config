// Run with node tests/preview-page.js. Tests page-boundary text disambiguation.
const assert = require('node:assert/strict');
const { resolvePage, resolveTarget } = require('../scripts/preview-page.js');
const pages = [
  { page: 1, text: 'A paragraph flows naturally until the boundary' },
  { page: 2, text: 'word on the next page and keeps going.' },
];
assert.equal(resolvePage(pages, 'A paragraph flows naturally until the ', 'boundary word on the next page and keeps going.'), 1);
assert.equal(resolvePage(pages, 'A paragraph flows naturally until the boundary ', 'word on the next page and keeps going.'), 2);
assert.equal(resolvePage(pages, 'A paragraph flows naturally until the boundary wo', 'rd on the next page and keeps going.'), 2);
assert.equal(resolvePage([
  { page: 1, text: 'repeat repeat repeat' }, { page: 2, text: 'repeat repeat repeat' },
], 'repeat repeat repeat repeat ', 'repeat repeat'), 2);
assert.equal(resolvePage([{ page: 1, text: 'Other output' }], 'unmatched ', 'source material'), null);
assert.deepEqual(resolveTarget([{page: 1, text: 'The ﬁnal word'}], 'The fi', 'nal word'),
  {page: 1, index: 4, length: 4});
console.log('PASS: first word on page 2, previous word on page 1, mid-word cursor, repeated prose, uncertain fallback');
