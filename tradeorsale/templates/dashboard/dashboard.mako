<%inherit file="../base.mako"/>  
<%namespace name="forms" file="../includes/forms.mako" import="render_field"/>

<%block name="header">
<script type="text/template" id="dashboard-panel-template">
  <div class="panel-inner">
    <h3>{{ name }} <a href="#" class="collapse-panel hidden">${_("Collapse")}</a></h3>
    <div class="panel-content">
      <p class="empty-panel">${_("No items yet")}</p>
      <ul id="{{ rawName }}-panel" class="panel-items">
      </ul>
    </div>
  </div>
  <div class="panel-footer">
    <div class="inner">
      <a href="#" class="show-more">${_("Show more")}</a>
    </div>
  </div>
</script>

<script type="text/template" id="image-thumb-template">
  <a href="#" class="delete {{^isEditingImages}}hidden{{/isEditingImages}}">x</a>
  <a id="{{ id }}" href="{{ medium }}" class="preview">
    <img src="{{ small }}" class="small" />
  </a>
</script>

<script type="text/template" id="drafts-panel-item-template">
  <div class="drag-handle">
    <div class="name">
      <a href="#" class="item-name">{{ name }}</a> <a href="#" class="edit-field-link hidden">${_("Edit")}</a>
      <div class="edit-field-form hidden">
        <input id="field-name-{{ id }}" type="text" value="{{ name }}" class="edit-field error-marker" />
        <div class="actions">
          <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
          <a href="#" class="cancel">${_("Cancel")}</a>
        </div>
      </div>
    </div>
  </div>

  <div class="item-content">
    <div class="tabbable tabs-below">
      <div class="tab-content">

        <div class="tab-pane tab-pane-iteminfo active" id="draft-item-info-{{ id }}">
          <div class="field type btn-group" data-toggle="buttons-radio">
            <button type="button" class="trade btn {{#isTrade}}active{{/isTrade}}">${_("Trade")}</button>
            <button type="button" class="sale btn {{^isTrade}}active{{/isTrade}}">${_("Sale")}</button>
          </div>

          <div class="field created">
            <h4>${_("Created")}</h4>
            <p>{{ created }}</p>
          </div>

          {{#if isTrade}}
          <div class="field trade_with">
            <h4>${_("Trade with")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{ trade_with }}</p>
            <div class="edit-field-form hidden fix-error">
              <input id="field-trade_with-{{ id }}" type="text" value="{{ trade_with }}" class="edit-field" />
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>

          <div class="field price hidden">
            <h4>${_("Price")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>PHP {{ price }} each</p>
            <div class="edit-field-form hidden fix-error">
              <div class="input-prepend">
                <span class="add-on">PHP</span>
                <input id="field-price-{{ id }}" type="text" value="{{ price }}" class="edit-field" />
              </div>
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{else}}
          <div class="field trade_with hidden">
            <h4>${_("Trade with")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{ trade_with }}</p>
            <div class="edit-field-form hidden fix-error">
              <input id="field-trade_with-{{ id }}" type="text" value="{{ trade_with }}" class="edit-field" />
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>

          <div class="field price">
            <h4>${_("Price")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>PHP {{ price }} each</p>
            <div class="edit-field-form hidden fix-error">
              <div class="input-prepend">
                <span class="add-on">PHP</span>
                <input id="field-price-{{ id }}" type="text" value="{{ price }}" class="edit-field" />
              </div>
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{/if}}

          {{#if quantity}}
          <div class="field quantity">
            <h4>${_("Quantity")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{ quantity }} ${_("in stock")}</p>
            <div class="edit-field-form hidden fix-error">
              <input id="field-quantity-{{ id }}" type="text" value="{{ quantity }}" class="edit-field" />
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{/if}}

          <div class="field description">
            <h4>${_("Description")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{nltobr description}}</p>
            <div class="edit-field-form hidden">
              <textarea id="field-description-{{ id }}" class="edit-field error-marker">{{ description }}</textarea>
              <div class="actions">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>

          {{#if reason}}
          <a href="#" class="add-reason-link hidden">${_("Add reason")}</a>
          <div class="field reason add-reason">
            <h4>${_("Reason")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{nltobr reason}}</p>
            <div class="edit-field-form hidden">
              <textarea id="field-reason-{{ id }}" class="edit-field error-marker">{{ reason }}</textarea>
              <div class="actions">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{else}}
          <a href="#" class="add-reason-link">${_("Add reason")}</a>
          <div class="field reason add-reason hidden">
            <h4>${_("Reason")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p></p>
            <div class="edit-field-form">
              <textarea id="field-reason-{{ id }}" class="edit-field error-marker"></textarea>
              <div class="actions">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{/if}}

          {{#if hasTags}}
          <div class="field-wrapper">
            <a href="#" class="add-tags-link hidden">${_("Add tags")}</a>
            <div class="field tags">
              <h4>${_("Tags")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
              <p class="error-marker"><input id="field-tags-{{ id }}" type="text" value="{{listTags tags}}" class="edit-field" /></p>
              <div class="edit-field-form hidden fix-error">
                <div class="actions">
                  <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                  <a href="#" class="cancel">${_("Cancel")}</a>
                </div>
              </div>
            </div>
          </div>
          {{else}}
          <div class="field-wrapper">
            <a href="#" class="add-tags-link">${_("Add tags")}</a>
            <div class="field tags hidden">
              <h4>${_("Tags")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
              <p class="error-marker"><input id="field-tags-{{ id }}" type="text" value="{{listTags tags}}" class="edit-field" /></p>
              <div class="edit-field-form fix-error">
                <div class="actions">
                  <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                  <a href="#" class="cancel">${_("Cancel")}</a>
                </div>
              </div>
            </div>
          </div>
          {{/if}}

          <div class="actions">
            <a href="#" class="delete-item">${_("Delete")}</a>
          </div>
        </div>

        <div class="tab-pane tab-pane-images" id="draft-images-{{ id }}">
          <div class="actions">
            <a href="#" class="edit-images">${_("Edit images")}</a>
            <a href="#" class="cancel-editing hidden">${_("Cancel editing")}</a>
          </div>
          <ul></ul>
          <div class="medium-image hidden"></div>
          <div class="images-masonry">
            <div class="drop-zone">
              <div class="help">${_("Drop more images here")}</div>
            </div>
          </div>
          <div class="meta">
            <input type="submit" class="upload btn btn-small" value="${_("Upload")}" disabled="disabled" />
            <span class="upload-stats">0%</span>
          </div>
        </div>

      </div>

      <ul class="nav nav-tabs">
        <li class="active">
          <a href="#draft-item-info-{{ id }}" data-toggle="tab">${_("Item Info")}</a>
        </li>
        <li>
          <a href="#draft-images-{{ id }}" data-toggle="tab">${_("Images")}</a>
        </li>
      </ul>

    </div>
  </div>
</script>

<script type="text/template" id="ongoing-panel-item-template">
  <div class="drag-handle">
    <div class="name">
      <span class="new-comments badge badge-warning hidden">0</span>
      <a href="#" class="item-name">{{ name }}</a> <a href="#" class="edit-field-link hidden">${_("Edit")}</a>
      <div class="edit-field-form hidden">
        <input id="field-name-{{ id }}" type="text" value="{{ name }}" class="edit-field error-marker" />
        <div class="actions">
          <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
          <a href="#" class="cancel">${_("Cancel")}</a>
        </div>
      </div>
    </div>
  </div>

  <div class="item-content">
    <div class="tabbable tabs-below">
      <div class="tab-content">

        <div class="tab-pane tab-pane-iteminfo active" id="ongoing-item-info-{{ id }}">
          {{#if isTrade}}
          <span class="type trade">${_("Trade")}</span>
          {{else}}
          <span class="type sale">${_("Sale")}</span>
          {{/if}}

          <div class="field created">
            <h4>${_("Created")}</h4>
            <p>{{ created }}</p>
          </div>

          {{#if isTrade}}
          <div class="field trade_with">
            <h4>${_("Trade with")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{ trade_with }}</p>
            <div class="edit-field-form hidden fix-error">
              <input id="field-trade_with-{{ id }}" type="text" value="{{ trade_with }}" class="edit-field" />
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>

          <div class="field price hidden">
            <h4>${_("Price")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>PHP {{ price }} each</p>
            <div class="edit-field-form hidden fix-error">
              <div class="input-prepend">
                <span class="add-on">PHP</span>
                <input id="field-price-{{ id }}" type="text" value="{{ price }}" class="edit-field" />
              </div>
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{else}}
          <div class="field price">
            <h4>${_("Price")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>PHP {{ price }} each</p>
            <div class="edit-field-form hidden fix-error">
              <div class="input-prepend">
                <span class="add-on">PHP</span>
                <input id="field-price-{{ id }}" type="text" value="{{ price }}" class="edit-field" />
              </div>
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{/if}}

          {{#if quantity}}
          <div class="field quantity">
            <h4>${_("Quantity")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{ quantity }} ${_("in stock")}</p>
            <div class="edit-field-form hidden fix-error">
              <input id="field-quantity-{{ id }}" type="text" value="{{ quantity }}" class="edit-field" />
              <div class="actions error-marker">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{/if}}

          <div class="field description">
            <h4>${_("Description")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{nltobr description}}</p>
            <div class="edit-field-form hidden">
              <textarea id="field-description-{{ id }}" class="edit-field error-marker">{{ description }}</textarea>
              <div class="actions">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>

          {{#if reason}}
          <a href="#" class="add-reason-link hidden">${_("Add reason")}</a>
          <div class="field reason add-reason">
            <h4>${_("Reason")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p>{{nltobr reason}}</p>
            <div class="edit-field-form hidden">
              <textarea id="field-reason-{{ id }}" class="edit-field error-marker">{{ reason }}</textarea>
              <div class="actions">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{else}}
          <a href="#" class="add-reason-link">${_("Add reason")}</a>
          <div class="field reason add-reason hidden">
            <h4>${_("Reason")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
            <p></p>
            <div class="edit-field-form">
              <textarea id="field-reason-{{ id }}" class="edit-field error-marker"></textarea>
              <div class="actions">
                <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                <a href="#" class="cancel">${_("Cancel")}</a>
              </div>
            </div>
          </div>
          {{/if}}

          {{#if hasTags}}
          <div class="field-wrapper">
            <a href="#" class="add-tags-link hidden">${_("Add tags")}</a>
            <div class="field tags">
              <h4>${_("Tags")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
              <p class="error-marker"><input id="field-tags-{{ id }}" type="text" value="{{listTags tags}}" class="edit-field" /></p>
              <div class="edit-field-form hidden fix-error">
                <div class="actions">
                  <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                  <a href="#" class="cancel">${_("Cancel")}</a>
                </div>
              </div>
            </div>
          </div>
          {{else}}
          <div class="field-wrapper">
            <a href="#" class="add-tags-link">${_("Add tags")}</a>
            <div class="field tags hidden">
              <h4>${_("Tags")} <a href="#" class="edit-field-link hidden">${_("Edit")}</a></h4>
              <p class="error-marker"><input id="field-tags-{{ id }}" type="text" value="{{listTags tags}}" class="edit-field" /></p>
              <div class="edit-field-form fix-error">
                <div class="actions">
                  <input type="submit" class="edit-field-btn btn btn-small" value="${_("Update")}" />
                  <a href="#" class="cancel">${_("Cancel")}</a>
                </div>
              </div>
            </div>
          </div>
          {{/if}}

        </div>

        <div class="tab-pane tab-pane-images" id="ongoing-images-{{ id }}">
          <div class="actions">
            <a href="#" class="edit-images">${_("Edit images")}</a>
            <a href="#" class="cancel-editing hidden">${_("Cancel editing")}</a>
          </div>
          <ul></ul>
          <div class="medium-image hidden"></div>
          <div class="images-masonry">
            <div class="drop-zone">
              <div class="help">${_("Drop more images here")}</div>
            </div>
          </div>
          <div class="meta">
            <input type="submit" class="upload btn btn-small" value="${_("Upload")}" disabled="disabled" />
            <span class="upload-stats">0%</span>
          </div>
        </div>

        <div class="tab-pane tab-pane-comments" id="ongoing-comments-{{ id }}">
          <div class="fb-comments" data-href="${request.host_url}/items/{{ id_b36 }}" data-num-posts="4"></div>
          <ul>
          </ul>
        </div>

      </div>

      <ul class="nav nav-tabs">
        <li class="active">
          <a href="#ongoing-item-info-{{ id }}" data-toggle="tab" class="item-info-tab">${_("Item Info")}</a>
        </li>
        <li>
          <a href="#ongoing-images-{{ id }}" data-toggle="tab" class="images-tab">${_("Images")}</a>
        </li>
        <li>
          <a href="#ongoing-comments-{{ id }}" data-toggle="tab" class="comments-tab">${_("Comments")} <span class="new-comments badge badge-warning hidden">0</span></a>
        </li>
      </ul>

    </div>
  </div>
</script>

<script type="text/template" id="archived-panel-item-template">
  <div class="name">
    <a href="#" class="item-name">{{ name }}</a>
  </div>
  <div class="item-content">
    <div class="tabbable tabs-below">
      <div class="tab-content">

        <div class="tab-pane tab-pane-iteminfo active" id="archived-item-info-{{ id }}">
          <div class="field created">
            <h4 class="{{ typePastense }}-on">{{#if isTrade}}${_("Traded on")}{{else}}${_("Sold on")}{{/if}} <span>{{ transaction_date }}</span></h4>
          </div>
          {{#unless isTrade}}
          <div class="field price">
            <h4>${_("Price")}</h4>
            <p>PHP {{ price }} each</p>
          </div>
          {{/unless}}
          <div class="field quantity">
            <h4>${_("Quantity")}</h4>
            <p>{{ original_quantity }} {{ suffix }}</p>
          </div>
          <div class="field description">
            <h4>${_("Description")}</h4>
            <p>{{ description }}</p>
          </div>
          {{#if reason}}
          <div class="field reason">
            <h4>${_("Reason")}</h4>
            <p>{{ reason }}</p>
          </div>
          {{/if}}

          <div class="actions">
            <a href="#" class="clone-item">${_("Clone")}</a>
          </div>
        </div>

      </div>
      <ul class="nav nav-tabs">
        <li class="active">
          <a href="#archived-item-info-{{ id }}" data-toggle="tab">${_("Item Info")}</a>
        </li>
      </ul>
    </div>
  </div>
</script>
</%block>

<%block name="pre_body">
  <div id="fb-root"></div>
  <script>
    window.fbAsyncInit = function() {
      // init the FB JS SDK
      FB.init({
        appId      : '462774343738804', // App ID from the App Dashboard
        channelUrl : '//${request.host}/channel.html', // Channel File for x-domain communication
        status     : true, // check the login status upon init?
        cookie     : true, // set sessions cookies to allow your server to access the session?
        xfbml      : true  // parse XFBML tags on this page?
      });

      // Additional initialization code such as adding Event Listeners goes here
      FB.Event.subscribe('comment.create', function(newComment) {
        var a = document.createElement('a');
        a.href = newComment.href;

        // base36 encoded item id
        itemIdB36 = a.pathname.split('/')[2];

        // notify backend
        itemSocket.emit('comment_create', {item_id_b36: itemIdB36});
      });

    };

    // Load the SDK's source Asynchronously
    // Note that the debug version is being actively developed and might 
    // contain some type checks that are overly strict. 
    // Please report such bugs using the bugs tool.
    (function(d, debug){
      var js, id = 'facebook-jssdk', ref = d.getElementsByTagName('script')[0];
      if (d.getElementById(id)) {return;}
      js = d.createElement('script'); js.id = id; js.async = true;
      js.src = "//connect.facebook.net/en_US/all" + (debug ? "/debug" : "") + ".js";
      ref.parentNode.insertBefore(js, ref);
    }(document, /*debug*/ false));

    // comments plugin
    (function(d, s, id) {
      var js, fjs = d.getElementsByTagName(s)[0];
      if (d.getElementById(id)) return;
      js = d.createElement(s); js.id = id;
      js.src = "//connect.facebook.net/en_US/all.js#xfbml=1&appId=125054457650841";
      fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));
  </script>
</%block>

<%block name="content">
<div id="dashboard">
  <div class="row">

    <div id="drafts" class="span4 dash-panel">
    </div>

    <div id="ongoing" class="span4 dash-panel">
    </div>

    <div id="archived" class="span4 dash-panel">
    </div>

  </div>
</div>
</%block>

<%block name="closure">
<script type="text/javascript">
  $(function() {
    var draftsPayload = $('<div>').html(escape("${draft_items}")).text(),
        ongoingPayload = $('<div>').html(escape("${ongoing_items}")).text(),
        archivedPayload = $('<div>').html(escape("${archived_items}")).text();
    TradeOrSale.Dashboard.showPanels(
      $.parseJSON(draftsPayload),
      $.parseJSON(ongoingPayload),
      $.parseJSON(archivedPayload));

    var WEB_SOCKET_SWF_LOCATION = '/static/plugins/socketio/WebSocketMain.swf',
        itemSocket = io.connect('/items');

    itemSocket.on('comments_counter', function(itemInfo) {
      var commentsTabLi = $('#item-' + itemInfo.item_id + ' .comments-tab').parent('li');

      // only display counter if its greater than zero and
      // the comments tab is not currently active.
      if (itemInfo.counter > 0 && !commentsTabLi.hasClass('active')) {
        $('#item-' + itemInfo.item_id + ' .new-comments').html(itemInfo.counter).removeClass('hidden');
      }
      else {
        $('#item-' + itemInfo.item_id + ' .new-comments').html(0).addClass('hidden');
      }
    });

    window.itemSocket = itemSocket;

  });
</script>
</%block>
