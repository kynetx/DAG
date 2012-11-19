ruleset a169x672 {
	meta {
		name "myProfile"
		description <<
			myCloud personal profile

      Copyright 2012 Kynetx, All Rights Reserved
		>>
		author "Ed Orcutt"
		logging on

    use module a169x625 alias CloudOS
		use module a169x664 alias cloudUI
		use module a169x676 alias pds
	}

	global {
    thisRID = meta:rid();
	}

  // ------------------------------------------------------------------------
	rule myProfile_cloudAppSelected {
		select when web cloudAppSelected
		pre {
		  appMenu = [
				{ "label"  : "Refresh",
				  "action" : "refresh" }
			];
		}
		{
		  // notify("myProfile", "hello neo ...");
			noop();
		}
		fired {
		  raise cloudos event appReadyToLoad
			  with appName = "myProfile"
				and  appRID  = thisRID
				and  appMenu = appMenu
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule myProfile_cloudAppLoaded {
	  select when explicit appLoaded
		{
			noop();
		}
		fired {
		  raise cloudos event appReadyToShow
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // -----------------------------------------------------------------------
	rule myProfile_appShown {
		select when explicit appShown
		pre {
		  appContentSelector = event:attr("appContentSelector");

			appContent = <<
        <form id="formMyProfile" class="form-horizontal">
          <fieldset>
            <div class="control-group">
              <label class="control-label" for="myProfileName">Name</label>
              <div class="controls">
                <input type="text" name="myProfileName" value="#{pds:get_me('myProfileName')}">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="myProfileEmail">Email</label>
              <div class="controls">
                <input type="text" name="myProfileEmail" value="#{pds:get_me('myProfileEmail')}">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="myProfilePhone">Phone</label>
              <div class="controls">
                <input type="text" name="myProfilePhone" value="#{pds:get_me('myProfilePhone')}">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="myDoorbell">Doorbell</label>
              <div class="controls">
                <input type="text" name="myDoorbell" class="disabled" disabled="" value="#{pds:get_me('myDoorbell')}">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="myProfilePhotoPreview">Photo</label>
              <div class="controls">
							  <img id="myProfilePhotoPreview" src="#{pds:get_me('myProfilePhotoSrc')}" class="mycloud-photo-preview" alt="">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="myProfilePhoto"></label>
              <div class="controls">
							  <input type="file" id="myProfilePhoto" onchange="KOBJ.a169x672.loadPhotoPreview(this)">
								<input type="hidden" id="myProfilePhotoSrc" name="myProfilePhotoSrc" value="#{pds:get_me('myProfilePhotoSrc')}">
                <!-- <input type="text" name="myProfilePhoto"> -->
              </div>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Save Changes</button>
            </div>
          </fieldset>
        </form>
			>>;
		}
		{
			replace_inner(appContentSelector, appContent);
		  // notify("myProfile_cloudAppShown", "hello neo ...");
		  cloudUI:hideSpinner();

			emit <<
				$K(":file").filestyle({
				  textField: false,
					icon: true
				});
			>>;

			emit <<
        KOBJ.a169x672.loadPhotoPreview = function(input) {
          if (input.files && input.files[0]) {
            var reader = new FileReader();

            reader.onload = function (e) {
              $K('#myProfilePhotoPreview')
                .attr('src', e.target.result);
              $K('#myProfilePhotoSrc')
                .val(e.target.result);
            };

            reader.readAsDataURL(input.files[0]);
          }
       }			

				  $K('#formMyProfile').submit(function(event) {
					  var _form = '#formMyProfile';
						var _token = KOBJ.skyNav.sessionToken;
						var _postlude = 'formMyProfilePostlude';
						var _rid = thisRID;

					  event.preventDefault();
						$K('#modalSpinner').modal('show');

					  var dom  = 'web';
						var type = 'submit';
						var eid  = Math.floor(Math.random()*9999999);
						var attr = $K(this).serialize();

						var esl = 'https://cs.kobj.net/sky/event/' +
						          _token + '/' + 	eid + '/' +
											dom + '/' +	type + '?_rids=' + _rid +
											'&element=' + encodeURIComponent(_form);

						$K.post(esl, attr)
						.complete(function(data) {
						  // alert('complete');
						  // --------------------------------------------
							// Not call the postlude
							var dom = 'web';
							var type = 'formMyProfilePostlude';
							var _token = KOBJ.skyNav.sessionToken;
							var _rid = thisRID;
							var eid = Math.floor(Math.random()*9999999);
							var esl = 'https://cs.kobj.net/sky/event/' +
						            _token + '/' + 	eid + '/' +
									      dom + '/' +	type + '?_rids=' + _rid;

							var r = document.createElement("script");
							r.src = esl;
							r.type = "text/javascript";
							r.onload = r.onreadystatechange = KOBJ.url_loaded_callback;
							var body = document.getElementsByTagName("body")[0] ||
							           document.getElementsByTagName("frameset")[0];
							body.appendChild(r);
						});


						//var thisApp = KOBJ.get_application(_rid);
						//thisApp.raise_event(_postlude, {}, _rid)
					});
			>>;
		}
		fired {
		  raise cloudos event cloudAppReady
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule formMyProfile_submit {
	  select when web submit "#formMyProfile"
		fired {
		  // set ent:myProfile event:attrs();
			raise pds event new_profile_item_available
				attributes event:attrs();
		}
	}

  // ------------------------------------------------------------------------
	rule formMyProfile_submitPostlude_Subscribers  {
	  select when web formMyProfilePostlude
		fired {
			raise pds event my_profile_updated
			  with _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule formMyProfile_submitPostlude_Subscribers_Orig is inactive  {
	  select when web formMyProfilePostlude
		pre {
		  friendSubList = CloudOS:subscriptionList("myConnections", "friend");
			friendSubMap = friendSubList.map(function(subscriber) {
			  eventChannel = friendSubList{[backChannel, "eventChannel"]};
				eventChannel = subscriber{"eventChannel"};
				backChannel = subscriber{"backChannel"};
				mymap = {
				  "cid"          : eventChannel,
					"eventChannel" : eventChannel,
					"backChannel"  : backChannel
				};
				mymap
			});
		}
		fired {
		  raise explicit event userProfile_subscriptionUpdate
			  for  thisRID
				with subscribers = friendSubMap
			  and  _api = "sky";
			raise pds event my_profile_updated
			  with _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule formMyProfile_updateSubscribers is inactive {
	  select when explicit userProfile_subscriptionUpdate
		foreach event:attr("subscribers") setting (subscriber)
		  pre {
			  profileName  = pds:get_me('myProfileName');
			  profileEmail = pds:get_me('myProfileEmail');
			  profilePhone = pds:get_me('myProfilePhone');
			  profilePhoto = pds:get_me('myProfilePhotoSrc');

				eventChannel = subscriber{"eventChannel"};
				backChannel  = subscriber{"backChannel"};

			  eventType = "myConnections_friend_userProfile_subscriptionUpdate";
			}
			{
			  event:send(subscriber, "explicit", eventType)
				  with attrs = {
			    "profileName"  : profileName,
			    "profileEmail" : profileEmail,
			    "profilePhone" : profilePhone,
			    "profilePhoto" : profilePhoto,
			    "eventChannel" : eventChannel,
			    "backChannel"  : backChannel
					};
			}
	}

  // ------------------------------------------------------------------------
	rule formMyProfile_submitPostlude {
	  select when web formMyProfilePostlude
		{
		  // notify("formMyProfile_submit", "hello neo ...") with sticky = true;
		  cloudUI:hideSpinner();
		}
	}

  // ------------------------------------------------------------------------
	rule myProfile_cloudAppCommand_refresh {
	  select when web cloudAppAction action re/refresh/
		{
		  cloudUI:setHash("#!/app/"+thisRID+"/show");
		}
	}

  // ------------------------------------------------------------------------
  // Beyond here there be dragons :)
  // ------------------------------------------------------------------------
}
