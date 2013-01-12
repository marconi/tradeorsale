<%namespace name="forms" file="../includes/forms.mako" import="render_field"/>

<script type="text/template" id="post-item-template">
  <div class="row">
    <div id="alert-wrapper" class="span12">
    </div>
    <div class="span7">
      <div class="left-pane">
        <form enctype="multipart/form-data" class="form-horizontal" method="post">
          <fieldset>
            <legend>${_('Post New Item')}</legend>
            <div class="fieldset-content">
              <input type="hidden" name="_csrf" value="${session.get_csrf_token()}">
              ${render_field(post_item_form.name)}
              ${render_field(post_item_form.quantity)}
              ${render_field(post_item_form.type)}
              ${render_field(post_item_form.price, placeholder='0.00', prepend='PHP')}
              ${render_field(post_item_form.trade_with, placeholder=_("What would you like to trade your item with?"))}
              ${render_field(post_item_form.description)}
              ${render_field(post_item_form.reason, placeholder=_('Optional reason for trading or selling this item'))}
              ${render_field(post_item_form.tags)}
              ${render_field(post_item_form.is_draft, value='', is_checkbox=True)}
              <div class="form-actions">
                <input id="submit-new-item" type="submit" class="btn" value="${_('Submit')}">
                <a id="close-new-item" href="#" class="btn">${_('Close')}</a>
              </div>
            </div>
          </fieldset>
        </form>
      </div>
    </div>
    <div class="span5">
      <div class="right-pane">
        <fieldset>
          <legend>${_('Images')} <span id="upload-stats">0%</span></legend>
          <div class="fieldset-content">
            <div class="images-masonry">
              <div class="drop-zone">${_("Drop your images here")}</div>
            </div>
            <div class="note">${_("Click thumbnail to remove image or")} <a href="#" class="clear-all">${_("clear all")}</a></div>
          </div>
        </fieldset>
      </div>
    </div>
  </div>
</script>
