<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>${h.get_settings(request, 'site_name')}</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <meta name="description" content="A trading platform that doesn't suck.">
    <meta name="author" content="Marconi Moreto">
    <meta name="keywords" content="philippine trading, trading, tradein, buy and sell, selling, alternative to sulit, alternative to ebay, buying, selling, trading platform">
    <meta name="copyright" content="2012">
    <meta name="Distribution" content="Global">
    <meta name="Rating" content="General">
    <meta http-equiv="cache-control" content="${h.get_settings(request, 'meta_cache_control', 'public')}">
    <meta http-equiv="expires" content="${h.get_settings(request, 'meta_expires', '1d')}">
    <meta name="google-site-verification" content="mpj_333wovI73H-hGUZhT_2THMjilfuAl4YKS51UKXo" />

    <!-- Le styles -->
    <link href="http://fonts.googleapis.com/css?family=Lobster" rel="stylesheet" type="text/css">
    <link href="${h.assets_url(request, '/plugins/jquery/ui/css/smoothness/jquery-ui-1.9.2.custom.min.css')}" rel="stylesheet">
    <link href="${h.assets_url(request, '/plugins/tag-it/css/jquery.tagit.css')}" rel="stylesheet">
    <link href="${h.assets_url(request, '/plugins/bootstrap/css/bootstrap.min.css')}" rel="stylesheet">
    <link href="${h.assets_url(request, '/css/font-awesome/css/font-awesome.css')}" rel="stylesheet">
    <link href="${h.assets_url(request, '/css/font-awesome/css/font-awesome-ie7.css')}" rel="stylesheet">
    <link href="${h.assets_url(request, '/css/local.css')}" rel="stylesheet">

    % if h.get_settings(request, "analytics") == 'true':
    % endif

    <%include file="includes/js_templates.mako"/>

    <%block name="header">
    </%block>

  </head>
  <body class="${body_class if body_class else ''}">

    <%block name="pre_body">
    </%block>

    <div id="container-wrapper">
      <div id="main-container" class="container">

        <div class="navbar">
          <div class="navbar-inner">
            <div class="container">
              <a class="brand" href="${url('home')}">${h.get_settings(request, 'site_name')}</a>
              <div id="main-nav" class="nav-collapse pull-right">
                <ul class="nav">
                  <li ${'class=active' if request.path_info == request.route_path('home') else ''}>
                    <a href="${url('home')}">${_("Home")}</a>
                  </li>
                  <li ${'class=active' if request.path_info == request.route_path('dashboard') else ''}>
                    <a href="${url('dashboard')}">${_("Dashboard")}</a>
                  </li>
                  <li class="dropdown">
                    <a href="#myaccount" class="dropdown-toggle" data-toggle="dropdown">
                      ${_("Your Account")}&nbsp;<b class="caret"></b>
                    </a>
                    <ul class="dropdown-menu">
                      <li><a href="#">${_('Profile')}</a></li>
                      <li><a href="#">${_('Settings')}</a></li>
                      <li class="divider"></li>
                      <li><a href="#">${_('Logout')}</a></li>
                    </ul>
                  </li>
                  <li id="btn-post-item-parent">
                    <a href="#" id="btn-post-item">${_('Post Item')}</a>
                    <div class="popup-arrow"></div>
                  </li>
                </ul>
              </div><!--/.nav-collapse -->
            </div>
          </div>
        </div>

        <div id="global-region"></div>

        <div id="content">
          <%block name="content">
          </%block>
        </div>
        <div id="footer">Developed by <a href="https://twitter.com/marconimjr">@marconimjr</a></div>

      </div> <!-- /container -->
    </div>

    <script type="text/javascript">
      var csrfToken = "${session.get_csrf_token()}",
          baseUrl = "${request.host_url}",
          currentUser = {id: 1, name: "Marconi", photo: "http://localhost:6543/static/users/photos/1/me_small.jpg?v=1354198418"};
    </script>

    <script src="${h.assets_url(request, '/plugins/socketio/socket.io.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/misc/json2.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/misc/uuid.js')}"></script>
    <script src="${h.assets_url(request, '/js/moment.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/backbone/underscore.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/jquery/jquery.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/jquery/jquery.ui.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/tag-it/tag-it.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/jquery/jquery.filedrop.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/bootstrap/js/bootstrap.min.js')}"></script>

    <script src="${h.assets_url(request, '/plugins/backbone/handlebars.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/backbone/backbone.min.js')}"></script>
    <script src="${h.assets_url(request, '/plugins/backbone/Backbone.validateAll.min.js')}"></script>
    <script src="${h.assets_url(request, '/js/helpers.js')}"></script>
    <script src="${h.assets_url(request, '/js/tradeorsale.js')}"></script>
    <script src="${h.assets_url(request, '/js/dashboard/panels.js')}"></script>
    <script src="${h.assets_url(request, '/js/dashboard/postitem.js')}"></script>
    <script src="${h.assets_url(request, '/js/common.js')}"></script>

    <script type="text/javascript">
      var tagNames = new TradeOrSale.ItemTags($.parseJSON($('<div>').html("${tag_names}").text()));
    </script>

    <%block name="closure">      
    </%block>

  </body>
</html>
