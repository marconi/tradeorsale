// Generated by CoffeeScript 1.4.0
(function() {
  var root;

  root = typeof exports !== "undefined" && exports !== null ? exports : window;

  Handlebars.registerHelper('listTags', function(tags) {
    var i, out, _i, _ref;
    out = '';
    for (i = _i = 0, _ref = tags.length; 0 <= _ref ? _i < _ref : _i > _ref; i = 0 <= _ref ? ++_i : --_i) {
      if ((i + 1) === tags.length) {
        out += tags[i].name;
      } else {
        out += tags[i].name + ',';
      }
    }
    return new Handlebars.SafeString(out);
  });

  Handlebars.registerHelper('nltobr', function(value) {
    value = Handlebars.Utils.escapeExpression(value);
    return new Handlebars.SafeString(value.replace(/\n/g, '<br />'));
  });

  root.escape = function(str) {
    return str.replace(/[\"]/g, '\\\"').replace(/[\b]/g, '\\b').replace(/[\f]/g, '\\f').replace(/[\n]/g, '\\n').replace(/[\r]/g, '\\r');
  };

}).call(this);