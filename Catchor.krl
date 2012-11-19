ruleset a169x660 {
	meta {
		name "Catchor"
		description <<
		  myCloud Catchor application
			
      Copyright 2012 Kynetx, All Rights Reserved
		>>

		// --------------------------------------------
		// ent:catchorThings
		// ent:catchorRequest

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
	rule catchor_thing_ready_sell {
	  select when explicit thing_ready_sell
		pre {
		  newThing = {
			  "thingChannel"     : event:attr("eventChannel"),
			  "thingName"        : event:attr("thingName"),
			  "thingPhoto"       : event:attr("thingPhoto"),
			  "thingDescription" : event:attr("thingDescription"),
			  "thingAttributes"  : event:attr("thingAttributes")
			};
		}
		fired {
		  set ent:catchorNextAction "catchor_post";
			set ent:newThing newThing;
		  raise explicit event cloudAppSelected for thisRID
			  with _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_Selected {
		select when web cloudAppSelected
		       or explicit cloudAppSelected
		pre {
		  appMenu = [
				{ "label"  : "Refresh",
				  "action" : "refresh" },
				{ "label"  : "Listings",
				  "action" : "listings" },
				{ "label"  : "Brokers",
				  "action" : "brokers" }
			];
		}
		{
		  //notify("catchor", "Selected, ready to load") with sticky = true;
			noop();
		}
		fired {
		  raise cloudos event appReadyToLoad
			  with appName = "Catchor"
				and  appRID  = thisRID
				and  appMenu = appMenu
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_Loaded {
	  select when explicit appLoaded
		pre {
		  appContentSelector = event:attr("appContentSelector");

			appContent = <<
			  <div id="mycloud-catchor"></div>
			>>;
		}
		{
		  // notify("catchor", "Loaded, ready to show") with sticky = true;
			replace_inner(appContentSelector, appContent);
		}
		fired {
		  raise cloudos event appReadyToShow
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_Shown {
		select when explicit appShown
		{
		  //notify("catchor", "Shown, app ready") with sticky = true;
		  cloudUI:hideSpinner();
		}
		fired {
		  raise cloudos event cloudAppReady
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

	// show POST page if there are no things listed.
	rule catchor_Shown_check_listings is inactive {
		select when explicit appShown
		pre {
		  thingCount = ent:catchorThings.keys().length();
		}
		if (thingCount == 0) then {
		  // notify("thingCount", thingCount) with sticky = true;
			noop();
		}
		fired {
		  set ent:catchorNextAction "catchor_post";
		}
	}

	rule catchor_Shown_Action {
		select when explicit appShown
		if (ent:catchorNextAction) then { noop(); }
		fired {
		  raise explicit event ent:catchorNextAction for thisRID
			  with _api = "sky";
			clear ent:catchorNextAction;
		} else {
		  raise explict event catchor_listings for thisRID
			  with _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_listings {
	  select when web cloudAppAction action re/listings/
	         or explicit catchor_listings
		pre {
		  // DEBUG
			catchorThings = ent:catchorThings;
			catchorRequest = ent:catchorRequest;
			buyOffers = ent:buyOffers;

			// --------------------------------------------
			// build request notification button & panel

			renderNotificationButton = function(thingChannel) {
			  foo = <<
				  <button id="catchorNotificationButton-#{thingChannel}" thingid="#{thingChannel}" class='btn btn-mini btn-primary btn-catchor-notification'>Notifications <span class='caret'></span></button>
				>>;
				foo
			};

			renderNotificationPanel = function(thingChannel) {
			  profileName = ent:catchorRequest{[thingChannel, "profileName"]};
			  profilePhoto = ent:catchorRequest{[thingChannel, "profilePhoto"]};
			  foo = <<
			    <div id="catchorNotificationPanel-#{thingChannel}" class="row" style="margin-left:140px;margin-right:40px;display:none;">
				    <div class="alert alert-info" style="min-height:40px;background-color: inherit;border-color: #0088CC;color: #FFFFFF;margin-bottom: 8px;margin-top: 8px;">
						  <img class="trustAllison" src="#{profilePhoto}" style="border-radius: 4px 4px 4px 4px; height: 40px;float:left;margin-right:8px;">
							<strong>Information Request</strong></br>
							<strong>#{profileName}</strong>
							<form style="margin-left:56px;margin-top:4px;margin-bottom:0;">
							  <legend style="font-size: 14px;font-weight: bold;line-height: 18px;margin-bottom: 8px;">Requested</legend>
								<label class="checkbox">
								  <input type="checkbox" checked> Maintenance History
								</label>
								<label class="checkbox">
								  <input type="checkbox" checked> Accident Reports
								</label>
								<label class="checkbox">
								  <input type="checkbox" checked> Test Drive
								</label>
								<legend style="font-size: 14px;font-weight: bold;line-height: 18px;margin-bottom: 8px;">Other Info</legend>
								<label class="checkbox">
								  <input type="checkbox"> Pictures
								</label>
								<label class="checkbox">
								  <input type="checkbox"> Trip History
								</label>
								<a href="#!/app/#{thisRID}/approveInfoRequest&thingChannel=#{thingChannel}" class="btn btn-mini btn-primary">Approve</a>
								<a href="#!/app/#{thisRID}/rejectInfoRequest&thingChannel=#{thingChannel}" class="btn btn-mini btn-primary">Reject</a>
							</form>
						</div>
				  </div>
				>>;
				foo
			};

			// --------------------------------------------
			// build buy offer notification button & panel

			renderBuyNotificationButton = function(thingChannel) {
			  foo = <<
				  <button id="catchorBuyNotificationButton-#{thingChannel}" thingid="#{thingChannel}" class='btn btn-mini btn-primary btn-catchor-buynotification'>Notifications <span class='caret'></span></button>
				>>;
				foo
			};

			renderBuyNotificationPanel = function(thingChannel) {
			  buyerName = ent:buyOffers{[thingChannel, "buyerName"]};
			  buyerPhoto = ent:buyOffers{[thingChannel, "buyerPhoto"]};
			  foo = <<
			    <div id="catchorBuyNotificationPanel-#{thingChannel}" class="row" style="margin-left:140px;margin-right:40px;display:none;">
				    <div class="alert alert-info" style="min-height:40px;background-color: inherit;border-color: #0088CC;color: #FFFFFF;margin-bottom: 8px;margin-top: 8px;text-shadow:none;">
						  <img class="trustAllison" src="#{buyerPhoto}" style="border-radius: 4px 4px 4px 4px; height: 40px;float:left;margin-right:8px;">
							<strong>Offer to Buy Received</strong></br>
							<strong>#{buyerName} - Bank Loan Approved</strong></br>
							<div style="margin-left:48px;margin-top:8px;">
							  <a href="#!/app/#{thisRID}/approveBuyRequest&thingChannel=#{thingChannel}" class="btn btn-mini btn-primary">Accept</a>
							  <a href="#!/app/#{thisRID}/rejectBuyRequest&thingChannel=#{thingChannel}" class="btn btn-mini btn-primary">Reject</a>
							</div>
						</div>
				  </div>
				>>;
				foo
			};

		  // appContent = ent:catchorThings.keys().join(" ");
			appListings = ent:catchorThings.keys().map(function(thingChannel) {
			  thingName  = ent:catchorThings{[thingChannel, "thingName"]};
			  thingPhoto = ent:catchorThings{[thingChannel, "thingPhoto"]};
			  thingPrice = ent:catchorThings{[thingChannel, "thingPrice"]};
			  thingDescription = ent:catchorThings{[thingChannel, "thingDescription"]};

				btnNotifications = (ent:catchorRequest{thingChannel}) =>
                           renderNotificationButton(thingChannel) | "";

				panelNotifications = (ent:catchorRequest{thingChannel}) =>
                             renderNotificationPanel(thingChannel) | "";

				btnBuyNotifications = (ent:buyOffers{thingChannel}) =>
                              renderBuyNotificationButton(thingChannel) | "";

				panelBuyNotifications = (ent:buyOffers{thingChannel}) =>
                                renderBuyNotificationPanel(thingChannel) | "";

				foo = <<
				  <div class="row" id="catchor-thing-#{thingChannel}">
				    <ul class="thumbnails pull-left">
					    <li>
						    <div class="thumbnail">
							    <img src="#{thingPhoto}" alt="#{thingName}">
							  </div>
					    </li>
					  </ul>
					  <div class="mycloud-listing">
					    <h3>#{thingName} <a href="#!/app/#{thisRID}/delist&thingChannel=#{thingChannel}" class="btn btn-mini btn-primary">Delist</a></h3>
							<h4>Price: $#{thingPrice}</h4>
							<p style="margin-bottom:4px;">#{thingDescription}</p>
							#{btnNotifications}
							#{btnBuyNotifications}
					  </div>
					</div>
					#{panelNotifications}
					#{panelBuyNotifications}
				>>
				foo
			}).join(" ");

			appNotice = <<
			  <div id="catchor-transfer-ownership" class="row" style="margin-left:140px;margin-right:40px;display:none;">
				  <div class="alert alert-info" style="min-height:40px;background-color: inherit;border-color: #0088CC;color: #FFFFFF;margin-bottom: 8px;margin-top: 8px;">
					  <img class="trustAllison" src="assets/people/allison.png" style="border-radius: 4px 4px 4px 4px; height: 40px;float:left;margin-right:8px;">
						<strong>Ownership Transfer Request</strong></br>
						<strong>Allison Smith</strong>
						<form class="catchor-transfer-ownership" style="margin-left:56px;margin-top:4px;margin-bottom:0;">
						  <legend style="font-size: 14px;font-weight: bold;line-height: 18px;margin-bottom: 8px;">Funds Transfer Complete</legend>
						  <button id="btn-transfer-ownership" class="btn btn-primary btn-mini" style="margin-top:4px;margin-bottom:0px;">Transfer Ownership</button>
						</form>
					</div>
				</div>
			>>;

			appContent = appListings;
		}
		{
		  // notify("catchor_listings", "hello neo ...") with sticky = true;
			replace_inner("#mycloud-catchor", appContent);
		  cloudUI:hideSpinner();

			// --------------------------------------------
			// HACK: Display Transfer Ownership Notice
			emit <<
			  $K('#mycloud-catchor img').click(function() {
					$K(this).parent().parent().parent().parent().after(appNotice);
				  $K("#catchor-transfer-ownership").show();

				  $K('#btn-transfer-ownership').click(function() {
				    $K('#catchor-transfer-ownership').remove();
				  });
				});

				$K('form.catchor-transfer-ownership').submit(function(event) {
				  event.preventDefault();
				});
			>>;

			// --------------------------------------------
			// Display Notification Panel
			emit <<
			  $K('button.btn-catchor-notification').click(function() {
				  var thingid = $K(this).attr('thingid');
					var panelid = '#catchorNotificationPanel-' + thingid;
					console.info("Notification thingid: ", thingid);

					$K(panelid).toggle();
				});
			>>;

			// --------------------------------------------
			// Display Buy Notification Panel
			emit <<
			  $K('button.btn-catchor-buynotification').click(function() {
				  var thingid = $K(this).attr('thingid');
					var panelid = '#catchorBuyNotificationPanel-' + thingid;
					// console.info("Notification thingid: ", thingid);

					$K(panelid).toggle();
				});
			>>;

			// --------------------------------------------
			// HACK: Display notifications
//			emit <<
//			  $K('button.btn-catchor-notification').click(function() {
//				  $K(this).parent().parent().after(buyNotice);
//				  $K('#btnApproveRequest').click(function() {
//				    $K('#catchor-buynotice').remove();
//				  });
//				});
//			>>;
		}
		//fired {
		//  clear ent:catchorThings;
		//}
	}

  // ------------------------------------------------------------------------
	rule catchor_approveInfoRequest {
	  select when web cloudAppAction action re/approveInfoRequest/
		pre {
		  thingChannel = event:attr("thingChannel");

			thingName    = ent:catchorRequest{[thingChannel, "thingName"]};
			profileName  = ent:catchorRequest{[thingChannel, "profileName"]};
			thingChannel = ent:catchorRequest{[thingChannel, "thingChannel"]};
			thingBackChannel = ent:catchorRequest{[thingChannel, "thingBackChannel"]};

			// --------------------------------------------
			// send subscription approval into things PEN

			subscription_map = {
			      "cid" : thingChannel
			};
		}
		{
		  // notify("approveInfoRequest", thingChannel) with sticky = true;
		  cloudUI:hideSpinner();

			// --------------------------------------------
			// hide notification panel & button
			emit <<
				var panelid  = '#catchorNotificationPanel-' + thingChannel;
				var buttonid = '#catchorNotificationButton-' + thingChannel;
			  $K(panelid).hide();
			  $K(buttonid).hide();
			>>;

			// --------------------------------------------
			// Approve subscription request for my thing
		  event:send(subscription_map, "cloudos", "subscriptionRequestApproved")
			  with attrs = {
				  "eventChannel" : thingBackChannel
				};
		}
		always {
		  // Delete request for information
		  clear ent:catchorRequest{thingChannel};
			// notification is a must
		  raise notification event status
			  with application = "Catchor"
				and  subject     = "Information Request Approved"
				and  description = "Approved request for information about " + thingName + " from " + profileName
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_rejectInfoRequest {
	  select when web cloudAppAction action re/rejectInfoRequest/
		pre {
		  thingChannel = event:attr("thingChannel");

			thingName    = ent:catchorRequest{[thingChannel, "thingName"]};
			profileName  = ent:catchorRequest{[thingChannel, "profileName"]};
			thingChannel = ent:catchorRequest{[thingChannel, "thingChannel"]};
			thingBackChannel = ent:catchorRequest{[thingChannel, "thingBackChannel"]};

			// --------------------------------------------
			// send subscription approval into things PEN

			subscription_map = {
			      "cid" : thingChannel
			};
		}
		{
		  // notify("approveInfoRequest", thingChannel) with sticky = true;
		  cloudUI:hideSpinner();

			// --------------------------------------------
			// hide notification panel & button
			emit <<
				var panelid  = '#catchorNotificationPanel-' + thingChannel;
				var buttonid = '#catchorNotificationButton-' + thingChannel;
			  $K(panelid).hide();
			  $K(buttonid).hide();
			>>;

			// --------------------------------------------
			// Reject subscription request for my thing
		  event:send(subscription_map, "cloudos", "subscriptionRequestRejected")
			  with attrs = {
				  "eventChannel" : thingBackChannel
				};
		}
		always {
		  // Delete request for information
		  clear ent:catchorRequest{thingChannel};
			// notification is a must
		  raise notification event status
			  with application = "Catchor"
				and  subject     = "Information Request Rejected"
				and  description = "Rejected request for information about " + thingName + " from " + profileName
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_post {
	  select when web cloudAppAction action re/post/
           or explicit catchor_post
		pre {
		  newThing = ent:newThing || {"thingChannel":"","thingName":"","thingPhoto":""};
			thingChannel     = newThing{"thingChannel"};
			thingName        = newThing{"thingName"};
			thingPhoto       = newThing{"thingPhoto"};
			thingDescription = newThing{"thingDescription"};
			thingAttributes  = newThing{"thingAttributes"};

			appContent = <<
        <form id="formCatchorPost" class="form-horizontal">
          <fieldset>
						<input type="hidden" name="thingChannel" value="#{thingChannel}">
            <div class="control-group">
              <label class="control-label" for="thingName">Name</label>
              <div class="controls">
                <input type="text" name="thingName" value="#{thingName}">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="thingDescription">Description</label>
              <div class="controls">
                <textarea name="thingDescription">#{thingDescription}</textarea>
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="thingPrice">Price</label>
              <div class="controls">
                <input type="text" name="thingPrice" value="">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="thingAttributes">Attributes</label>
              <div class="controls">
                <input type="text" name="thingAttributes" value="#{thingAttributes}">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for="thingPhotoPreview">Photo</label>
              <div class="controls">
								<img id="thingPhotoPreview" src="#{thingPhoto}" class="mycloud-photo-preview" alt="">
              </div>
            </div>
            <div class="control-group">
              <label class="control-label" for=""></label>
              <div class="controls">
							  <input type="file" id="thingPhoto" onchange="KOBJ.a169x660.loadPhotoPreview(this)">
								<input type="hidden" id="thingPhotoSrc" name="thingPhoto" value="#{thingPhoto}">
              </div>
            </div>
            <div class="form-actions">
              <button type="submit" class="btn btn-primary">Publish</button>
            </div>
          </fieldset>
        </form>
			>>;
		}
		{
		  // notify("catchor", "You Post") with sticky = true;
			replace_inner("#mycloud-catchor", appContent);
		  cloudUI:hideSpinner();

			// Make the file browser button pretty
			emit <<
				$K(":file").filestyle({
				  textField: false,
					icon: true
				});
			>>;

			// Load preview of image
			emit <<
        KOBJ.a169x660.loadPhotoPreview = function(input) {
          if (input.files && input.files[0]) {
            var reader = new FileReader();

            reader.onload = function (e) {
              $K('#thingPhotoPreview')
                .attr('src', e.target.result);
              $K('#thingPhotoSrc')
                .val(e.target.result);
            };

            reader.readAsDataURL(input.files[0]);
          }
       }			
			>>;

			// custom form submit
			emit <<
				  $K('#formCatchorPost').submit(function(event) {
					  var _form = '#formCatchorPost';
						var _token = KOBJ.skyNav.sessionToken;
						var _postlude = 'formCastorPostPostlude';
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
							var type = 'formCastorPostPostlude';
							var _token = KOBJ.skyNav.sessionToken;
							var _rid = thisRID;
							var eid = Math.floor(Math.random()*9999999);

							var channel = $K('#formCatchorPost input:[name="thingChannel"]').val();

							var esl = 'https://cs.kobj.net/sky/event/' +
						            _token + '/' + 	eid + '/' +
									      dom + '/' +	type + '?_rids=' + _rid +
												'&thingChannel=' + channel;

							var r = document.createElement("script");
							r.src = esl;
							r.type = "text/javascript";
							r.onload = r.onreadystatechange = KOBJ.url_loaded_callback;
							var body = document.getElementsByTagName("body")[0] ||
							           document.getElementsByTagName("frameset")[0];
							body.appendChild(r);
						});
					});
			>>;

		}
		fired {
		  clear ent:newThing;
		}
	}

  // ------------------------------------------------------------------------
	rule formCatchorPost_submit {
	  select when web submit "#formCatchorPost"
		pre {
		  thingChannel = event:attr("thingChannel");
		}
		fired {
		  set ent:catchorThings{thingChannel} event:attrs();
			raise explicit event new_thing_added
			  for  thisRID
				with thingChannel = thingChannel
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule formCatchorPost_submit_Postlude {
	  select when web formCastorPostPostlude
		pre {
		  thingChannel = event:attr("thingChannel");
			thingName = ent:catchorThings{[thingChannel, "thingName"]};
			thingPrice = ent:catchorThings{[thingChannel, "thingPrice"]};
		}
		{
		  // notify("formCatchorPost_submit_Postlude", "thingChannel: " + thingChannel) with sticky = true;
		  cloudUI:hideSpinner();
		}
		always {
		  raise notification event status
			  with application = "Catchor"
				and  subject     = thingName + " listed"
				and  description = thingName + " has been listed for sale for $" + thingPrice
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_brokers {
	  select when web cloudAppAction action re/brokers/
		pre {
		  agentSubs = CloudOS:subscriptionList("IntentCasting", "agent");
			agentHTML = agentSubs.map(function(a) {
			  channelName  = a{"channelName"};
				eventChannel = a{"eventChannel"};
				backChannel  = a{"backChannel"};
				profilePhoto = "/assets/img/people/" + channelName.lc() + ".png";

				agent = <<
				  <li class="span2" id="myBroker-#{backChannel}">
					  <a href="#!/app/#{thisRID}/unsubscribe&backChannel=#{backChannel}" class="thumbnail mycloud-thumbnail">
						  <img src="#{profilePhoto}" alt="#{channelName}">
							<h5 class="cloudUI-center">#{channelName}</h5>
						</a>
				  </li>
				>>;
				agent
			}).join(" ");

			appContent = <<
			  <h4 style="margin-left:20px;">myBrokers</h4>
			  <ul class="thumbnails mycloud-thumbnails">
				  #{agentHTML}
			  </ul>
			  <h4 style="margin-left:20px;">Brokers</h4>
			  <ul class="thumbnails mycloud-thumbnails">
				  <li class="span2">
					  <a href="#!/app/#{thisRID}/subscribe&doorbell=fe21fd60-f961-012f-39a0-00163e64d091" class="thumbnail mycloud-thumbnail">
						  <img src="/assets/img/people/faststuff.png" alt="FastStuff">
							<h5 class="cloudUI-center">FastStuff</h5>
						</a>
				  </li>
				  <li class="span2">
					  <span class="thumbnail mycloud-thumbnail">
						<img src="/assets/img/people/ebay.png" alt="eBay">
						<h5 class="cloudUI-center">eBay</h5>
					  </span>
				  </li>
				  <li class="span2">
					  <span class="thumbnail mycloud-thumbnail">
						  <img src="/assets/img/people/craigslist.png" alt="Craigslist">
						  <h5 class="cloudUI-center">Craigslist</h5>
					  </span>
				  </li>
			  </ul>
			>>;
		}
		{
		  // notify("catchor_brokers", "Brokers") with sticky = true;
			replace_inner("#mycloud-catchor", appContent);
		  cloudUI:hideSpinner();
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_cloudAppCommand_delist {
	  select when web cloudAppAction action re/delist/
		pre {
		  thingChannel  = event:attr("thingChannel");
			thingSelector = "#catchor-thing-" + thingChannel;
			thingName = ent:catchorThings{[thingChannel, "thingName"]};
		}
		{
		  // notify("catchor_cloudAppCommand_delist", "hello neo ...") with sticky = true;
			emit <<
			  $K(thingSelector).remove();
			>>;
		  cloudUI:hideSpinner();
		}
		fired {
		  clear ent:catchorThings{thingChannel};
		  raise notification event status
			  with application = "Catchor"
				and  subject     = thingName + " delisted"
				and  description = thingName + " is no longer listed for sale"
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_cloudAppCommand_delist_subscribers {
	  select when web cloudAppAction action re/delist/
		pre {
		  BrokerList = CloudOS:subscriptionList("IntentCasting", "agent");
			BrokerListMap = BrokerList.map(function(subscriber) {
				eventChannel = subscriber{"eventChannel"};
				backChannel  = subscriber{"backChannel"};
				mymap = {
				  "cid"          : eventChannel,
					"eventChannel" : eventChannel,
					"backChannel"  : backChannel
				};
				mymap
			});
		}
		fired {
		  raise explicit event delist_thing_broker
			  for  thisRID
				with subscribers = BrokerListMap
				and  thingChannel = event:attr("thingChannel")
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_delist_thing_broker {
	  select when explicit delist_thing_broker
		foreach event:attr("subscribers") setting (subscriber)
		  pre {
				thingChannel = event:attr("thingChannel");
				eventChannel = subscriber{"eventChannel"};
				backChannel  = subscriber{"backChannel"};
				eventType = "broker_thing_delist";
			}
			{
			  event:send(subscriber, "explicit", eventType)
				  with attrs = {
					"thingChannel" : thingChannel,
			    "eventChannel" : eventChannel,
			    "backChannel"  : backChannel
					};
			}
	}

  // ------------------------------------------------------------------------
	rule catchor_cloudAppCommand_subscribe {
	  select when web cloudAppAction action re/^subscribe$/
		pre {
		  doorbell = event:attr("doorbell");
		}
		{
		  // notify("whitePages_cloudAppCommand_myfoo", doorbell) with sticky = true;
		  cloudUI:hideSpinner();
		}
		always {
		  raise system event subscribe
				with namespace = "IntentCasting"
			  and  channelName = "FastStuff"
				and  relationship = "agent-broker"
				and  targetChannel = doorbell
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_unsubscribe {
	  select when web cloudAppAction action re/unsubscribe/
		pre {
		  backChannel = event:attr("backChannel");
			uiSelector  = "#myBroker-#{backChannel}";
		}
		{
		  // notify("myConnections_unsubscribe", backChannel) with sticky = true;
			emit << $K(uiSelector).remove(); >>;
		  cloudUI:hideSpinner();
		}
		always {
		  raise system event unsubscribe
			  with backChannel = backChannel
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_new_thing_added {
	  select when explicit new_thing_added
		pre {
		  BrokerList = CloudOS:subscriptionList("IntentCasting", "agent");
			BrokerListMap = BrokerList.map(function(subscriber) {
				eventChannel = subscriber{"eventChannel"};
				backChannel  = subscriber{"backChannel"};
				mymap = {
				  "cid"          : eventChannel,
					"eventChannel" : eventChannel,
					"backChannel"  : backChannel
				};
				mymap
			});
		}
		fired {
		  raise explicit event new_thing_added_broker
			  for  thisRID
				with subscribers = BrokerListMap
				and  thingChannel = event:attr("thingChannel")
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_new_thing_added_broker {
	  select when explicit new_thing_added_broker
		foreach event:attr("subscribers") setting (subscriber)
		  pre {
				thingChannel = event:attr("thingChannel");
				eventChannel = subscriber{"eventChannel"};
				backChannel  = subscriber{"backChannel"};

				thingName        = ent:catchorThings{[thingChannel, "thingName"]};
				thingDescription = ent:catchorThings{[thingChannel, "thingDescription"]};
				thingPrice       = ent:catchorThings{[thingChannel, "thingPrice"]};
				thingAttributes  = ent:catchorThings{[thingChannel, "thingAttributes"]};
				thingPhoto       = ent:catchorThings{[thingChannel, "thingPhoto"]};
				thingOwner       = pds:get_me('myProfileName');

				eventType = "broker_thing_add";
			}
			{
			  event:send(subscriber, "explicit", eventType)
				  with attrs = {
					"thingChannel"     : thingChannel,
					"thingName"        : thingName,
					"thingDescription" : thingDescription,
					"thingPrice"       : thingPrice,
					"thingAttributes"  : thingAttributes,
					"thingPhoto"       : thingPhoto,
					"thingOwner"       : thingOwner,
			    "eventChannel"     : eventChannel,
			    "backChannel"      : backChannel
					};
			}
	}

  // ------------------------------------------------------------------------
	rule catchor_Request_for_Information {
	  select when explicit catchorInformationRequest
		pre {
		  thingChannel = event:attr("thingChannel");
		  infoRequest = {
			  "thingChannel"     : event:attr("thingChannel"),
			  "thingBackChannel" : event:attr("thingBackChannel"),
			  "thingName"        : event:attr("thingName"),
			  "profileName"      : event:attr("profileName"),
			  "profilePhoto"     : event:attr("profilePhoto"),
			  "profileDoorbell"  : event:attr(profileDoorbell)
			};
		}
		always {
		  set ent:catchorRequest{thingChannel} infoRequest;
		}
	}

	// ========================================================================
	// BUY RULES
	// 
	// ent:buyOffers

	rule catchor_newBuyOffer {
	  select when explicit newBuyOffer
		pre {
		  thingChannel = event:attr("thingChannel");
		  buyerName    = event:attr("buyerName");

			thingName  = ent:catchorThings{[thingChannel, "thingName"]};
			thingPrice = ent:catchorThings{[thingChannel, "thingPrice"]};
		}
		always {
		  set ent:buyOffers{thingChannel} event:attrs();
		  raise notification event status
			  with application = "Catchor"
				and  subject     = "Buy Offer Received"
				and  description = "Offer to buy " + thingName + " for $" + thingPrice + " received from " + buyerName
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_approveBuyRequest {
	  select when web cloudAppAction action re/approveBuyRequest/
		pre {
		  thingChannel = event:attr("thingChannel");

			buyerName    = ent:buyOffers{[thingChannel, "buyerName"]};
			buyerChannel = ent:buyOffers{[thingChannel, "buyerChannel"]};
			thingName    = ent:catchorThings{[thingChannel, "thingName"]};
			thingPrice   = ent:catchorThings{[thingChannel, "thingPrice"]};

			// --------------------------------------------
			// send buy offer accepted

			event_map = {
			      "cid" : buyerChannel
			};

			sellerName  = pds:get_me('myProfileName');
			sellerPhoto = pds:get_me('myProfilePhoto');
    }
		{
		  // notify("Approve Buy", thingChannel) with sticky = true;

		  event:send(event_map, "explicit", "buyOfferAccepted")
			  with attrs = {
				  "thingChannel" : thingChannel,
					"sellerName"   : sellerName,
					"sellerPhoto"  : sellerPhoto
				};

			// Hide buy notification panel
			emit <<
			  $K('#catchorBuyNotificationPanel-' + thingChannel).hide();
			>>;

			// Replace buy notification buttom
			emit <<
			  $K('#catchorBuyNotificationButton-' + thingChannel).replaceWith('<h4>Sold - Pending Funds Transfer</h4>');
			>>;

		  cloudUI:hideSpinner();
		}
		always {
		  raise notification event status
			  with application = "Catchor"
				and  subject     = "Buy Offer Accepted"
				and  description = "Accepted offer to buy " + thingName + " for $" + thingPrice + " from " + buyerName
				and  priority    = 0
				and  _api = "sky";
		}
  }

  // ------------------------------------------------------------------------
	rule catchor_buyTransferComplete {
	  select when explicit buyTransferComplete
		pre {
		  thingChannel = event:attr("thingChannel");

			buyerName  = ent:buyOffers{[thingChannel, "buyerName"]};
			thingName  = ent:catchorThings{[thingChannel, "thingName"]};
			thingPrice = ent:catchorThings{[thingChannel, "thingPrice"]};
		}
		always {
		  clear ent:buyOffers{thingChannel};
		  raise notification event status
			  with application = "Catchor"
				and  subject     = "Funds Transfer Complete"
				and  description = "Received $" + thingPrice + " for " + thingName + " from " + buyerName
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule catchor_cloudAppCommand_refresh {
	  select when web cloudAppAction action re/refresh/
		{
		  cloudUI:setHash("#!/app/"+thisRID+"/show");
		}
	}

  // ------------------------------------------------------------------------
  // Beyond here there be dragons :)
  // ------------------------------------------------------------------------
}
