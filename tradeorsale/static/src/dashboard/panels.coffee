root = (exports ? window)

Dashboard =
  draftsPanel: null
  ongoingPanel: null
  archivedPanel: null
  vent: new _.extend {}, Backbone.Events


class PanelItems extends Backbone.Collection
  model: TradeOrSale.Item
  name: ''

  comparator: (item) ->
    return -item.get('id')

  initialize: (models, options) ->
    @options = options

  url: ->
    url = '/' + TradeOrSale.apiVersion + '/users/' + currentUser.id + '/items?status=' + @options.name
    lastItem = @getLastItem()
    if lastItem?
      url += '&last=' + lastItem.get('id')
    return url

  getLastItem: ->
    return @at(@size()-1)


class DashboardPanelView extends Backbone.View
  template: '#dashboard-panel-template'
  events: {
    'click .panel-footer .show-more': 'showMoreItems'
    'click h3 .collapse-panel': 'collapsePanel'
  }

  initialize: ->
    # convert the json images to ItemImages
    # and json tags to ItemTags and json
    # comments to ItemComments collections.
    @collection.each (item, i) =>
      item = @_normalizeItem(item)

    @template = Handlebars.compile($(@template).html())
    @render()

    @collection.bind 'remove', @removeItem, @
    @collection.bind 'add', @addItem, @

    Dashboard.vent.on 'ItemTabSwitch:' + @options.name, @itemTabSwitch, @
    Dashboard.vent.on 'TogglePanelExpand:' + @options.name, @togglePanelExpand, @

  render: ->
    $(@el).html(@template({
      name: @options.name,
      rawName: @options.name.toLowerCase()
    }))

    if @collection.size() > 0
      @$('.empty-panel').addClass('hidden')

    # render each item
    @collection.each (item, i) =>
      isLast = if i == (@collection.size() - 1) then true else false
      itemView = new Dashboard.itemClasses[@options.name]
        model: item
        isLast: isLast
      @$(".panel-items").append(itemView.el)

  removeItem: ->
    if @collection.size() == 0
      @$('.empty-panel').removeClass('hidden')
    else
      @$('.panel-items li:last-child').addClass('last')

  addItem: (item, options) ->
    item = @_normalizeItem(item)
    isLast = if @collection.size() == 0 then true else false
    itemView = new Dashboard.itemClasses[@options.name]
      model: item
      isLast: isLast

    # hide empty label if its still shown
    if not @$('.empty-panel').hasClass('hidden')
      @$('.empty-panel').addClass('hidden')

    if item.addingMechanism? and item.addingMechanism == 'prepend'
      @$(".panel-items").prepend(itemView.el)
    else
      index = item.collection.indexOf(item)
      previousItem = item.collection.at(index - 1)
      if previousItem?
        previousItemView  = @$('#item-' + previousItem.id)
        previousItemView.after(itemView.el)
      else
        @$(".panel-items").prepend(itemView.el)

      # remove class from last item
      @$(".panel-items li.last").removeClass('last')

      # attach it to this latest last item
      @$(".panel-items li:last").addClass('last')

  showMoreItems: (e) ->
    e.preventDefault()

    $(e.currentTarget).html('Please wait ...')
    @collection.fetch
      add: true
      success: (collection, response, options) =>
        $(e.currentTarget).html('Show more')

      error: (collection, xhr, options) =>
        @options.addingMechanism = 'prepend'

  togglePanelExpand: (type) ->
    if type == 'expand'
      $(@el).removeClass('span4').addClass('span8')
      @$('.collapse-panel').removeClass('hidden')
      $("#dashboard #archived").addClass('hidden')
    else
      $(@el).removeClass('span8').addClass('span4')
      $("#dashboard #archived").removeClass('hidden')

  collapsePanel: (e, switchTab=true) ->
    e.preventDefault()

    # collapse all comments
    @$('.tab-pane-comments li').removeClass('shown')
    @$('.tab-pane-comments li .subcomment').addClass('hidden')
    @$('.tab-pane-comments li .meta .collapse').addClass('hidden')
    @$('.tab-pane-comments li .meta .expand').removeClass('hidden')

    # collapse panel
    $(@el).removeClass('span8').addClass('span4')
    @$('h3 .collapse-panel').addClass('hidden')

    # switch all tabs to item info
    if switchTab
      @$('.nav-tabs .item-info-tab').tab 'show'

    # show the archived panel
    $("#dashboard #archived").removeClass('hidden')

  itemTabSwitch: (e) ->
    # if there are no active comments tab, collapse panel
    if @$('.nav-tabs .active .comments-tab').length == 0
      @collapsePanel(e, false)

  _normalizeItem: (item) ->
    # does 3 things:
    # 1. move images field outside attributes and delete the images attribute
    # 2. create new ItemTags for raw json tags and override the tags attribute
    if item.get('images')?
      item.images.reset(item.get('images'))
      delete item.attributes.images

    # only convert to ItemTags if its not yet ItemTags
    tags = item.get('tags')
    if not (tags instanceof TradeOrSale.ItemTags)
      itemTags = new TradeOrSale.ItemTags()
      itemTags.reset(tags)
      item.set('tags', itemTags)

    return item


class ThumbImageView extends Backbone.View
  template: '#image-thumb-template'
  className: 'thumb'
  tagName: 'li'
  events: {
    'click .preview': 'toggleImagePreview'
    'click .delete': 'deleteImage'
  }
  isEditingImages: false

  initialize: ->
    @template = Handlebars.compile($(@template).html())
    @render()
    @model.bind 'destroy', @destroyThumb, @

    # whenever the parent item's image editing state changes,
    # update our own option.
    Dashboard.vent.on 'ToggleImageEditing:' + @options.itemId, @updateImageEditingOption, @

  render: ->
    image = @model.toJSON()
    image['isEditingImages'] = @options.isEditingImages
    $(@el).html(@template(image))
    $(@el).attr('id', 'item-thumbnail-' + @model.id)

  destroyThumb: ->
    @undelegateEvents()
    @remove()
    @unbind()

  deleteImage: (e) ->
    e.preventDefault()
    if @options.isEditingImages
      @model.destroy()

  toggleImagePreview: (e) ->
    e.preventDefault()

    Dashboard.vent.trigger 'ToggleImagePreview:' + @options.itemId

    # do nothing if we're in editing state
    if @options.isEditingImages
      return

    targetLi = $(e.currentTarget).parent('li')
    targetImageId = targetLi.attr('id').split('-')[2]

    # remove currently active preview
    targetLi.siblings('.active').removeClass('active')
    mediumPreview = $(e.currentTarget).parents('ul').siblings('.medium-image')

    # remove exisiting preloader
    mediumPreview.find('.preloader').remove()

    # return the existing preview to its rightful place
    existingPreview = mediumPreview.find('img')
    existingImageId = null
    if existingPreview.length > 0
      existingPreview.addClass('hidden')
      existingImageId = existingPreview.attr('id').split('-')[2]

      existingLi = $(e.currentTarget).parents('ul').find('#item-thumbnail-' + existingImageId)
      existingLi.find('.preview').append(existingPreview)

      # clear preview
      mediumPreview.html('').addClass('hidden')

    # if medium image is not yet loaded
    if @$('.medium').length == 0

      mediumPreview.append(TradeOrSale.imagePreloader)

      mediumImage = document.createElement('img')
      mediumImage.className = 'medium hidden'
      mediumImage.setAttribute('id', 'item-image-' + @model.id)
      $(mediumImage).bind 'load', ->
        mediumPreview.find('.preloader').remove()
        mediumPreview.append(mediumImage)
        $(mediumImage).removeClass('hidden')

      targetLi.addClass('active')
      mediumImage.src = $(e.currentTarget).attr('href')

    # if its already loaded and just hidden, show it
    else if $(e.target).siblings('.medium').hasClass('hidden')
      if existingImageId != targetImageId
        mediumImage = $(e.target).siblings('.medium')
        $(e.currentTarget).parent('.thumb').addClass('active')
        mediumPreview.append(mediumImage)
      else
        existingLi.removeClass('active')
        mediumPreview.addClass('hidden')
        return

    # show whatever medium image was loaded
    mediumPreview.find('img').removeClass('hidden')
    mediumPreview.removeClass('hidden')

  updateImageEditingOption: (isEditingImages) ->
    @options.isEditingImages = isEditingImages

    if isEditingImages
      @$('.delete').removeClass('hidden')
      $(@el).removeClass('active')
    else
      @$('.delete').addClass('hidden')


