root = (exports ? window)

TradeOrSale.postItemView = null

class PostItemView extends Backbone.View
  template: '#post-item-template'
  id: 'post-item'
  className: 'popup'
  events:
    'change #name': 'nameChanged'
    'change #type': 'typeChanged'
    'change #trade_with': 'tradeWithChanged'
    'change #price': 'priceChanged'
    'change #quantity': 'quantityChanged'
    'change #description': 'descriptionChanged'
    'change #reason': 'reasonChanged'
    'change #is_draft': 'isDraftChanged'
    'click #close-new-item': 'closePostItem'
    'click #submit-new-item': 'submitNewItem'
    'click .images-masonry li': 'removeImageThumb'
    'click .right-pane .note .clear-all': 'removeAllImagesThumb'

  initialize: ->
    $("#content").hide()  # hide whatever is the current content
    @template = Handlebars.compile($(@template).html())
    @render()  # render immediately so we can hide price field
    @$('#price').parents('.control-group').hide()
    @initFileDrop()

  render: ->
    $(@el).html(@template())

  initFileDrop: =>
    @uuid = UUID.create().hex
    @uploadHandlers = {}
    @failedUploadCounter = 0
    @fileDrop = @$('.drop-zone').filedrop
      url: =>
        return '/' + TradeOrSale.apiVersion + '/users/' + currentUser.id + '/items/' + @model.id + '/images'
      paramname: 'image'
      data:
        uuid: @uuid
      error: (err, file) =>
        switch err
          when 'BrowserNotSupported'
            console.log "Browser doesn't support html5"
          when 'TooManyFiles'
            console.log "Uploading too many files"
          when 'FileTooLarge'
            console.log "Uploading too large file"
          when 'FileTypeNotAllowed'
            @_resetRightPane()
            console.log "Invalid file type"
      allowedfiletypes: ['image/jpeg', 'image/png']
      maxfiles: 24
      maxfilesize: 10  # 10mb
      drop: =>
        ulTag = document.createElement('ul')
        @$(".right-pane .drop-zone").hide()
        @$(".right-pane .images-masonry").append(ulTag)
        @$(".right-pane .note").show()
      uploadFinished: (i, file, response, time) =>
        if response.status == 'FAILED'
          @$(".right-pane .image-" + i).remove()
          @failedUploadCounter += 1
        else
          # attach each uploaded images to the model
          image = new TradeOrSale.ItemImage
            id: response.sizes.id
            item_id: response.item_id
            original: response.sizes.original
            medium: response.sizes.medium
            small:  response.sizes.small
          @model.images.add(image)
      progressUpdated: (i, file, progress) =>
        newFilter = 'grayscale(' + (100 - progress) + '%)'
        @$(".right-pane .image-" + i + " img").css('filter', newFilter)
        @$(".right-pane .image-" + i + " img").css('-webkit-filter', newFilter)
        @$(".right-pane .image-" + i + " img").css('-moz-filter', newFilter)
      globalProgressUpdated: (progress) =>
        @$("#upload-stats").html(progress + '%')
      beforeEach: (i, file) =>
        liTag = document.createElement('li')
        liTag.className = 'image-' + i

        innerTag = document.createElement('div')
        innerTag.className = 'inner'
        imgTag = document.createElement('img')
        innerTag.appendChild(imgTag)

        reader = new FileReader()
        reader.onload = (e) =>
          imgTag.src = e.target.result
          @$(".right-pane ul").append(liTag)
        reader.readAsDataURL file

        liTag.appendChild(innerTag)
      beforeSend: (file, i, done) =>
        @uploadHandlers[i] = {handler: done, file: file}
      afterAll: =>
        @finishUpload()
      removeElement: (index) =>
        nextIndex = index + 1
        remainingLi = @$(".right-pane ul li").length

        # shift classes of elements
        for subIndex in [nextIndex..remainingLi]
          newIndex = subIndex - 1
          @$('.right-pane ul li.image-' + subIndex).attr('class', 'image-' + newIndex)

  removeImageThumb: (e) =>
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
    if @$(".right-pane ul li").length == 0
      @_resetRightPane()
    @fileDrop.removeElement(index)

  removeAllImagesThumb: (e) =>
    e.preventDefault()
    @_resetRightPane()

  displayError: (field) ->
    fieldEl = @.$("##{field}")

    @clearFieldError(field)

    # only display this field's error
    if @model.errors? and field of @model.errors
      fieldEl.parents('.control-group').addClass('error')
      errorMsg = document.createElement 'span'
      errorMsg.className = 'help-inline error'
      errorMsg.innerHTML = @model.errors[field]
      fieldEl.parents('.controls').append errorMsg

  nameChanged: (e) ->
    e.preventDefault()
    @model.set {name: $(e.currentTarget).val()}, {validateAll: false}
    @displayError 'name'

  typeChanged: (e) ->
    e.preventDefault()
    newType = $(e.currentTarget).val()
    if newType == 'SALE'
      @$('#trade_with').parents('.control-group').hide()
      @$('#price').parents('.control-group').show()
      @$('#price').focus()
    else
      @$('#trade_with').parents('.control-group').show()
      @$('#price').parents('.control-group').hide()
      @$('#price').val('').change()
    @model.set {type: newType}, {silent: true, validateAll: false}
    @displayError 'type'

  tradeWithChanged: (e) ->
    e.preventDefault()
    @model.set {trade_with: $(e.currentTarget).val()}, {validateAll: false}
    @displayError 'trade_with'

  priceChanged: (e) ->
    e.preventDefault()
    price = $(e.currentTarget).val()
    @model.set {price: price}, {validateAll: false}
    @displayError 'price'

  quantityChanged: (e) ->
    e.preventDefault()
    quantity = $(e.currentTarget).val()
    @model.set {quantity: quantity}, {validateAll: false}
    @displayError 'quantity'

  descriptionChanged: (e) ->
    e.preventDefault()
    @model.set {description: $(e.currentTarget).val()}, {validateAll: false}
    @displayError 'description'

  reasonChanged: (e) ->
    e.preventDefault()
    @model.set {reason: $(e.currentTarget).val()}, {validateAll: false}

  isDraftChanged: (e) ->
    e.preventDefault()
    if @$('#is_draft').attr('checked') != undefined
      @$('#is_draft').val('y')
    else
      @$('#is_draft').val('')

  submitNewItem: (e) ->
    e.preventDefault()

    @model.set {
      name: @$('#name').val(),
      type: @$('#type').val(),
      price: @$('#price').val(),
      quantity: @$('#quantity').val(),
      description: @$('#description').val(),
      reason: @$('#reason').val(),
      is_draft: @$('#is_draft').val()
    }, {validateAll: true}

    if not _.isEmpty(@model.errors)
      @_displayEachError()
      @_showAlert('error', "Something wen't wrong while trying to add your item")
    else
      @disableForm()

      # then followed by the actual item
      @model.save({uuid: @uuid}, {
        wait: true
        success: (model, response, options) =>
          # remove uuid from attributes
          delete model.attributes.uuid
          @model = model

          # convert the returned json of tags to ItemTags
          itemTags = new TradeOrSale.ItemTags()
          itemTags.reset(@model.get('tags'))
          @model.set('tags', itemTags)

          if _.size(@uploadHandlers) == 0
            @finishUpload()  # if no images, finish post item
          else
            # upload each image
            _.each @uploadHandlers, (handlerInfo, i) =>
              handlerInfo.handler(i)

        error: (model, xhr, options) =>
          model.errors = $.parseJSON(xhr.responseText)
          @model = model
          @_displayEachError()
          @enableForm()
          @_showAlert('error', "Something wen't wrong while trying to add your item")
      })

  closePostItem: (e) ->
    if e != undefined
      e.preventDefault()
    $(@el).hide()
    $("#content").show()
    $("#btn-post-item-parent").removeClass('active')

  openPostItem: ->
    $("#content").hide()
    $(@el).show()
    $("#btn-post-item-parent").addClass('active')

  disableForm: ->
    @$('form').find(':input:not(:disabled)').prop('disabled', true)
    $(@el).undelegate('.images-masonry li', 'click')
    @$('.images-masonry li').css('cursor', 'default')
    @$(".right-pane .note").hide()

  enableForm: ->
    @$('form').find(':input:disabled').prop('disabled', false)
    $(@el).delegate('.images-masonry li', 'click', @removeImageThumb)
    @$('.images-masonry li').css('cursor', 'pointer')
    if @$('.images-masonry li').length > 0
      @$(".right-pane .note").show()

  resetForm: ->
    @_resetLeftPane()
    @_resetRightPane()
    @failedUploadCounter = 0

  finishUpload: ->
    @_showAlert('success', 'Item has successfully been added')
    if @failedUploadCounter > 0
      plural = if @failedUploadCounter > 1 then 'images' else 'image'
      msg = "#{@failedUploadCounter} #{plural} failed to upload,
        make sure they have valid file name"
      @_showAlert('alert', msg, false)

    delete @model.attributes.images

    # add model to collection of drafts
    @model.addingMechanism = 'prepend'

    # if item is draft, add it to drafts panel
    if @model.get('is_draft') == 'y' and TradeOrSale.Dashboard.draftsPanel?
      TradeOrSale.Dashboard.draftsPanel.collection.add @model, at: 0

    # else add it to the ongoing panel
    else
      TradeOrSale.Dashboard.ongoingPanel.collection.add @model, at: 0      

    # reset the form and display success alert
    @enableForm()
    @resetForm()

  showTagError: (msg) ->
    fieldEl = @$("#tags")

    @clearFieldError('tags')

    fieldEl.parents('.control-group').addClass('error')
    errorMsg = document.createElement 'span'
    errorMsg.className = 'help-inline error'
    errorMsg.innerHTML = msg
    fieldEl.parents('.controls').append errorMsg

  clearFieldError: (field) ->
    fieldEl = @.$("##{field}")

    # remove existing error
    if fieldEl.parents(".control-group").find('.help-inline.error').length > 0
      fieldEl.parents('.control-group').removeClass('error')
      fieldEl.parents(".control-group").find('.help-inline.error').remove()

  _showAlert: (type, msg, destructive=true) ->
    @$("#alert-wrapper").hide()

    if destructive  # remove existing alerts if destructive
      @$("#alert-wrapper .alert").remove()

    alertTag = document.createElement('div')
    alertTag.className = 'alert'
    if type != 'alert'
      alertTag.className += ' alert-' + type

    closeBtn = document.createElement('button')
    closeBtn.className = 'close'
    closeBtn.innerHTML = '×'
    closeBtn.setAttribute('type', 'button')
    closeBtn.setAttribute('data-dismiss', 'alert')
    alertTag.innerHTML = msg
    alertTag.appendChild(closeBtn)
    @$("#alert-wrapper").append(alertTag).fadeIn()

  _resetLeftPane: ->
    @model = new TradeOrSale.Item()
    @$('#name').val('')
    @$('#type').val('TRADE').change()
    @$('#trade_with').val('')
    @$('#quantity').val('1')
    @$('#description').val('')
    @$('#reason').val('')
    @$('#is_draft').val('').removeAttr('checked')

    @$(".control-group.error").removeClass('error')
    @$(".help-inline.error").remove()
    @$("#tags").tagit("removeAll")

  _resetRightPane: ->
    @$(".right-pane ul").remove()
    @$(".right-pane .note").hide()
    @$(".right-pane .drop-zone").show()
    @$("#upload-stats").html('0%')

    @fileDrop.files = []
    @fileDrop.files_count = 0

    for index in _.keys(@uploadHandlers)
      @fileDrop.removeElement(index)

    @uploadHandlers = {}

  _displayEachError: ->
    if not _.isEmpty(@model.errors)
      _.each @model.attributes, (__, field) =>
        @displayError field


