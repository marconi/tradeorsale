root = (exports ? window)

TradeOrSale =
  apiVersion: 'v1'
  errorMsgs:
    required: "This field is required"
    invalidPrice: "Invalid price"
    invalidQuantity: "Invalid quantity"
    createTagPermissionDenied: "You don't have enough privilege yet to create new tags"

class ItemImage extends Backbone.Model
  defaults:
    item_id: ''
    original: ''
    medium: ''
    small: ''
  urlRoot: ->
    return '/' + TradeOrSale.apiVersion + '/users/' + currentUser.id + '/items/' + @get('item_id')


class ItemImages extends Backbone.Collection
  model: ItemImage


class ItemTag extends Backbone.Model
  defaults:
    name: ''
  urlRoot: '/item/tags'


class ItemTags extends Backbone.Collection
  model: ItemTag

  findByName: (tagName) ->
    return this.find (tag) ->
      if tag.get('name') == tagName
        return tag


class Item extends Backbone.Model
  defaults:
    id_b36: ''
    name: ''
    type: 'TRADE'
    trade_with: ''
    price: ''
    quantity: 1
    original_quantity: 1
    description: ''
    reason: ''
    is_draft: false
    tags: new ItemTags()
    created: ''

    # traded-on/sold-on date
    transaction_date: ''

  url: ->
    url = @urlRoot()
    if not @isNew()
      url += '/' + @id
    return url

  urlRoot: ->
    return '/' + TradeOrSale.apiVersion + '/users/' + currentUser.id + '/items'

  validators:
    price: (value) ->
      return /^\d[\d.,]*$/.test(value)
    quantity: (value) ->
      return /^\d+$/.test(value) and parseInt(value, 10) > 0

  initialize: ->
    # NOTE: we never create an images attribute so it doesn't get submitted
    # everytime we have a field update. URLs tend to be longer, which
    # will make payload fat :)
    @images = new ItemImages()
    @pendingTags = new ItemTags()

  validate: (attrs) ->
    errors = @errors = {}
    console.log attrs
    if attrs.name?
      errors['name'] = TradeOrSale.errorMsgs['required'] if not attrs.name

    if attrs.description?
      errors['description'] = TradeOrSale.errorMsgs['required'] if not attrs.description

    if attrs.price?
      errors['price'] = TradeOrSale.errorMsgs['required'] if (attrs.type == 'SALE' or not attrs.type?) and not attrs.price
      errors['price'] = TradeOrSale.errorMsgs['invalidPrice'] if attrs.price and not @validators['price'](attrs.price)

    if attrs.trade_with?
      errors['trade_with'] = TradeOrSale.errorMsgs['required'] if (attrs.type == 'TRADE' or not attrs.type?) and not attrs.trade_with

    if attrs.quantity?
      errors['quantity'] = TradeOrSale.errorMsgs['invalidQuantity'] if attrs.quantity and not @validators['quantity'](attrs.quantity)
      errors['quantity'] = TradeOrSale.errorMsgs['required'] if not attrs.quantity

    if not _.isEmpty(errors)
      return errors


# preload our image preloader
imagePreloader = new Image
imagePreloader.className = 'preloader'
imagePreloader.src = baseUrl + '/static/images/image-preloader.gif'

TradeOrSale.Item = Item
TradeOrSale.ItemImage = ItemImage
TradeOrSale.ItemTag = ItemTag
TradeOrSale.ItemTags = ItemTags
TradeOrSale.ItemImages = ItemImages
TradeOrSale.imagePreloader = imagePreloader
root.TradeOrSale = TradeOrSale
