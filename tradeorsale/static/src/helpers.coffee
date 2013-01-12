root = (exports ? window)

Handlebars.registerHelper 'listTags', (tags) ->
  out = ''
  for i in [0...tags.length]
    if (i + 1) == tags.length
      out += tags[i].name
    else
      out += tags[i].name + ','
  return new Handlebars.SafeString(out)

Handlebars.registerHelper 'nltobr', (value) ->
  value = Handlebars.Utils.escapeExpression(value)
  return new Handlebars.SafeString(value.replace(/\n/g, '<br />'))

root.escape = (str) ->
  # .replace(/[\\]/g, '\\\\')
  # .replace(/[\"]/g, '\\\"')
  # .replace(/[\/]/g, '\\/')
  # .replace(/[\b]/g, '\\b')
  # .replace(/[\f]/g, '\\f')
  # .replace(/[\n]/g, '\\n')
  # .replace(/[\r]/g, '\\r')
  # .replace(/[\t]/g, '\\t');
  return str
    .replace(/[\"]/g, '\\\"')
    .replace(/[\b]/g, '\\b')
    .replace(/[\f]/g, '\\f')
    .replace(/[\n]/g, '\\n')
    .replace(/[\r]/g, '\\r');