class DraftsItemView extends Backbone.View
  template: '#drafts-panel-item-template'
  tagName: 'li'
  events:
    'click .name .item-name': 'toggleItem'

    # name field events
    'mouseover li .name': 'toggleNameEditLink'
    'mouseout li .name': 'toggleNameEditLink'
    'click li .name .edit-field-link': 'toggleNameEditForm'
    'click li .name .edit-field-form .cancel': 'toggleNameEditForm'
    'click li .name .edit-field-form .edit-field-btn': 'updateItemName'

    # item info tab pane
    'mouseover .tab-pane-iteminfo .field': 'toggleFieldEditLink'
    'mouseout .tab-pane-iteminfo .field': 'toggleFieldEditLink'
    'click .tab-pane-iteminfo .field .edit-field-link': 'showFieldEditForm'
    'click .tab-pane-iteminfo .field .actions .cancel': 'hideFieldEditForm'
    'click .tab-pane-iteminfo .field .actions .edit-field-btn': 'updateField'
    'click .tab-pane-iteminfo > .actions .delete-item': 'deleteItem'
    'click .tab-pane-iteminfo .add-reason-link': 'showAddReasonForm'
    'click .field.type .btn': 'toggleItemType'
    'keypress .edit-field-form .edit-field': 'enterPressed'
    'click .tab-pane-iteminfo .add-tags-link': 'showAddTagsForm'

    # images tab pane
    'click .tab-pane-images .actions a.edit-images': 'editImages'
    'click .tab-pane-images .actions a.cancel-editing': 'cancelEditImages'
    'click .tab-pane-images .meta .upload': 'uploadMoreImages'
    'click .tab-pane-images .drop-zone li': 'removeDroppedImageThumb'

  isEditingImages: false
  switchingTypeState: null

  attributes: ->
    attrs =
      class: (if @options.isLast then 'last' else '')
      id: 'item-' + @model.id
    return attrs

  initialize: ->
    @template = Handlebars.compile($(@template).html())
    @render()

    # bind item events
    @model.bind 'remove', @destroyItem, @
    @model.bind 'destroy', @destroyItem, @
    @model.bind 'change:name', @nameChanged, @
    @model.bind 'change:trade_with', @tradeWithChanged, @
    @model.bind 'change:price', @priceChanged, @
    @model.bind 'change:quantity', @quantityChanged, @
    @model.bind 'change:description', @descriptionChanged, @
    @model.bind 'change:reason', @reasonChanged, @
    Dashboard.vent.on 'ToggleImagePreview:' + @model.id, @clearImagePreview, @

  render: ->
    item = @model.toJSON()
    item.isTrade = if @model.get('type') == 'TRADE' then true else false
    item.hasTags = if @model.get('tags').size() == 0 then false else true
    item.tags = @model.get('tags').toJSON()
    $(@el).html(@template(item))

    # copy all existing tags to pending tags, when adding and removing
    # tags use pending tags until submission wherein we override the actual tags.
    @model.pendingTags.reset()
    @model.get('tags').each (tag) =>
      @model.pendingTags.push tag

    @$("#field-tags-" + @model.id).tagit
      singleField: true
      allowSpaces: true
      removeConfirmation: true
      caseSensitive: false
      availableTags: tagNames.pluck('name')
      beforeTagAdded: (e, ui) =>
        if ui.duringInitialization
          return

        # if tag about to be add doesn't exist in availableTags, reject it for now.
        tagName = $(ui.tag).find('.tagit-label').text()
        tag = tagNames.findByName(tagName)

        if not tag
          # manually attach tags error
          @model.errors.tags = TradeOrSale.errorMsgs['createTagPermissionDenied']
          @displayError('tags')
          return false

        @model.pendingTags.push(tag)

        # remove error marker
        fieldParent = @$('.field.tags')
        fieldParent.find('.error').remove()
        fieldParent.removeClass('error')

      afterTagRemoved: (e, ui) =>
        tagName = $(ui.tag).find('.tagit-label').text()
        tag = @model.pendingTags.findByName(tagName)
        if tag
          @model.pendingTags.remove(tag)

    # hide the close button
    @$("#field-tags-" + @model.id).siblings('.tagit').find('.tagit-close').addClass('hidden')
    @$("#field-tags-" + @model.id).siblings('.tagit').addClass('readonly')

    # render each image
    @model.images.each (image, i) =>
      imageView = new ThumbImageView
        model: image
        itemId: @model.id
      @$('.tab-pane-images > ul').append(imageView.el)

    @model.images.bind 'add', @addImage, @

  ## model changed

  nameChanged: ->
    @$('.name .item-name').html(@model.escape('name'))

  tradeWithChanged: ->
    @$('.trade_with p').html(@model.escape('trade_with'))

  priceChanged: ->
    @$('.tab-pane-iteminfo .field.price p').html('PHP ' + @model.escape('price') + ' each')

  quantityChanged: ->
    @$('.tab-pane-iteminfo .field.quantity p').html(@model.escape('quantity') + ' in stock')

  descriptionChanged: ->
    description = @model.escape('description').replace /\n/g, '<br />'
    @$('.tab-pane-iteminfo .field.description p').html(description)

  reasonChanged: ->
    reason = @model.escape('reason').replace /\n/g, '<br />'
    @$('.tab-pane-iteminfo .field.reason p').html(reason)

  destroyItem: ->
    @undelegateEvents()
    @remove()
    @unbind()

  ## name field

  toggleItem: (e) ->
    e.preventDefault()
    if $(@el).hasClass('open')
      $(@el).removeClass('open')
    else
      $(@el).addClass('open')

  toggleNameEditLink: (e) ->
    e.preventDefault()

    # if edit form is shown, don't toggle edit link
    if @$('.name .item-name').hasClass('hidden')
      return

    if $(@el).hasClass('open') and e.type == 'mouseover'
      @$('.name .edit-field-link').removeClass('hidden')
    else if e.type == 'mouseout'
      @$('.name .edit-field-link').addClass('hidden')

  toggleNameEditForm: (e) ->
    e.preventDefault()

    # clear existing errors
    @$('.name').removeClass('error')
    @$('.name .edit-field-form .error').remove()

    # reset the edit field's value
    @$('.name .edit-field-form .edit-field').val(@model.escape('name'))

    if @$('.name .edit-field-form').hasClass('hidden')
      @$('.name .edit-field-form').removeClass('hidden')
      @$('.name .item-name, .name .edit-field-link').addClass('hidden')
    else
      @$('.name .item-name, .name .edit-field-link').removeClass('hidden')
      @$('.name .edit-field-form').addClass('hidden')

  updateItemName: (e) ->
    e.preventDefault()

    input = @$('.name .edit-field-form .edit-field')
    @model.set 'name', input.val(), {validateAll: false}

    # clear existing errors
    @$('.name').removeClass('error')
    @$('.name .edit-field-form .error').remove()

    if not _.isEmpty(@model.errors) and 'name' of @model.errors
      @$('.name').addClass('error')
      errorMsg = document.createElement 'div'
      errorMsg.className = 'error'
      errorMsg.innerHTML = @model.errors['name']
      @$('.name .edit-field-form').find('.error-marker').after errorMsg
      return

    @model.save()
    @toggleNameEditForm(e)

  ## item info pane

  toggleFieldEditLink: (e) ->
    e.preventDefault()

    # don't toggle edit link if the edit form is shown
    if not $(e.currentTarget).children('.edit-field-form').hasClass('hidden')
      return

    editFieldLink = $(e.currentTarget).find('.edit-field-link')
    if editFieldLink.hasClass('hidden') and e.type == 'mouseover'
      editFieldLink.removeClass('hidden')
    else if e.type == 'mouseout'
      editFieldLink.addClass('hidden')

  showFieldEditForm: (e) ->
    e.preventDefault()

    # only hide the display of field when this is not tags field,
    # because tags field uses the same display for editing.
    if not $(e.currentTarget).parents('.field').hasClass('tags')
      $(e.currentTarget).parent('h4').siblings('p').addClass('hidden')
    else
      pTag = $(e.currentTarget).parent('h4').siblings('p')
      pTag.find('.tagit').removeClass('readonly')
      pTag.find('.tagit .tagit-close').removeClass('hidden')
      pTag.find('.tagit-new input').focus()

      # populate pendingTags with whatever is in tags
      @model.pendingTags.reset()
      @model.get('tags').each (tag) =>
        @model.pendingTags.push tag

    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).parent('h4').siblings('.edit-field-form').removeClass('hidden')

  hideFieldEditForm: (e) ->
    e.preventDefault()

    fieldParent = $(e.currentTarget).parents('.field')

    # if we're cancelling edit form of tags
    if fieldParent.hasClass('tags')
      fieldParent.find('p').removeClass('hidden')
      fieldParent.find('p .tagit').addClass('readonly')

      fieldParent.find('.tagit-new input').val('')
      existingTags = @model.get('tags').pluck('name')
      pendingTags = @model.pendingTags.pluck('name')

      # if tag list is empty, hide the form and show add-tags link
      if @model.get('tags').size() == 0
        fieldParent.addClass('hidden')
        fieldParent.siblings('.add-tags-link').removeClass('hidden')
        @$("#field-tags-" + @model.id).tagit("removeAll")

      else
        # intersect the pending and existing tags and remove the intersection        
        diffTags = _.difference(pendingTags, existingTags)

        _.each diffTags, (tagName) =>
          @$("#field-tags-" + @model.id).tagit("removeTagByName", tagName, false)

        _.each existingTags, (tagName) =>
           @$("#field-tags-" + @model.id).tagit("createTag", tagName)

      fieldParent.find('p .tagit .tagit-close').addClass('hidden')

      # clear pending tags
      @model.pendingTags.reset()

    else
      # set value of the edit-field to the whatever is in the model
      editField = fieldParent.find('.edit-field')
      fieldName = editField.attr('id').split('-')[1]

      # use get so not the escaped value gets shown in edit field
      editField.val @model.get fieldName

    # remove error marker
    fieldParent.removeClass('error')
    fieldParent.find('.error').remove()

    # if we're hiding reason field and its empty,
    # show 'Add reason' link and hide the form.
    if fieldName == 'reason' and @model.get(fieldName) == ''
      fieldParent.siblings('.add-reason-link').removeClass('hidden')
      fieldParent.addClass('hidden')
      return

    # if user is switching to SALE but clicked cancel instead of entering price,
    # emulate clicking TRADE which hides the price edit form.
    if @switchingTypeState == 'SALE'
      @$('.field.type .btn.trade').click()
      @switchingTypeState = null  # clear switching state
      return

    fieldParent.find('.edit-field-link').removeClass('hidden')
    $(e.currentTarget).parents('.edit-field-form').addClass('hidden')
    $(e.currentTarget).parents('.edit-field-form').siblings('p').removeClass('hidden')   

  updateField: (e) ->
    e.preventDefault()

    fieldParent = $(e.currentTarget).parents('.field')

    if not fieldParent.hasClass('tags')
      input = $(e.currentTarget).parents('.edit-field-form').find('.edit-field')
      fieldName = input.attr('id').split('-')[1]

      @model.set fieldName, input.val(), {validateAll: false}
    else

      # copy pending tags to new ItemTags
      newItemTags = new TradeOrSale.ItemTags()
      @model.pendingTags.each (tag) =>
        newItemTags.push(tag)

      # reset pending tags and override the old tags
      @model.pendingTags.reset()
      @model.set 'tags', newItemTags, {validateAll: false}

    # if there are errors after set, display them first
    if not _.isEmpty(@model.errors)
      _.each @model.attributes, (__, field) =>
        @displayError field
      return

    # if switching to SALE state, meaning user is updating the price.
    # after setting the price we just set the type to SALE
    # so it gets included in the save.
    if @switchingTypeState == 'SALE'
      @model.set 'type', 'SALE', {validateAll: false}
      @switchingTypeState = null

    @model.save null, success: (model, response, options) =>
      @model = model

      # convert the returned json of tags to ItemTags
      itemTags = new TradeOrSale.ItemTags()
      itemTags.reset(@model.get('tags'))
      @model.set('tags', itemTags)

    @hideFieldEditForm(e)

  deleteItem: (e) ->
    e.preventDefault()
    @model.collection.remove(@model)
    @model.destroy()

  showAddReasonForm: (e) ->
    e.preventDefault()
    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.add-reason').removeClass('hidden')
    $(e.currentTarget).siblings('.add-reason').find('textarea').focus()

  toggleItemType: (e) ->
    e.preventDefault()

    newType = $(e.currentTarget).html().toUpperCase()
    @switchingTypeState = newType

    if newType == 'SALE' and @model.get('type') == 'TRADE'  # show price edit form
      @$('.field.price').removeClass('hidden')
      @$('.field.price .edit-field-link').click()
      @$('.field.price .edit-field').focus()

      # hide trade_with field
      @$('.field.trade_with').addClass('hidden')

    else if newType == 'TRADE' and @model.get('type') == 'SALE'
      # if there's a price element, hide it
      @$('.field.price').addClass('hidden')
      @$('.field.price .edit-field').val('')

      # show trade_with field
      @$('.field.trade_with').removeClass('hidden')

      # switch type field to TRADE and clear price immediately,
      # then save to backend.
      @model.set type: newType
      @model.set price: ""
      @model.save()

      @switchingTypeState = null

    # from TRADE user switched to SALE then back to TRADE
    else if newType == 'TRADE' and @model.get('type') == 'TRADE'
      @$('.field.price').addClass('hidden')
      @$('.field.price .edit-field').val('')

      # show trade_with field
      @$('.field.trade_with').removeClass('hidden')

      # remove error marker
      @$('.field.price').removeClass('error')
      @$('.field.price .edit-field-form .error').remove()

  enterPressed: (e) ->
    # allow submitting if enter was pressed only if the field is not
    # a textarea, since in textarea we can have multiple line.
    if e.keyCode == 13 and e.target.tagName != 'TEXTAREA'
      $(e.currentTarget).parents('.edit-field-form').find('.actions .edit-field-btn').click()

  showAddTagsForm: (e) ->
    e.preventDefault()
    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.field.tags').removeClass('hidden')

    $(e.currentTarget).siblings('.field.tags').find('.edit-field-form').removeClass('hidden')
    pTag = $(e.currentTarget).siblings('.field.tags').find('p')
    pTag.find('.tagit').removeClass('readonly')
    pTag.find('.tagit .tagit-close').removeClass('hidden')
    pTag.find('.tagit-new input').focus()

  ## item images pane

  editImages: (e) ->
    e.preventDefault()
    @clearImagePreview()

    # if there's an existing preview when editing,
    # return it first to its proper place.
    existingPreview = @$(".medium-image img")
    if existingPreview.length > 0
      existingPreview.addClass('hidden')
      existingImageId = existingPreview.attr('id').split('-')[2]

      existingLi = $(e.currentTarget).parents('ul').find('#item-thumbnail-' + existingImageId)
      existingLi.find('.preview').append(existingPreview)
      @$(".medium-image").html('').addClass('hidden')

    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.cancel-editing').removeClass('hidden')
    @$(".drop-zone .help").show()
    @$('.drop-zone').show()
    @$(".meta").show()
    @initFileDrop()

    # trigger image editing event so thumbnails can update their option
    @isEditingImages = true
    Dashboard.vent.trigger 'ToggleImageEditing:' + @model.id, @isEditingImages

  cancelEditImages: (e) ->
    e.preventDefault()
    @$('.drop-zone').hide()
    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.edit-images').removeClass('hidden')
    @$(".meta").hide()
    @$('.drop-zone').off()
    @resetDropZone()

    # trigger image editing event so thumbnails can update their option
    @isEditingImages = false
    Dashboard.vent.trigger 'ToggleImageEditing:' + @model.id, @isEditingImages

  uploadMoreImages: (e) ->
    e.preventDefault()
    if _.size(@uploadHandlers) > 0
      # upload each image
      _.each @uploadHandlers, (handlerInfo, i) =>
        handlerInfo.handler(i)

  removeDroppedImageThumb: (e) ->
    e.preventDefault()

    index = $(e.currentTarget).attr('class').split('-')[1]
    delete @uploadHandlers[index]

    # shift indexes
    indexToShift = _.filter _.keys(@uploadHandlers), (subIndex) ->
      return if subIndex > index then true else false
    indexToShift.sort()
    for subIndex in indexToShift
      handlerInfo = @uploadHandlers[subIndex]
      delete @uploadHandlers[subIndex]
      @uploadHandlers[subIndex - 1] = handlerInfo

    $(e.currentTarget).remove()
    if @$(".tab-pane-images .drop-zone li").length == 0
      @resetDropZone()
    @fileDrop.removeElement(index)

  addImage: (image) ->
    imageView = new ThumbImageView
      model: image
      itemId: @model.id
      isEditingImages: @isEditingImages

    @$('.tab-pane-images > ul').append(imageView.el)

  ## misc

  resetDropZone: ->
    @fileDrop.files = []
    @fileDrop.files_count = 0
    @uploadHandlers = []
    @failedUploadCounter = 0
    @$(".tab-pane-images .drop-zone li").remove()
    @$(".drop-zone ul").remove()
    @$(".drop-zone .help").show()
    @$(".tab-pane-images .meta .upload").attr('disabled', 'disabled')
    @$(".meta .upload-stats").html('0%')

  clearImagePreview: =>
    if @$('.tab-pane-images .medium-thumb').length > 0
      li = @$('.tab-pane-images .medium-thumb')
      position = li.attr('position')

      li.find('.medium').addClass('hidden')
      li.find('.small').removeClass('hidden')
      li.removeClass('medium-thumb')

      # don't bother swapping if the same element is occupying that position
      occupant = li.parents('ul').find('> li').eq(position)
      if not occupant.is(li)
        occupant.before(li)

  initFileDrop: ->
    @uploadHandlers = {}
    @failedUploadCounter = 0
    @fileDrop = @$('.drop-zone').filedrop
      url: =>
        return '/' + TradeOrSale.apiVersion + '/users/' + currentUser.id + '/items/' + @model.id + '/images'
      paramname: 'image'
      data:
        item_id: @model.id
      error: (err, file) =>
        switch err
          when 'BrowserNotSupported'
            console.log "Browser doesn't support html5"
          when 'TooManyFiles'
            console.log "Uploading too many files"
          when 'FileTooLarge'
            console.log "Uploading too large file"
          when 'FileTypeNotAllowed'
            @resetDropZone()
            console.log @fileDrop
            console.log "Invalid file type"
      allowedfiletypes: ['image/jpeg', 'image/png']
      maxfiles: 24
      maxfilesize: 10  # 10mb
      drop: =>
        if @$(".drop-zone ul").length == 0
          ulTag = document.createElement('ul')
          @$(".drop-zone .help").hide()
          @$(".drop-zone").append(ulTag)

        @$(".tab-pane-images .meta .upload").removeAttr("disabled")
      uploadFinished: (i, file, response, time) =>
        if response.status == 'FAILED'
          @$(".drop-zone .image-" + i).remove()
          @failedUploadCounter += 1
        else
          # move newly uploaded image's thumbnails
          image = new TradeOrSale.ItemImage
            id: response.sizes.id
            original: response.sizes.original
            medium: response.sizes.medium
            small:  response.sizes.small

          @model.images.add image, at: (@model.images.size() - 1)

      progressUpdated: (i, file, progress) =>
        newFilter = 'grayscale(' + (100 - progress) + '%)'
        @$(".drop-zone .image-" + i + " img").css('filter', newFilter)
        @$(".drop-zone .image-" + i + " img").css('-webkit-filter', newFilter)
        @$(".drop-zone .image-" + i + " img").css('-moz-filter', newFilter)
      globalProgressUpdated: (progress) =>
        @$(".meta .upload-stats").html(progress + '%')
      beforeEach: (i, file) =>
        liTag = document.createElement('li')
        liTag.className = 'image-' + i
        imgTag = document.createElement('img')

        reader = new FileReader()
        reader.onload = (e) =>
          imgTag.src = e.target.result
          liTag.appendChild(imgTag)
          @$(".drop-zone ul").append(liTag)
        reader.readAsDataURL file
      beforeSend: (file, i, done) =>
        @uploadHandlers[i] = {handler: done, file: file}
      afterAll: =>
        @resetDropZone()
      removeElement: (index) =>
        nextIndex = index + 1
        remainingLi = @$(".tab-pane-images .drop-zone li").length

        # shift classes of elements
        for subIndex in [nextIndex..remainingLi]
          newIndex = subIndex - 1
          @$('.tab-pane-images .drop-zone li.image-' + subIndex).attr('class', 'image-' + newIndex)

      prepareDrop: =>
        # cleanup any existing dropped items first
        if @$(".drop-zone ul li").length > 0
          @$(".drop-zone ul li").remove()  # remove existing
          for index in _.keys(@uploadHandlers)
            @fileDrop.removeElement(index)
          @uploadHandlers = {}

  displayError: (field) ->
    fieldEl = @.$("#field-#{field}-#{@model.id}")

    attachError = (msg) ->
      fieldEl.parents(".field").addClass('error')
      errorMsg = document.createElement 'div'
      errorMsg.className = 'error'
      errorMsg.innerHTML = msg
      return errorMsg

    # remove existing error
    if fieldEl.parents(".field").hasClass('error')
      fieldEl.parents(".field").removeClass('error')
      fieldEl.parents(".field").find('.error').remove()

    # check for tags' errors first
    if field == 'tags' and _.has(@model.errors, field)
      errorTag = attachError(@model.errors[field])
      fieldEl.parents('.error-marker').after errorTag
      delete @model.errors.tags  # manually remove tags error

    else if @model.errors? and field of @model.errors
      errorTag = attachError(@model.errors[field])
      fieldEl.parents('.edit-field-form').find('.error-marker').after errorTag


