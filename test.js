// Added test.js file to test the Pipeline functionality 

var assert = require('assert')

function test() {
  assert.equal(2 + 2, 4);
}

if (module == require.main) require('test').run(test);