TradeOrSale.showPostItem = ->
  if TradeOrSale.postItemView?
    TradeOrSale.postItemView.openPostItem()
  else
    item = new TradeOrSale.Item()
    TradeOrSale.postItemView = new PostItemView model: item
    $("#btn-post-item-parent").addClass('active')
    $("#global-region").html(TradeOrSale.postItemView.el)
    $("#post-item #tags").tagit
      singleField: true
      allowSpaces: true
      removeConfirmation: true
      caseSensitive: false
      availableTags: tagNames.pluck('name')
      beforeTagAdded: (e, ui) ->
        if ui.duringInitialization
          return

        # if tag about to be add doesn't exist in availableTags, reject it for now.
        tagName = $(ui.tag).find('.tagit-label').text()
        tag = tagNames.findByName(tagName)

        if not tag
          TradeOrSale.postItemView.showTagError(TradeOrSale.errorMsgs['createTagPermissionDenied'])
          return false

        existingTags = TradeOrSale.postItemView.model.get('tags')
        existingTags.push(tag)
        TradeOrSale.postItemView.clearFieldError('tags')

      afterTagRemoved: (e, ui) ->
        tagName = $(ui.tag).find('.tagit-label').text()
        existingTags = TradeOrSale.postItemView.model.get('tags')

        tag = existingTags.findByName(tagName)
        if tag
          existingTags.remove(tag)


TradeOrSale.togglePostItem = (e) ->
  if TradeOrSale.postItemView? and $(TradeOrSale.postItemView.el).is(':visible')
    TradeOrSale.postItemView.closePostItem(e)
  else
    TradeOrSale.showPostItem()
