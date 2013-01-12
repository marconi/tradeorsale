var Browser = require("zombie"),
    assert = require('chai').assert,
    expect = require('chai').expect,
    should = require('chai').should();

var DASHBOARD_URL = "http://localhost:6543/dashboard";


describe("toggling of panel item", function() {
  var firstLi = "#drafts .panel-items li:first-child",
      itemNameTag = "#drafts .panel-items li:first-child a.item-name";

  before(function(done) {
    this.browser = new Browser();
    this.browser
      .visit(DASHBOARD_URL)
      .then(done, done);
  });

  it("should expand when name is clicked", function() {
    var firstLiTag = this.browser.query(firstLi);

    this.browser.clickLink(itemNameTag);
    expect(firstLiTag.getAttribute("class")).to.equal("open");
  });

  it("should collapse when name is clicked", function() {
    var firstLiTag = this.browser.query(firstLi);

    this.browser.clickLink(itemNameTag);
    expect(firstLiTag.getAttribute("class")).to.not.equal("open");
  });

});



// TODO: add tests for adding more images

// describe("toggling of post-item form", function() {
  // before(function(done) {
  //   this.browser = new Browser();
  //   this.browser
  //     .visit(SITE_URL)
  //     .then(done, done);
  // });

//   it("shouldn't have the #post-item element", function() {
//     should.not.exist(this.browser.query("#post-item"));
//   });

//   it("should show #post-item when #btn-post-item is clicked", function() {
//     this.browser.clickLink("#btn-post-item");
//     should.exist(this.browser.query("#post-item"));
//   });

//   it("should hide #post-item when closed", function() {
//     this.browser.clickLink("#close-new-item");
//     var postItem = this.browser.query("#post-item");
//     should.exist(postItem);
//     postItem.style.display.should.eql("none");
//   });
// });