class OngoingItemView extends Backbone.View
  template: '#ongoing-panel-item-template'
  tagName: 'li'
  events:
    'click .name .item-name': 'toggleItem'

    # name field events
    'mouseover li .name': 'toggleNameEditLink'
    'mouseout li .name': 'toggleNameEditLink'
    'click li .name .edit-field-link': 'toggleNameEditForm'
    'click li .name .edit-field-form .cancel': 'toggleNameEditForm'
    'click li .name .edit-field-form .edit-field-btn': 'updateItemName'

    # item info tab pane
    'mouseover .tab-pane-iteminfo .field': 'toggleFieldEditLink'
    'mouseout .tab-pane-iteminfo .field': 'toggleFieldEditLink'
    'click .tab-pane-iteminfo .field .edit-field-link': 'showFieldEditForm'
    'click .tab-pane-iteminfo .field .actions .cancel': 'hideFieldEditForm'
    'click .tab-pane-iteminfo .field .actions .edit-field-btn': 'updateField'
    'click .tab-pane-iteminfo .add-reason-link': 'showAddReasonForm'
    'keypress .edit-field-form .edit-field': 'enterPressed'
    'click .tab-pane-iteminfo .add-tags-link': 'showAddTagsForm'

    # images tab pane
    'click .tab-pane-images .actions a.edit-images': 'editImages'
    'click .tab-pane-images .actions a.cancel-editing': 'cancelEditImages'
    'click .tab-pane-images .meta .upload': 'uploadMoreImages'
    'click .tab-pane-images .drop-zone li': 'removeDroppedImageThumb'

    # tabs
    'click .nav-tabs .comments-tab': 'switchToCommentsTab'

  isEditingImages: false

  attributes: ->
    attrs =
      class: (if @options.isLast then 'last' else '')
      id: 'item-' + @model.id
    return attrs

  initialize: ->
    @template = Handlebars.compile($(@template).html())
    @render()

    # bind item events
    @model.bind 'remove', @destroyItem, @
    @model.bind 'destroy', @destroyItem, @
    @model.bind 'change:name', @nameChanged, @
    @model.bind 'change:trade_with', @tradeWithChanged, @
    @model.bind 'change:price', @priceChanged, @
    @model.bind 'change:quantity', @quantityChanged, @
    @model.bind 'change:description', @descriptionChanged, @
    @model.bind 'change:reason', @reasonChanged, @

    Dashboard.vent.on 'ToggleImagePreview:' + @model.id, @clearImagePreview, @

  render: ->
    item = @model.toJSON()
    item.isTrade = if @model.get('type') == 'TRADE' then true else false
    item.hasTags = if @model.get('tags').size() == 0 then false else true
    item.tags = @model.get('tags').toJSON()
    $(@el).html(@template(item))

    # copy all existing tags to pending tags, when adding and removing
    # tags use pending tags until submission wherein we override the actual tags.
    @model.pendingTags.reset()
    @model.get('tags').each (tag) =>
      @model.pendingTags.push tag

    @$("#field-tags-" + @model.id).tagit
      singleField: true
      allowSpaces: true
      removeConfirmation: true
      caseSensitive: false
      availableTags: tagNames.pluck('name')
      beforeTagAdded: (e, ui) =>
        if ui.duringInitialization
          return

        # if tag about to be add doesn't exist in availableTags, reject it for now.
        tagName = $(ui.tag).find('.tagit-label').text()
        tag = tagNames.findByName(tagName)

        if not tag
          # manually attach tags error
          @model.errors.tags = TradeOrSale.errorMsgs['createTagPermissionDenied']
          @displayError('tags')
          return false

        @model.pendingTags.push(tag)

        # remove error marker
        fieldParent = @$('.field.tags')
        fieldParent.find('.error').remove()
        fieldParent.removeClass('error')

      afterTagRemoved: (e, ui) =>
        tagName = $(ui.tag).find('.tagit-label').text()
        tag = @model.pendingTags.findByName(tagName)
        if tag
          @model.pendingTags.remove(tag)

    # hide the close button
    @$("#field-tags-" + @model.id).siblings('.tagit').find('.tagit-close').addClass('hidden')
    @$("#field-tags-" + @model.id).siblings('.tagit').addClass('readonly')

    # render each image
    @model.images.each (image, i) =>
      imageView = new ThumbImageView
        model: image
        itemId: @model.id
      @$('.tab-pane-images > ul').append(imageView.el)
    @model.images.bind 'add', @addImage, @

    # broadcast to panel when a tab switch happens
    @$('.nav-tabs a[data-toggle="tab"]').on 'shown', (e) ->
      Dashboard.vent.trigger 'ItemTabSwitch:Ongoing', e

  ## model changed

  nameChanged: ->
    @$('.name .item-name').html(@model.escape('name'))

  tradeWithChanged: ->
    @$('.trade_with p').html(@model.escape('trade_with'))

  priceChanged: ->
    @$('.tab-pane-iteminfo .field.price p').html('PHP ' + @model.escape('price') + ' each')

  quantityChanged: ->
    @$('.tab-pane-iteminfo .field.quantity p').html(@model.escape('quantity') + ' in stock')

  descriptionChanged: ->
    description = @model.escape('description').replace /\n/g, '<br />'
    @$('.tab-pane-iteminfo .field.description p').html(description)

  reasonChanged: ->
    reason = @model.escape('reason').replace /\n/g, '<br />'
    @$('.tab-pane-iteminfo .field.reason p').html(reason)

  destroyItem: ->
    @undelegateEvents()
    @remove()
    @unbind()

  ## name field

  toggleItem: (e) ->
    e.preventDefault()
    if $(@el).hasClass('open')
      $(@el).removeClass('open')
    else
      $(@el).addClass('open')

  toggleNameEditLink: (e) ->
    e.preventDefault()

    # if edit form is shown, don't toggle edit link
    if @$('.name .item-name').hasClass('hidden')
      return

    if $(@el).hasClass('open') and e.type == 'mouseover'
      @$('.name .edit-field-link').removeClass('hidden')
    else if e.type == 'mouseout'
      @$('.name .edit-field-link').addClass('hidden')

  toggleNameEditForm: (e) ->
    e.preventDefault()

    # clear existing errors
    @$('.name').removeClass('error')
    @$('.name .edit-field-form .error').remove()

    # reset the edit field's value
    @$('.name .edit-field-form .edit-field').val(@model.escape('name'))

    if @$('.name .edit-field-form').hasClass('hidden')
      @$('.name .edit-field-form').removeClass('hidden')
      @$('.name .item-name, .name .edit-field-link').addClass('hidden')
    else
      @$('.name .item-name, .name .edit-field-link').removeClass('hidden')
      @$('.name .edit-field-form').addClass('hidden')

  updateItemName: (e) ->
    e.preventDefault()

    input = @$('.name .edit-field-form .edit-field')
    @model.set 'name', input.val(), {validateAll: false}

    # clear existing errors
    @$('.name').removeClass('error')
    @$('.name .edit-field-form .error').remove()

    if not _.isEmpty(@model.errors) and 'name' of @model.errors
      @$('.name').addClass('error')
      errorMsg = document.createElement 'div'
      errorMsg.className = 'error'
      errorMsg.innerHTML = @model.errors['name']
      @$('.name .edit-field-form').find('.error-marker').after errorMsg
      return

    @model.save()
    @toggleNameEditForm(e)

  ## item info pane

  toggleFieldEditLink: (e) ->
    e.preventDefault()

    # don't toggle edit link if the edit form is shown
    if not $(e.currentTarget).children('.edit-field-form').hasClass('hidden')
      return

    editFieldLink = $(e.currentTarget).find('.edit-field-link')
    if editFieldLink.hasClass('hidden') and e.type == 'mouseover'
      editFieldLink.removeClass('hidden')
    else if e.type == 'mouseout'
      editFieldLink.addClass('hidden')

  showFieldEditForm: (e) ->
    e.preventDefault()

    # only hide the display of field when this is not tags field,
    # because tags field uses the same display for editing.
    if not $(e.currentTarget).parents('.field').hasClass('tags')
      $(e.currentTarget).parent('h4').siblings('p').addClass('hidden')
    else
      pTag = $(e.currentTarget).parent('h4').siblings('p')
      pTag.find('.tagit').removeClass('readonly')
      pTag.find('.tagit .tagit-close').removeClass('hidden')
      pTag.find('.tagit-new input').focus()

      # populate pendingTags with whatever is in tags
      @model.pendingTags.reset()
      @model.get('tags').each (tag) =>
        @model.pendingTags.push tag

    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).parent('h4').siblings('.edit-field-form').removeClass('hidden')

  hideFieldEditForm: (e) ->
    e.preventDefault()

    fieldParent = $(e.currentTarget).parents('.field')

    # if we're cancelling edit form of tags
    if fieldParent.hasClass('tags')
      fieldParent.find('p').removeClass('hidden')
      fieldParent.find('p .tagit').addClass('readonly')

      fieldParent.find('.tagit-new input').val('')
      existingTags = @model.get('tags').pluck('name')
      pendingTags = @model.pendingTags.pluck('name')

      # if tag list is empty, hide the form and show add-tags link
      if @model.get('tags').size() == 0
        fieldParent.addClass('hidden')
        fieldParent.siblings('.add-tags-link').removeClass('hidden')
        @$("#field-tags-" + @model.id).tagit("removeAll")

      else
        # intersect the pending and existing tags and remove the intersection        
        diffTags = _.difference(pendingTags, existingTags)

        _.each diffTags, (tagName) =>
          @$("#field-tags-" + @model.id).tagit("removeTagByName", tagName, false)

        _.each existingTags, (tagName) =>
           @$("#field-tags-" + @model.id).tagit("createTag", tagName)

      fieldParent.find('p .tagit .tagit-close').addClass('hidden')

      # clear pending tags
      @model.pendingTags.reset()

    else
      # set value of the edit-field to the whatever is in the model
      editField = fieldParent.find('.edit-field')
      fieldName = editField.attr('id').split('-')[1]

      # use get so not the escaped value gets shown in edit field
      editField.val @model.get fieldName

    # remove error marker
    fieldParent.removeClass('error')
    fieldParent.find('.error').remove()

    # if we're hiding reason field and its empty,
    # show 'Add reason' link and hide the form.
    if fieldName == 'reason' and @model.get(fieldName) == ''
      fieldParent.siblings('.add-reason-link').removeClass('hidden')
      fieldParent.addClass('hidden')
      return

    fieldParent.find('.edit-field-link').removeClass('hidden')
    $(e.currentTarget).parents('.edit-field-form').addClass('hidden')
    $(e.currentTarget).parents('.edit-field-form').siblings('p').removeClass('hidden')   

  updateField: (e) ->
    e.preventDefault()

    fieldParent = $(e.currentTarget).parents('.field')

    if not fieldParent.hasClass('tags')
      input = $(e.currentTarget).parents('.edit-field-form').find('.edit-field')
      fieldName = input.attr('id').split('-')[1]

      @model.set fieldName, input.val(), {validateAll: false}
    else

      # copy pending tags to new ItemTags
      newItemTags = new TradeOrSale.ItemTags()
      @model.pendingTags.each (tag) =>
        newItemTags.push(tag)

      # reset pending tags and override the old tags
      @model.pendingTags.reset()
      @model.set 'tags', newItemTags, {validateAll: false}

    # if there are errors after set, display them first
    if not _.isEmpty(@model.errors)
      _.each @model.attributes, (__, field) =>
        @displayError field
      return

    @model.save()
    @hideFieldEditForm(e)

  showAddReasonForm: (e) ->
    e.preventDefault()
    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.add-reason').removeClass('hidden')
    $(e.currentTarget).siblings('.add-reason').find('textarea').focus()

  enterPressed: (e) ->
    # allow submitting if enter was pressed only if the field is not
    # a textarea, since in textarea we can have multiple line.
    if e.keyCode == 13 and e.target.tagName != 'TEXTAREA'
      $(e.currentTarget).parents('.edit-field-form').find('.actions .edit-field-btn').click()

  showAddTagsForm: (e) ->
    e.preventDefault()
    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.field.tags').removeClass('hidden')

    $(e.currentTarget).siblings('.field.tags').find('.edit-field-form').removeClass('hidden')
    pTag = $(e.currentTarget).siblings('.field.tags').find('p')
    pTag.find('.tagit').removeClass('readonly')
    pTag.find('.tagit .tagit-close').removeClass('hidden')
    pTag.find('.tagit-new input').focus()

  ## item images pane

  editImages: (e) ->
    e.preventDefault()
    @clearImagePreview()

    # if there's an existing preview when editing,
    # return it first to its proper place.
    existingPreview = @$(".medium-image img")
    if existingPreview.length > 0
      existingPreview.addClass('hidden')
      existingImageId = existingPreview.attr('id').split('-')[2]

      existingLi = $(e.currentTarget).parents('ul').find('#item-thumbnail-' + existingImageId)
      existingLi.find('.preview').append(existingPreview)
      @$(".medium-image").html('').addClass('hidden')

    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.cancel-editing').removeClass('hidden')
    @$(".drop-zone .help").show()
    @$('.drop-zone').show()
    @$(".meta").show()
    @initFileDrop()

    # trigger image editing event so thumbnails can update their option
    @isEditingImages = true
    Dashboard.vent.trigger 'ToggleImageEditing:' + @model.id, @isEditingImages

  cancelEditImages: (e) ->
    e.preventDefault()
    @$('.drop-zone').hide()
    $(e.currentTarget).addClass('hidden')
    $(e.currentTarget).siblings('.edit-images').removeClass('hidden')
    @$(".meta").hide()
    @$('.drop-zone').off()
    @resetDropZone()

    # trigger image editing event so thumbnails can update their option
    @isEditingImages = false
    Dashboard.vent.trigger 'ToggleImageEditing:' + @model.id, @isEditingImages

  uploadMoreImages: (e) ->
    e.preventDefault()
    if _.size(@uploadHandlers) > 0
      # upload each image
      _.each @uploadHandlers, (handlerInfo, i) =>
        handlerInfo.handler(i)

  removeDroppedImageThumb: (e) ->
    e.preventDefault()

    index = $(e.currentTarget).attr('class').split('-')[1]
    delete @uploadHandlers[index]

    # shift indexes
    indexToShift = _.filter _.keys(@uploadHandlers), (subIndex) ->
      return if subIndex > index then true else false
    indexToShift.sort()
    for subIndex in indexToShift
      handlerInfo = @uploadHandlers[subIndex]
      delete @uploadHandlers[subIndex]
      @uploadHandlers[subIndex - 1] = handlerInfo

    $(e.currentTarget).remove()
    if @$(".tab-pane-images .drop-zone li").length == 0
      @resetDropZone()
    @fileDrop.removeElement(index)

  addImage: (image) ->
    imageView = new ThumbImageView
      model: image
      itemId: @model.id
      isEditingImages: @isEditingImages

    @$('.tab-pane-images > ul').append(imageView.el)

  ## item tab navs

  switchToCommentsTab: (e) ->
    e.preventDefault()
    Dashboard.vent.trigger 'TogglePanelExpand:Ongoing', 'expand'

    # emit to backend to clear the comments:new:counter for this item
    itemSocket.emit 'comments_counter_clear', @model.id

  ## misc

  resetDropZone: ->
    @fileDrop.files = []
    @fileDrop.files_count = 0
    @uploadHandlers = []
    @failedUploadCounter = 0
    @$(".tab-pane-images .drop-zone li").remove()
    @$(".drop-zone ul").remove()
    @$(".drop-zone .help").show()
    @$(".tab-pane-images .meta .upload").attr('disabled', 'disabled')
    @$(".meta .upload-stats").html('0%')

  clearImagePreview: =>
    if @$('.tab-pane-images .medium-thumb').length > 0
      li = @$('.tab-pane-images .medium-thumb')
      position = li.attr('position')

      li.find('.medium').addClass('hidden')
      li.find('.small').removeClass('hidden')
      li.removeClass('medium-thumb')

      # don't bother swapping if the same element is occupying that position
      occupant = li.parents('ul').find('> li').eq(position)
      if not occupant.is(li)
        occupant.before(li)

  initFileDrop: ->
    @uploadHandlers = {}
    @failedUploadCounter = 0
    @fileDrop = @$('.drop-zone').filedrop
      url: =>
        return '/' + TradeOrSale.apiVersion + '/users/' + currentUser.id + '/items/' + @model.id + '/images'
      paramname: 'image'
      data:
        item_id: @model.id
      error: (err, file) =>
        switch err
          when 'BrowserNotSupported'
            console.log "Browser doesn't support html5"
          when 'TooManyFiles'
            console.log "Uploading too many files"
          when 'FileTooLarge'
            console.log "Uploading too large file"
          when 'FileTypeNotAllowed'
            @resetDropZone()
            console.log "Invalid file type"
      allowedfiletypes: ['image/jpeg', 'image/png']
      maxfiles: 24
      maxfilesize: 10  # 10mb
      drop: =>
        if @$(".drop-zone ul").length == 0
          ulTag = document.createElement('ul')
          @$(".drop-zone .help").hide()
          @$(".drop-zone").append(ulTag)

        @$(".tab-pane-images .meta .upload").removeAttr("disabled")
      uploadFinished: (i, file, response, time) =>
        if response.status == 'FAILED'
          @$(".drop-zone .image-" + i).remove()
          @failedUploadCounter += 1
        else
          # move newly uploaded image's thumbnails
          image = new TradeOrSale.ItemImage
            id: response.sizes.id
            original: response.sizes.original
            medium: response.sizes.medium
            small:  response.sizes.small

          @model.images.add image, at: (@model.images.size() - 1)

      progressUpdated: (i, file, progress) =>
        newFilter = 'grayscale(' + (100 - progress) + '%)'
        @$(".drop-zone .image-" + i + " img").css('filter', newFilter)
        @$(".drop-zone .image-" + i + " img").css('-webkit-filter', newFilter)
        @$(".drop-zone .image-" + i + " img").css('-moz-filter', newFilter)
      globalProgressUpdated: (progress) =>
        @$(".meta .upload-stats").html(progress + '%')
      beforeEach: (i, file) =>
        liTag = document.createElement('li')
        liTag.className = 'image-' + i
        imgTag = document.createElement('img')

        reader = new FileReader()
        reader.onload = (e) =>
          imgTag.src = e.target.result
          liTag.appendChild(imgTag)
          @$(".drop-zone ul").append(liTag)
        reader.readAsDataURL file
      beforeSend: (file, i, done) =>
        @uploadHandlers[i] = {handler: done, file: file}
      afterAll: =>
        @resetDropZone()
      removeElement: (index) =>
        nextIndex = index + 1
        remainingLi = @$(".tab-pane-images .drop-zone li").length

        # shift classes of elements
        for subIndex in [nextIndex..remainingLi]
          newIndex = subIndex - 1
          @$('.tab-pane-images .drop-zone li.image-' + subIndex).attr('class', 'image-' + newIndex)

      prepareDrop: =>
        # cleanup any existing dropped items first
        if @$(".drop-zone ul li").length > 0
          @$(".drop-zone ul li").remove()  # remove existing
          for index in _.keys(@uploadHandlers)
            @fileDrop.removeElement(index)
          @uploadHandlers = {}

  displayError: (field) ->
    fieldEl = @.$("#field-#{field}-#{@model.id}")

    attachError = (msg) ->
      fieldEl.parents(".field").addClass('error')
      errorMsg = document.createElement 'div'
      errorMsg.className = 'error'
      errorMsg.innerHTML = msg
      return errorMsg

    # remove existing error
    if fieldEl.parents(".field").hasClass('error')
      fieldEl.parents(".field").removeClass('error')
      fieldEl.parents(".field").find('.error').remove()

    # check for tags' errors first
    if field == 'tags' and _.has(@model.errors, field)
      errorTag = attachError(@model.errors[field])
      fieldEl.parents('.error-marker').after errorTag
      delete @model.errors.tags  # manually remove tags error

    else if @model.errors? and field of @model.errors
      errorTag = attachError(@model.errors[field])
      fieldEl.parents('.edit-field-form').find('.error-marker').after errorTag


