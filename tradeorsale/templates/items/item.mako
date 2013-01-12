<%inherit file="../base.mako"/>

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
<div class="fb-comments" data-href="${request.host_url}/items/${item_id}" data-num-posts="4"></div>
</%block>

<%block name="closure">
<script type="text/javascript">
  $(function() {
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
