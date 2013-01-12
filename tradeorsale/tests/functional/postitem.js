var Browser = require("zombie");
    assert = require('chai').assert,
    expect = require('chai').expect,
    should = require('chai').should();

var SITE_URL = "http://localhost:6543";


describe("toggling of post-item form", function() {
  before(function(done) {
    this.browser = new Browser();
    this.browser
      .visit(SITE_URL)
      .then(done, done);
  });

  it("shouldn't have the #post-item element", function() {
    should.not.exist(this.browser.query("#post-item"));
  });

  it("should show #post-item when #btn-post-item is clicked", function() {
    this.browser.clickLink("#btn-post-item");
    should.exist(this.browser.query("#post-item"));
  });

  it("should hide #post-item when closed", function() {
    this.browser.clickLink("#close-new-item");
    var postItem = this.browser.query("#post-item");
    should.exist(postItem);
    expect(postItem.style.display).to.equal("none");
  });
});

describe("toggling of price field", function() {
  before(function(done) {
    var _self = this;
    this.browser = new Browser();
    this.browser
      .visit(SITE_URL)
      .then(function() {
        _self.browser.clickLink("#btn-post-item");
      })
      .then(done, done);
  });

  it("should display price field when type is SALE", function() {
    var typeField = this.browser.query("#post-item #type"),
        priceField = this.browser.query("#post-item .field-price");

    expect(priceField.style.display).to.equal("none");

    this.browser.select("#post-item #type", "SALE");
    expect(priceField.style.display).to.equal("");
  });

  it("should hide price field when type is TRADE", function() {
    var priceField = this.browser.query("#post-item .field-price");

    this.browser.select("#post-item #type", "TRADE");
    expect(priceField.style.display).to.equal("none");
  });
});

describe("display errors on invalid post-item form", function() {
  before(function(done) {
    var _self = this;
    this.browser = new Browser();
    this.browser.setMaxListeners(0);  // fixes memory leak warning
    this.browser
      .visit(SITE_URL)
      .then(function() {
        _self.browser.clickLink("#btn-post-item");
      })
      .then(done, done);
  });

  it("should display name field error", function() {
    var nameField = this.browser.query("#post-item #name"),
        errorField = "#post-item .field-name span.error";

    this.browser.fill("#post-item #name", "sample name");
    should.not.exist(this.browser.query(errorField));

    this.browser.fill("#post-item #name", "");
    should.exist(this.browser.query(errorField));
  });

  it("should display price field error", function() {
    var typeField = this.browser.query("#post-item #type"),
        priceField = this.browser.query("#post-item #price"),
        errorField = "#post-item .field-price span.error";

    this.browser.select("#post-item #type", "SALE");
    this.browser.fill("#post-item #price", "invalid price");
    should.exist(this.browser.query(errorField));

    this.browser.fill("#post-item #price", "");
    should.exist(this.browser.query(errorField));

    this.browser.fill("#post-item #price", "30,000");
    should.not.exist(this.browser.query(errorField));
  });

  it("should display quantity field error", function() {
    var typeField = this.browser.query("#post-item #quantity"),
        errorField = "#post-item .field-quantity span.error";

    this.browser.fill("#post-item #quantity", "");
    should.exist(this.browser.query(errorField));

    this.browser.fill("#post-item #quantity", "0");
    should.exist(this.browser.query(errorField));

    this.browser.fill("#post-item #quantity", "1");
    should.not.exist(this.browser.query(errorField));
  });

  it("should display description field error", function() {
    var typeField = this.browser.query("#post-item #description"),
        errorField = "#post-item .field-description span.error";

    this.browser.fill("#post-item #description", "");
    should.exist(this.browser.query(errorField));

    this.browser.fill("#post-item #description", "some description");
    should.not.exist(this.browser.query(errorField));
  });

  it("should display tags field error", function() {
    var tagNames = this.browser.evaluate("tagNames"),
        firstTag = tagNames.models[0].attributes.name,
        newTagField = this.browser.query("#post-item .tagit-new input"),
        errorField = "#post-item .field-tags span.error";

    this.browser.fill("#post-item .tagit-new input", "superandomtag");
    newTagField.blur();
    should.exist(this.browser.query(errorField));

    this.browser.fill("#post-item .tagit-new input", firstTag);
    newTagField.blur();
    should.not.exist(this.browser.query(errorField));
  });

  it("should display all required field errors", function() {
    var submitBtn = this.browser.query("#post-item #submit-new-item"),
        _self = this;

    this.browser.fill("#post-item #name", "")
      .select("#post-item #type", "SALE")
      .fill("#post-item #price", "")
      .fill("#post-item #quantity", "")
      .fill("#post-item #description", "")
      .fill("#post-item .tagit-new input", "");
    submitBtn.click();
    should.exist(this.browser.query("#post-item .field-name span.error"));
    should.exist(this.browser.query("#post-item .field-price span.error"));
    should.exist(this.browser.query("#post-item .field-quantity span.error"));
    should.exist(this.browser.query("#post-item .field-description span.error"));
  });
});

// FIXME: success seems to be failing upon submission
// describe("success post-item form submission", function() {
//   before(function(done) {
//     var _self = this;
//     this.browser = new Browser();
//     this.browser.debug = true;
//     this.browser.setMaxListeners(0);  // fixes memory leak warning
//     this.browser
//       .visit(SITE_URL)
//       .then(function() {
//         _self.browser.clickLink("#btn-post-item");
//       })
//       .then(done, done);
//   });

//   it("should display success message", function() {
//     var tagNames = this.browser.evaluate("tagNames"),
//         firstTag = tagNames.models[0].attributes.name,
//         submitBtn = this.browser.query("#post-item #submit-new-item"),
//         _self = this;

//     this.browser.fill("#post-item #name", "super awesome item")
//       .select("#post-item #type", "SALE")
//       .fill("#post-item #price", "250.00")
//       .fill("#post-item #quantity", "1")
//       .fill("#post-item #description", "awesome description")
//       .fill("#post-item .tagit-new input", firstTag);
//       // .pressButton("#post-item #submit-new-item", function() {
//       //   console.log("button pressed!");
//       // });

//     submitBtn.click();

//     // this.browser.wait(function() {
//     //   console.log("here!");
//     //   console.log(_self.browser.dump());
//     // });

//     console.log(this.browser.lastRequest);
//     console.log(this.browser.lastError);
//     console.log(this.browser.errors);

//     // this.browser.wait(function(window) {
//     //   var a = window.document.querySelector("#post-item .field-description span.error");
//     //   console.log(a);
//     //   return a;
//     // }, function() {
//     //   console.log("alert loaded!");
//     // });
//     // console.log(this.browser.html());
    
//     // console.log(this.browser.resources);
//     // this.browser.viewInBrowser();

//     // should.not.exist(this.browser.query("#post-item .field-name span.error"));
//     // should.not.exist(this.browser.query("#post-item .field-type span.error"));
//     // should.not.exist(this.browser.query("#post-item .field-price span.error"));
//     // should.not.exist(this.browser.query("#post-item .field-quantity span.error"));
//     // should.not.exist(this.browser.query("#post-item .field-description span.error"));
//     // should.exist(this.browser.query("#post-item #alert-wrapper .alert-success"));
//   });
// });

// TODO: test adding of newly posted item to drafts or ongoing panel