class ArchivedItemView extends Backbone.View
  template: '#archived-panel-item-template'
  tagName: 'li'
  events:
    'click .name .item-name': 'toggleItem'
    'click .actions .clone-item': 'cloneItem'

  attributes: ->
    attrs =
      class: (if @options.isLast then 'last' else '')
      id: 'item-' + @model.id
    return attrs

  initialize: ->
    @template = Handlebars.compile($(@template).html())
    @render()

    @model.bind 'change:transaction_date', @transactionDateChanged, @

  render: ->
    item = @model.toJSON()
    item.isTrade = if @model.get('type') == 'TRADE' then true else false
    item.typePastense = if @model.get('type') == 'TRADE' then 'traded' else'sold'
    item.suffix = if @model.get('original_quantity') > 1 then 'items' else 'item'
    $(@el).html(@template(item))

  ## name field

  toggleItem: (e) ->
    e.preventDefault()
    if $(@el).hasClass('open')
      $(@el).removeClass('open')
    else
      $(@el).addClass('open')

  ## transaction date field

  transactionDateChanged: ->
    @$('.tab-pane .field.created span').html(@model.escape('transaction_date'))

  ## item info pane

  cloneItem: (e) ->
    e.preventDefault()
    url = @model.url() + '?action=clone'
    $.ajax
      type: "GET"
      url: url
      dataType: "json"
      success: (rawItem) ->
        clonedItem = new TradeOrSale.Item rawItem
        TradeOrSale.Dashboard.draftsPanel.collection.add clonedItem
        $('#item-' + clonedItem.id + ' .name .item-name').click()
        $('#item-' + clonedItem.id + ' .name .edit-field-link').click()
        $('#item-' + clonedItem.id + ' .name .edit-field-form .edit-field').focus().select()


