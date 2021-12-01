// file under test
require('../js/app');

// makes asserts work
var assert = require('assert');
var refute = require("refute")(assert); // for the binding

var test_tz = 'America/New_York';

// this is just for testing out ways to test stuff in Mocha...
describe('Array', function() {
  describe('#indexOf()', function() {
    it('should return -1 when the value is not present', function(done) {
      assert.equal([1,2,3].indexOf(4), -1);
      done();
    });
    it('should demonstrate asserting on a throw', function(done) {
      assert.throws(function() {
        undefined_function();
      }, Error);
      done();
    });
  });
});

// ACTUAL TEST SUITE BEGINS HERE
describe('ConvertFromUTCToLocalDatetime', function() {
  it('should return a sensical answer', function(done) {
    assert.equal(window.ConvertFromUTCToLocalDatetime("2018-02-28T18:26:24.000Z", test_tz), "2/28/2018 1:26 PM");
    done();
  })
});
describe('ConvertFromUTCToLocalDate', function() {
  it('should return a sensical answer', function(done) {
    assert.equal(window.ConvertFromUTCToLocalDate("2018-02-28"), "2/28/2018");
    done();
  });
});
describe('ConvertFromFriendlyToUTCDatetime', function() {
  it('should return correct datetime from default friendly format', function(done) {
    assert.equal(window.ConvertFromFriendlyToUTCDatetime("Wed Feb 28 2018 @ 3:00PM", test_tz), "2018-02-28T20:00:00Z");
    done();
  });
  it('should return earliest datetime from friendly format with hyphenated time range', function(done) {
    assert.equal(window.ConvertFromFriendlyToUTCDatetime("Wed Feb 28 2018 @ 3:00PM-5:00PM", test_tz), "2018-02-28T20:00:00Z");
    done();
  });
  it('should return earliest datetime from friendly format with hyphenated time range and multiple datetime ranges', function(done) {
    assert.equal(window.ConvertFromFriendlyToUTCDatetime("Wed Feb 28 2018 @ 3:00PM-5:00PM; Sat Mar 3 2018 @ 1:00PM-4:00PM", test_tz), "2018-02-28T20:00:00Z");
    done();
  });
});
describe('ConvertFromLocalToUTCDatetime', function() {
  it('should convert local datetime to UTC ISO datetime even across midnight AND non-leap year', function(done) {
    assert.equal(window.ConvertFromLocalToUTCDatetime("2/28/2018 9:00 PM", test_tz), "2018-03-01T02:00:00Z");
    done();
  })
});
describe('ConvertFromLocalToUTCDate', function() {
  it('should convert local date to UTC ISO date', function(done) {
    assert.equal(window.ConvertFromLocalToUTCDate("2/28/2018"), "2018-02-28");
    assert.equal(window.ConvertFromLocalToUTCDate(""), "");
    done();
  });
});
describe('IsNonblankString', function() {
  it('should return false on null', function(done) {
    refute(window.IsNonblankString(null));
    done();
  });
  it('should return false on ""', function(done) {
    refute(window.IsNonblankString(""));
    done();
  });
  it('should return false on "      \\n  "', function(done) {
    refute(window.IsNonblankString("      \n  "));
    done();
  });
  it('should return true on "     this  "', function(done) {
    assert(window.IsNonblankString("      this  "));
    done();
  });
});
describe('USDatetimeSorter', function() {
  it('should return -1 if the first arg is blank', function(done) {
    assert.equal(-1, window.USDatetimeSorter("","1/15/2018 3:00PM"));
    done();
  });
  it('should return 1 if the second arg is blank', function(done) {
    assert.equal(1, window.USDatetimeSorter("1/15/2018 3:00PM", ""));
    done();
  });
  it('should return 1 if the first arg is later than the second arg', function(done) {
    assert.equal(1, window.USDatetimeSorter("1/16/2018 12:00PM", "1/15/2018 3:00PM"));
    done();
  });
  it('should return -1 if the first arg is earlier than the second arg', function(done) {
    assert.equal(-1, window.USDatetimeSorter("1/14/2018 12:00PM", "1/15/2018 3:00PM"));
    done();
  });
  it('should return 0 if the first arg is the same datetime as the second arg', function(done) {
    assert.equal(0, window.USDatetimeSorter("1/15/2018 3:00PM", "1/15/2018 3:00PM"));
    done();
  });
});
describe('PriceSorter', function() {
  it('should return -1 if the first price is blank', function(done) {
    assert.equal(-1, window.PriceSorter("","$1,000,000"));
    done();
  });
  it('should return 1 if the second price is blank', function(done) {
    assert.equal(1, window.PriceSorter("$1,000,000", ""));
    done();
  });
  it('should return 1 if the first price is greater than the second price', function(done) {
    assert.equal(1, window.PriceSorter("1000001", "$1,000,000"));
    done();
  });
  it('should return -1 if the first price is less than the second price', function(done) {
    assert.equal(-1, window.PriceSorter("$1,000,000", "$1,000,001"));
    done();
  });
  it('should return 0 if the first price is the same as the second price', function(done) {
    assert.equal(0, window.PriceSorter("$1,000,000", "$1,000,000"));
    done();
  });
});
describe('StripTags', function() {
  it('should trim spaces from the end, convert runs of spaces/tabs/LF to 1 space and strip tags', function(done) {
    assert.equal("this is a string without tags", window.StripTags("   this <i>is a</i>  \n <a href='blah'>string </a> without tags  "));
    done();
  })
});
describe('OpenHouseSorter', function() {
  it('should return -1 if the first open house is blank', function(done) {
    assert.equal(-1, window.OpenHouseSorter("","Wed Feb 28 2018 @ 3:00PM"));
    done();
  });
  it('should return 1 if the second open house is blank', function(done) {
    assert.equal(1, window.OpenHouseSorter("Wed Feb 28 2018 @ 3:00PM", ""));
    done();
  });
  it('should return 1 if the first open house is later than the second open house', function(done) {
    assert.equal(1, window.OpenHouseSorter("Wed Feb 28 2018 @ 4:00PM", "Wed Feb 28 2018 @ 3:00PM"));
    done();
  });
  it('should return -1 if the first open house is earlier than the second open house', function(done) {
    assert.equal(-1, window.OpenHouseSorter("Wed Feb 28 2018 @ 3:00PM", "Thu Mar 1 2018 @ 3:00PM"));
    done();
  });
  it('should return 0 if the first open house is the same datetime as the second open house', function(done) {
    assert.equal(0, window.OpenHouseSorter("Wed Feb 28 2018 @ 3:00PM", "Wed Feb 28 2018 @ 3:00PM"));
    done();
  });
});
describe('AddressWithLinksSorter', function() {
  it('should return -1 if the first address is blank', function(done) {
    assert.equal(-1, window.AddressWithLinksSorter("","<a href='/listings/2'>1 Sycamore St.</a>, Port Washington, NY"));
    done();
  });
  it('should return 1 if the second address is blank', function(done) {
    assert.equal(1, window.AddressWithLinksSorter("<a href='/listings/2'>1 Sycamore St.</a>, Port Washington, NY", ""));
    done();
  });
  it('should return 1 if the first address is alphanumerically greater than the second address', function(done) {
    assert.equal(1, window.AddressWithLinksSorter(" <a href='/listings/1'>2 Sycamore St.</a>, Port Washington, NY", "<a href='/listings/2'>1 Sycamore St.</a>, Port Washington, NY"));
    done();
  });
  it('should return -1 if the first address is alphanumerically less than than the second address', function(done) {
    assert.equal(-1, window.AddressWithLinksSorter("10 Sycamore St., Port Washington, NY", "2 Sycamore St., Port Washington, NY"));
    done();
  });
  it('should return 0 if the first address is the same as the second address', function(done) {
    assert.equal(0, window.AddressWithLinksSorter("<a href='/listings/2'>1 Sycamore St.</a>, Port Washington, NY", "<a href='/listings/2'>1 Sycamore St.</a>, Port Washington, NY"));
    done();
  });
});
