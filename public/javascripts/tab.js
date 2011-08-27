window.fbAsyncInit = function() {
  FB.init({
    appId  : '#{FB_APP_ID}',
    status : true, // check login status
    cookie : true, // enable cookies to allow the server to access the session
    xfbml  : true, // parse XFBML
    channelUrl  : 'http://simplegiveawayapp.com/channel.html'
  });

  FB.Canvas.setSize();

  FB.Event.subscribe('edge.create', function() {
    $just_liked = true;
    Giveaway.step.one.hide();
    Giveaway.step.two.show();
  });
};

(function() {
  var e = document.createElement('script');
  e.src = document.location.protocol + '//connect.facebook.net/en_US/all.js';
  e.async = true;
  document.getElementById('fb-root').appendChild(e);
}());

$(function() {

  // init
  $just_liked = false;

  $app_data = '#{@giveaway["app_data"] || "ref_none"}';
  $referrer = $app_data.split("ref_")[1];

  var $modal = $("#giveaway_modal");
  var $loader = $modal.find(".loader");

  $("#giveaway_image").click(function() {
    Giveaway.modal.hide();
  });

  // Giveaway object
  Giveaway = {

    modal : $modal,

    step : {
      one : $modal.find(".step.one"),
      two : $modal.find(".step.two"),
      three : $modal.find(".step.three")
    },

    loader : $loader,

    eligible : #{@giveaway["has_liked"]},

    entry : {

      loader : function() {
        $modal.find(".step").hide();
        $loader.show();
        $modal.show();
      },

      error : function(error) {
        $loader.hide();
        Giveaway.step.two.hide();
        Giveaway.step.three.show().find(".entry-status").html('<p>' + error + '</p>');
        Giveaway.share.listener();
      },

      success : function() {
        $loader.hide();
        Giveaway.step.two.hide();
        Giveaway.step.three.show();
        Giveaway.share.listener();
      },

      submit : function(thesession, json) {
        Giveaway.entry.loader();
        if (json) {
          thesession = eval('(' + thesession + ')'); //decode json
        }
        $.ajax({
          type: 'POST',
          url: '#{giveaway_entries_path(@giveaway["giveaway"])}',
          dataType: "json",
          data: 'session_key=' + thesession.session_key + '&has_liked=' + Giveaway.eligible + '&ref_id=' + $referrer,
          statusCode: {
            201: function(response) {
              Giveaway.entry.success();
              $entry_id = response;
              $share_count = 0;
              $request_count = 0;
            },
            406: function(response) {
              Giveaway.entry.error("You have already entered the giveaway.<br />Entry is limited to one per person.");
              var $entry = jQuery.parseJSON(response.responseText);
              $entry_id = $entry.entry.id;
              $share_count = parseInt($entry.entry.share_count);
              $request_count = parseInt($entry.entry.request_count);
            },
            412: function() {
              $loader.hide();
              Giveaway.step.one.show();
            },
            404: function() {
              Giveaway.entry.error("There was an unexpected error.<br />Please reload the page and try again.");
            },
            424: function() {
              Giveaway.entry.error("There was an unexpected error.<br />Please reload the page and try again.");
            }
          }
        });
      },

      statusCheck : function() {
        FB.getLoginStatus(function(response) {
          if (response.session) {
            Giveaway.entry.submit(response.session);
          } else {
            FB.ui({
              method: 'oauth',
              client_id: '#{FB_APP_ID}',
              perms: 'email, user_location, user_birthday, user_likes, publish_stream, offline_access'
            },
            function(response) {
              if (response.session) {
                $new_session = response.session;
                Giveaway.entry.submit(response.session, true);
              } else {
                console.log($just_liked);
                Giveaway.entry.error("You must grant permissions in order to enter the giveaway.");
              }
            });
          }
        });
      },

      eligible : function() {
        Giveaway.entry.loader();
        if (typeof($new_session) === "undefined") {
          Giveaway.entry.statusCheck();
        } else {
          Giveaway.entry.submit($new_session, true);
        }
      }
    },

    share : {

      listener : function() {
        $("a.wall-post").click(function(e) {
          Giveaway.share.as_wall_post();
          e.preventDefault();
        });
        $("a.app-request").click(function(e) {
          Giveaway.share.as_app_request();
          e.preventDefault();
        });
      },

      callback : function(json) {
        $.ajax({
          type: 'PUT',
          url: '#{giveaway_entries_path(@giveaway["giveaway"])}' + '/' + $entry_id,
          dataType: "text",
          data: json,
          statusCode: {
            202: function(response) {
              alert("Do something with this 202");
            },
            406: function(response) {
              alert("Do something with this 406");
            },
            404: function() {
              Giveaway.entry.error("There was an unexpected error.<br />Please reload the page and try again.");
            }
          }
        });
      },

      dialog : function(data) {
        FB.ui(
          data,
          function(response) {
            if (response && response.post_id) {
              json = {
                entry : {
                  share_count : $share_count + 1
                }
              };
              Giveaway.share.callback(json);
              console.log('Post was published.' + $entry_id);
            }
            else if (response && response.request_ids) {
              json = {
                entry : {
                  request_count : $request_count + response.request_ids.length
                }
              };
              Giveaway.share.callback(json);
              console.log('Request was sent.' + $entry_id);
            }
            else {
              console.log('Nothing was shared.' + $entry_id);
            }
          }
        );
      },

      as_wall_post : function() {
        Giveaway.share.dialog({
          method: "feed",
          name: '#{@giveaway["current_page"]["name"]}',
          link: '#{@giveaway["giveaway"]["giveaway_url"]}' + '&app_data=ref_' + $entry_id,
          picture: '#{@giveaway["giveaway"].feed_image.url}',
          caption: '#{@giveaway["giveaway"].title}',
          description: '#{@giveaway["giveaway"].description}'
        });
      },

      as_app_request : function() {
        Giveaway.share.dialog({
          method: 'apprequests',
          message: '#{@giveaway["giveaway"].description}',
          data: { referrer_id : $entry_id.toString(), giveaway_id : '#{@giveaway["giveaway"]["id"]}' }
        });
      }
    }
  };

  // Event Listeners
  $("#enter_giveaway a").click(function(e) {
    if (Giveaway.eligible || $just_liked) {
      Giveaway.entry.eligible();
    } else {
      Giveaway.modal.show();
      Giveaway.step.two.find("a").click(function(event) {
        event.preventDefault();
        Giveaway.entry.statusCheck();
      });
    }
    e.preventDefault();
  });
});