Dashboard.showPanels = (draftItems, ongoingItems, archivedItems) ->
  if not Dashboard.draftsPanel?
    items = new PanelItems(null, {name: 'drafts'})
    items.reset(draftItems)
    Dashboard.draftsPanel = new DashboardPanelView
      el: $("#drafts")
      collection: items
      name: "Drafts"

  if not Dashboard.ongoingPanel?
    items = new PanelItems(null, {name: 'ongoing'})
    items.reset(ongoingItems)
    Dashboard.ongoingPanel = new DashboardPanelView
      el: $("#ongoing")
      collection: items
      name: "Ongoing"

  if not Dashboard.archivedPanel?
    items = new PanelItems(null, {name: 'archived'})
    items.reset(archivedItems)
    Dashboard.archivedPanel = new DashboardPanelView
      el: $("#archived")
      collection: items
      name: "Archived"

  getMovedItem = (originPanel, destinationPanel, itemId) ->
    item = originPanel.collection.get(itemId)
    originPanel.collection.remove(item)
    destinationPanel.collection.add(item)
    return item

  # sort between drafts and ongoing
  $("#drafts-panel, #ongoing-panel").sortable
    connectWith: "#drafts-panel, #ongoing-panel"
    placeholder: "item-drop-zone"
    dropOnEmpty: true
    handle: ".drag-handle"
    receive: (e, ui) ->
      originPanelId = $(ui.sender).attr('id')
      destinationPanelId = $(ui.item).parents('.panel-items').attr('id')
      itemId = $(ui.item).attr('id').split('-')[1]
      item = null
      originPanel = null
      destinationPanel = null
      if originPanelId == 'ongoing-panel'  # from ongoing panel
        originPanel = Dashboard.ongoingPanel
        destinationPanel = Dashboard.draftsPanel
        item = getMovedItem(originPanel, destinationPanel, itemId)
        item.save is_draft: true

  # sort between ongoing and archived
  $("#ongoing-panel, #archived-panel").sortable
    connectWith: "#drafts-panel, #archived-panel"
    placeholder: "item-drop-zone"
    dropOnEmpty: true
    handle: ".drag-handle"
    receive: (e, ui) ->
      originPanelId = $(ui.sender).attr('id')
      destinationPanelId = $(ui.item).parents('.panel-items').attr('id')
      itemId = $(ui.item).attr('id').split('-')[1]

      item = null
      originPanel = null
      destinationPanel = null
      switch originPanelId
        when 'drafts-panel'  # from drafts panel
          originPanel = Dashboard.draftsPanel
          destinationPanel = Dashboard.ongoingPanel
          item = getMovedItem(originPanel, destinationPanel, itemId)
          item.save is_draft: false

        when 'ongoing-panel'  # from ongoing panel
          originPanel = Dashboard.ongoingPanel

          if destinationPanelId == 'drafts-panel'
            destinationPanel = Dashboard.draftsPanel
          else  # moving to archived
            destinationPanel = Dashboard.archivedPanel

          item = getMovedItem(originPanel, destinationPanel, itemId)

          if destinationPanelId == 'drafts-panel'
            item.save is_draft: true
          else  # moving to archived
            item.save
              is_draft: false
              status: 'archived'

  $("#drafts-panel, #ongoing-panel, #archived-panel").disableSelection()

Dashboard.PanelItems = PanelItems
Dashboard.ThumbImageView = ThumbImageView

Dashboard.itemClasses =
  "Drafts": DraftsItemView
  "Ongoing": OngoingItemView
  "Archived": ArchivedItemView
TradeOrSale.Dashboard = Dashboard
