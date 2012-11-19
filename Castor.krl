ruleset a169x659 {
	meta {
		name "Castor"
		description <<
			myCloud Castor application

      Copyright 2012 Kynetx, All Rights Reserved
		>>

		// --------------------------------------------
		// ent:intentCast
		// ent:intentRequest
		//
		// "thingChannel" : {
		//   "backChannel" : "",
		//   "sellChannel" : "",
		//   "thingName"   : "",
		//   "status"      : "init/request"
		// }

		author "Ed Orcutt"
		logging on

    use module a169x625 alias CloudOS
		use module a169x664 alias cloudUI
		use module a169x676 alias pds
	}

	global {
    thisRID = meta:rid();

		// --------------------------------------------
		renderCastAttrs = function(castAttrs) {
		  castPlus  = "Interest:" + castAttrs;
		  castSplit = castPlus.split(re/;/);
			castHTML = castSplit.map(function(a) {
			  part = a.split(re/:/);
			  "<p><strong>"+part[0]+":</strong> "+part[1]+"</p>"
			}).join(" ");
			castHTML
		};

		// --------------------------------------------
		renderCastAttrsORIG = function(castAttrs) {
		  castSplit = castAttrs.split(re/;/);
			castHTML = castSplit.map(function(a) {
			  "<h5>"+a+"</h5>"
			}).join(" ");
			castHTML
		};
	}

  // ------------------------------------------------------------------------
	rule castor_Selected {
		select when web cloudAppSelected
		       or explicit cloudAppSelected
		pre {
		  appMenu = [
				{ "label"  : "Refresh",
				  "action" : "refresh" },
				{ "label"  : "Intentcast",
				  "action" : "intents" },
				{ "label"  : "Preview Shelf",
				  "action" : "shelf" },
				{ "label"  : "Brokers",
				  "action" : "brokers" },
				{ "label"  : "Reset Buy",
				  "action" : "resetbuy" }
			];
		}
		fired {
		  // clear ent:buyOffers;
		  raise cloudos event appReadyToLoad
			  with appName = "Castor"
				and  appRID  = thisRID
				and  appMenu = appMenu
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_Loaded {
	  select when explicit appLoaded
		pre {
		  appContentSelector = event:attr("appContentSelector");

			appContent = <<
			  <div id="mycloud-castor">hello neo ...</div>
			>>;
		}
		{
			replace_inner(appContentSelector, appContent);
		}
		fired {
		  raise cloudos event appReadyToShow
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_Shown {
		select when explicit appShown
		{
		  // cloudUI:hideSpinner();
			noop();
		}
		fired {
		  raise cloudos event cloudAppReady
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_intents {
	  select when web cloudAppAction action re/intents/
		       or explicit appShown
		pre {

			// --------------------------------------------
			// Build the modal Send Request button
			sendRequestButton = function(castID, thingID) {
			  requestStatus = (ent:intentRequest{thingID}) => ent:intentRequest{[thingID,"status"]} | "none";
				btnLabel = (requestStatus eq "request")  => "Request Pending"  |
				           (requestStatus eq "approved") => "Request Approved" |
				           (requestStatus eq "rejected") => "Request Rejected" | "Send Request";

				btnColor = (requestStatus eq "request")  => "btn-info"    |
				           (requestStatus eq "approved") => "btn-success" |
				           (requestStatus eq "rejected") => "btn-danger"  | "btn-primary";

			  foo = <<
					<a href="#!/app/#{thisRID}/subscribeThing&castID=#{castID}&thingID=#{thingID}" thingid="#{thingID}" class="btn #{btnColor}">#{btnLabel}</a>
				>>;
				foo
			};

		  // --------------------------------------------
			// Thing Request Info modal
			renderRequestInfoModal = function(thingID, thingName, castID) {
			  btnSendRequest = sendRequestButton(castID, thingID);
			  foo = <<
				    <div id="modal-castor-thing-#{thingID}" class="modal hide fade modal-castor-thing">
				      <div class="modal-header">
					      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
						    <h3>#{thingName}</h3>
					    </div>
					    <div class="modal-body">
							  <form class="pull-right" style="margin-right: 60px;">
								  <legend>Other Request</legend>
								  <label class="checkbox">
									  <input type="checkbox" value="">
										Test Drive 
									</label>
								  <label class="checkbox">
									  <input type="checkbox" value="" checked="">
										Include Reputation
									</label>
							  </form>
							  <form class="pull-left" style="margin-left: 60px;">
								  <legend>Available Information</legend>
								  <label class="checkbox">
									  <input type="checkbox" value="">
										Maintenance History
									</label>
								  <label class="checkbox">
									  <input type="checkbox" value="">
										Pictures
									</label>
								  <label class="checkbox">
									  <input type="checkbox" value="">
										Trip History
									</label>
								  <label class="checkbox">
									  <input type="checkbox" value="">
										Accident Reports 
									</label>
							  </form>
					    </div>
					    <div class="modal-footer">
							  #{btnSendRequest}
						    <!-- <button class="btn btn-primary" thingid="#{thingID}">Send Request</button> -->
					    </div>
				    </div>
				>>;
				foo
			};

			// --------------------------------------------
			// Modal for creating Intentcast
			renderCreateIntentcast = function() {
			  foo = <<
				    <div id="modal-castor-create-cast" class="modal hide fade">
				      <div class="modal-header">
					      <button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button>
						    <h3>Create Intentcast</h3>
					    </div>
							<form id="form-castor-create-cast" class="form-horizontal" style="margin-bottom:0;">
					      <div class="modal-body">
								  <div class="control-group">
									  <label class="control-label" for="castLabel">Description</label>
										<div class="controls">
										  <input type="text" name="castLabel">
										</div>
									</div>
								  <div class="control-group">
									  <label class="control-label" for="castMaxPrice">Max Price</label>
										<div class="controls">
										  <input type="text" name="castMaxPrice">
										</div>
									</div>
								  <div class="control-group">
									  <label class="control-label" for="castCondition">Condition</label>
										<div class="controls">
											<select name="castCondition">
											  <option>New or Used</option>
											  <option>New</option>
											  <option>Used</option>
											</select>
										</div>
									</div>
								  <div class="control-group">
									  <label class="control-label" for="castSeller">Seller</label>
										<div class="controls">
											<select name="castSeller">
											  <option>Priviate Seller Only</option>
											  <option>Brick & Mortar</option>
											  <option>Distributor</option>
											  <option>Any Seller</option>
											</select>
										</div>
									</div>
								  <div class="control-group">
									  <label class="control-label" for="castAttrs">Attributes</label>
										<div class="controls">
										  <input type="text" name="castAttrs">
										</div>
									</div>
					      </div>
					      <div class="modal-footer">
						      <button type="submit" class="btn btn-primary">Cast Intent</button>
					      </div>
							</form>
				    </div>
				>>;
				foo
			};

			// --------------------------------------------
			// HACK: render Trust Icon
			renderTrustIcon = function(thingOwner) {
			  trustID = "trust" + thingOwner.replace(re/\ /g, "");
				foo = thingOwner +
				      " <img class='" + trustID +
							"' src='assets/trust/connectme_16.png'>"
				foo
			};

			// --------------------------------------------
			// Build the Subscribe (Request Info) button
//			requestInfoButton = function(castID, thingID) {
//			  requestStatus = (ent:intentRequest{thingID}) => ent:intentRequest{[thingID,"status"]} | "none";
//				btnLabel = (requestStatus eq "request")  => "Request Pending"  |
//				           (requestStatus eq "approved") => "Request Approved" |
//				           (requestStatus eq "rejected") => "Request Rejected" | "Subscribe";
//
//			  //btnLabel = (ent:intentRequest{thingID}) =>
//        //           ((ent:intentRequest{[thingID,"status"]} eq "request")  => "Request Pending" | "Request Approved" ) |
//				//					 "Subscribe";
//			  foo = <<
//					<a href="#!/app/#{thisRID}/subscribeThing&castID=#{castID}&thingID=#{thingID}" class="btn btn-mini btn-primary">#{btnLabel}</a>
//				>>;
//				foo
//			};

		  // --------------------------------------------
			renderBuyThingPanel = function(thingChannel) {
			  sellerName = ent:buyOffers{[thingChannel, "sellerName"]};
			  sellerPhoto = ent:buyOffers{[thingChannel, "sellerPhoto"]};
			  foo = <<
			    <div id="castorBuyNotificationPanel-#{thingChannel}" class="row" style="margin-left:140px;margin-right:40px;display:block;">
				    <div class="alert alert-info" style="min-height:40px;background-color: inherit;border-color: #0088CC;color: #333333;margin-bottom: 8px;margin-top: 8px;text-shadow:none;">
						  <img class="trustAllison" src="#{sellerPhoto}" style="border-radius: 4px 4px 4px 4px; height: 40px;float:left;margin-right:8px;">
							<strong>Approve Funds Transfer</strong></br>
							<strong>#{sellerName} - Buy Offer Accepted</strong></br>
							<div style="margin-left:48px;margin-top:8px;">
							  <a href="#!/app/#{thisRID}/approveBuyThing&thingChannel=#{thingChannel}" class="btn btn-mini btn-primary">Approve</a>
							<div>
						</div>
				  </div>
				>>;
				foo
			};

		  // --------------------------------------------
		  // Build the HTML that will display offer to review
		  renderResult = function(castResult, castID) {
			  thingContent = castResult.decode().map(function(a) {
					thingName  = a{'thingName'};
					thingPhoto = a{'thingPhoto'};
					thingPrice = a{'thingPrice'};
					thingDescription = a{'thingDescription'};
					thingOwner = (a{'thingOwner'}) => renderTrustIcon(a{'thingOwner'}) | "Unpublished";
					thingID = a{'thingChannel'};

					thingModal = renderRequestInfoModal(thingID, thingName, castID);

			  	requestStatus = (ent:intentRequest{thingID}) => ent:intentRequest{[thingID,"status"]} | "none";
					btnLabel = (requestStatus eq "request")  => "Request Pending"  |
				             (requestStatus eq "approved") => "Request Approved" |
				             (requestStatus eq "rejected") => "Request Rejected" | "Request Info";

					thingActionButtons = <<
								<button thingid="#{thingID}" class="btn btn-mini btn-primary btn-castor-thing">#{btnLabel}</button>
								<a href="#!/app/#{thisRID}/buyThing&castID=#{castID}&thingID=#{thingID}" class="btn btn-mini btn-primary">Buy</a>
								<!-- <button class="btn btn-mini btn-primary btn-castor-buy">Buy</button> -->
					>>;

					buyStatus = (ent:buyOffers{thingID}) => ent:buyOffers{[thingID,"status"]} | "none";
					thingActions = (buyStatus eq "offer")    => "<h4>Buy Offer Pending</h4>" |
                         (buyStatus eq "accepted") => "<h4 id='castorBuyStatus-#{thingID}'>Buy Offer Accepted</h4>" |
                         thingActionButtons;

					buyThingPanel = (buyStatus eq "accepted") => renderBuyThingPanel(thingID) | "";

					// requestButton = requestInfoButton(castID, thingID);
					foo = <<
				    <div class="row">
				      <ul class="thumbnails pull-left">
					      <li>
						      <div class="thumbnail">
							      <img src="#{thingPhoto}" alt="#{thingName}">
							    </div>
					      </li>
					    </ul>
					    <div class="mycloud-listing">
					      <h3>#{thingName} <img style="max-width:22px;" title="more like this" src="assets/icons/up.png"> <img style="max-width:22px;" title="less like this" src="assets/icons/down.png"></h3>
							  <h4>Price: $#{thingPrice}</h4>
							  <h4>Owner: #{thingOwner}</h4>
							  <p>#{thingDescription}</p>
								#{thingActions}
					    </div>
					  </div>
						#{thingModal}
						#{buyThingPanel}
				  >>;
				  foo
				}).join(" ");
				thingContainer = <<
				  <div id="castor-result-#{castID}" style="margin-top:10px;display:none;">
				    #{thingContent}
				  </div>
				>>;
				thingContainer
			};

			// --------------------------------------------
			// Generate "qualified sellers" HTML
			countResult = function(castResult, castID) {
			  count = castResult.decode().length();
				btnReview = (count == 0) => "" |
				  "<button class='btn btn-mini btn-success castor-offer' castid='#{castID}'>Review Offers <span class='caret'></span></button>";
				foo = <<
				  #{count} qualified sellers
					#{btnReview}
				>>
				foo
			};

			// FOR DEBUG ONLY
			intentCast = ent:intentCast;
			intentRequest = ent:intentRequest;
			buyOffers = ent:buyOffers;


			// --------------------------------------------
			// Generate listing for your Intentcast
		  castContent = ent:intentCast.keys().sort(function(a,b){a < b}).map(function(timestamp) {
			  castLabel = ent:intentCast{[timestamp, "castLabel"]};
			  castAttrs = ent:intentCast{[timestamp, "castAttrs"]};
				castHTML  = renderCastAttrs(castAttrs);
				
			  castResult = ent:intentCast{[timestamp, "castResult"]};
				brokerResult = (castResult) => renderResult(castResult, timestamp) | "";
				brokerResultCount = (castResult) => countResult(castResult, timestamp) | "0 qualified sellers";

				foo = <<
			  <div class="row well well-small" id="castor-intent-#{timestamp}">
				  <a href="#!/app/#{thisRID}/decast&castID=#{timestamp}" class="btn btn-mini pull-right" title="remove intentcast"><i class="icon-remove"></i></a>
				  <h3>#{castLabel}</h3>
				  <!-- <h3>#{castLabel} <a href="#!/app/#{thisRID}/decast&castID=#{timestamp}" class="btn btn-mini btn-primary">Remove</a></h3> -->
					#{castHTML}
					<h5>#{brokerResultCount}</h5>
					#{brokerResult}
				</div>
				>>;
				foo
			}).join(" ");

			// --------------------------------------------
			// Form to create Intentcast

			formIntentcast = renderCreateIntentcast();
			appContent = <<
			  <div class="row" id="formCastor" style="margin-bottom:20px;">
				  <button id="btn-castor-create-cast" class="btn btn-primary">Create Intentcast</button>
				</div>
				#{formIntentcast}
				#{castContent}
			>>;

			buyNotice = <<
			  <div id="castor-buy-notice" class="row" style="margin-left:140px;margin-right:40px;display:block;">
				  <div class="alert alert-info" style="min-height:40px;background-color: inherit;border-color: #0088CC;color: #000000;margin-bottom: 8px;margin-top: 8px;">
					  <img class="trustAllison" src="assets/people/ben.png" style="border-radius: 4px 4px 4px 4px; height: 40px;float:left;margin-right:8px;">
						<strong>Purchase Confirmation</strong></br>
						<strong>Ben Goode</strong></br>
						<button id="btn-buy-confirmation" class="btn btn-primary btn-mini" style="margin-top:4px;margin-bottom:0px;">Purchase Confirmed</button>
					</div>
				</div>
			>>;

		}
		{
			replace_inner("#mycloud-castor", appContent);
			CloudOS:skyWatchSubmit("#formCastIntent", "");
			CloudOS:skyWatchSubmit("#form-castor-create-cast", "");
		  cloudUI:hideSpinner();

			// --------------------------------------------
			// Button: Create Intentcast
			emit <<
			  $K('#btn-castor-create-cast').click(function() {
				  $K('#modal-castor-create-cast').modal('show');
				});
			>>;

			// --------------------------------------------
			// Button: Modal - Create Intentcast
			emit <<
			  $K('#modal-castor-create-cast button').click(function() {
				  $K('#modal-castor-create-cast').modal('hide');
				});
			>>;

			// --------------------------------------------
			// Button: Review Offers
			emit <<
			  $K('button.castor-offer').click(function() {
				  var castid = $K(this).attr('castid');
					var resultid = '#castor-result-' + castid;
					$K(resultid).toggle();
				  //console.log('Clicked Castor Offer! castid: ', castid);
				});
			>>;

			// --------------------------------------------
			// Button: Request Info
			emit <<
			  $K('button.btn-castor-thing').click(function() {
				  var thingid = $K(this).attr('thingid');
					var modalid = '#modal-castor-thing-' + thingid;
					$K(modalid).modal('show');
					// console.log('Clicked Request Info, thingid: ', thingid);
				});
			>>;

			// --------------------------------------------
			// Button: Modal - Send Request
			  emit <<
			  $K('div.modal-castor-thing a.btn').click(function() {
				  var thingid = $K(this).attr('thingid');
					var modalid = '#modal-castor-thing-' + thingid;
					$K(modalid).modal('hide');
				});
				>>;
//			emit <<
//			  $K('div.modal-castor-thing button').click(function() {
//				  var thingid = $K(this).attr('thingid');
//					var modalid = '#modal-castor-thing-' + thingid;
//					$K(modalid).modal('hide');
//
//					// ----------------------
//					// raise event
//					var eid = Math.floor((Math.random()*9999999)+1);
//					var tok = KOBJ.skyNav.sessionToken;
//					var dom = 'web';
//					var evt = 'info_request_sent';
//					var rid = 'a169x659';
//					var esl = 'https://cs.kobj.net/sky/event/'
//                  + tok + '/'
//									+ eid + '/'
//									+ dom + '/'
//									+ evt + '/'
//									+ '?_rids=' + rid
//
//	  		  var r = document.createElement("script");
//		  		r.src = esl;
//			  	r.type = "text/javascript";
//				  r.onload = r.onreadystatechange = KOBJ.url_loaded_callback;
//  				var body = document.getElementsByTagName("body")[0] ||
//                     document.getElementsByTagName("frameset")[0];
//  				body.appendChild(r);
//				});
//			>>;

			// --------------------------------------------
			// HACK: Buy button
			emit <<
			  $K('button.btn-castor-buy').click(function() {
				  $K(this).parent().parent().after(buyNotice);
				  $K('#btn-buy-confirmation').click(function() {
				    $K('#castor-buy-notice').remove();
				  });
				});
			>>;

			// --------------------------------------------
			// HACK: Trustcard for Ben Goode
			emit <<
		$K("img.trustBenGoode")
      .popover({
		     content: "<div class='trust-card'><div class='card small' data-puid='puid:c1F4B'><div class='avatar' data-puid='puid:c1F4B'><img class='user' src='assets/people/ben.png' /></div><h2>Ben Goode</h2><div class='info'><ul><li class='location'><a target='_blank' href='https://maps.google.com/maps?q='>Provo, UT</a></li><li class='followers'>918 connections</li></ul></div><ul class='tags'><li class='tag'><a class='tag' data-tag-name='kynetx' href='#'>trustworthy <i class='score'>89</i></a></li><li class='tag'><a class='tag' data-tag-name='blogger' href='#'>employed <i class='score'>43</i></a></li><li class='tag'><a class='tag' data-tag-name='hoverme hovercard' href='#'>home owner <i class='score'>42</i></a></li><li class='tag'><a class='tag' data-tag-name='coder' href='#'>reliable <i class='score'>123</i></a></li></ul><div class='profiles'><a target='_blank' class='provider twitter' href='http://twitter.com/'>twitter</a><a target='_blank' class='provider linkedin' href='http://www.linkedin.com/'>linkedin</a><a target='_blank' class='provider facebook' href='http://www.facebook.com/'>facebook</a></div><div class='trust-level level2'>Verified</div></div></div>",
				 trigger: "hover"
		  })
      .click(function(e) {
        e.preventDefault()
		})
		$K("img.trustFredWilson")
      .popover({
		     content: "<div class='trust-card'><div class='card small' data-puid='puid:c1F4B'><div class='avatar' data-puid='puid:c1F4B'><img class='user' src='assets/people/fred.png' /></div><h2>Fred Wilson</h2><div class='info'><ul><li class='location'><a target='_blank' href='https://maps.google.com/maps?q='>Salt Lake City, UT</a></li><li class='followers'>33 connections</li></ul></div><ul class='tags'><li class='tag'><a class='tag' data-tag-name='kynetx' href='#'>trustworthy <i class='score'>30</i></a></li><li class='tag'><a class='tag' data-tag-name='krl developer' href='#'>employed <i class='score'>3</i></a></li><li class='tag'><a class='tag' data-tag-name='hoverme hovercard' href='#'>renter <i class='score'>7</i></a></li><li class='tag'><a class='tag' data-tag-name='coder' href='#'>reliable <i class='score'>3</i></a></li></ul><div class='profiles'><a target='_blank' class='provider twitter' href='http://twitter.com/'>twitter</a><a target='_blank' class='provider linkedin' href='http://www.linkedin.com/'>linkedin</a><a target='_blank' class='provider facebook' href='http://www.facebook.com/'>facebook</a></div><div class='trust-level level0'>Unverified</div></div></div>",
				 trigger: "hover"
		  })
      .click(function(e) {
        e.preventDefault()
		})
			>>;
		}
	}

  // ------------------------------------------------------------------------
	// HACK
	rule castor_info_request_sent {
	  select when web info_request_sent
		always {
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Information Request"
				and  description = "Your information request has been sent to the seller"
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_formCastIntent_submit_ORIG  is inactive {
	  select when web submit "#formCastIntent"
		pre {
		  timestamp = time:strftime(time:now({"tz":"UTC"}), "%s");
			castAttrs = renderCastAttrs(renderCastAttrs(event:attr("castAttrs")));
			newCast = <<
			  <div class="row well well-small" id="castor-intent-#{timestamp}">
				  <a href="#!/app/#{thisRID}/decast&castID=#{timestamp}" class="btn btn-mini pull-right" title="remove intentcast"><i class="icon-remove"></i></a>
				  <h3>#{event:attr("castLabel")}</h3>
					#{castAttrs}
				</div>
			>>;
		}
		{
		  // notify("castor_formCastIntent_submit", timestamp) with sticky = true;
			after("#formCastor", newCast);
			emit <<
			  // clear form values
				$K('#formCastIntent input').val('')
			>>;
		  cloudUI:hideSpinner();
		}
		always {
		  set ent:intentCast{timestamp} event:attrs();
		  raise notification event status
			  with application = "Castor"
				and  subject     = event:attr("castLabel")
				and  description = "Intent casted for " + event:attr("castLabel")
				and  priority    = 0
				and  _api = "sky";
			raise explicit event castor_intentcast_brokers
			  for  thisRID
				with castID = timestamp
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_formCastIntent_submit {
	  select when web submit "#form-castor-create-cast"
		pre {
		  castAttrs = event:attr("castAttrs") +
			            ";Max Price:$" + event:attr("castMaxPrice") +
									";Condition:" + event:attr("castCondition") +
									";Seller:" + event:attr("castSeller");
			castMap = {
			  "castAttrs" : castAttrs,
			  "castLabel" : event:attr("castLabel")
			};

		  timestamp = time:strftime(time:now({"tz":"UTC"}), "%s");
			castHTML = renderCastAttrs(castAttrs);
			newCast = <<
			  <div class="row well well-small" id="castor-intent-#{timestamp}">
				  <a href="#!/app/#{thisRID}/decast&castID=#{timestamp}" class="btn btn-mini pull-right" title="remove intentcast"><i class="icon-remove"></i></a>
				  <h3>#{event:attr("castLabel")}</h3>
					#{castHTML}
				</div>
			>>;
		}
		{
		  // notify("castor_formCastIntent_submit", timestamp) with sticky = true;
			after("#formCastor", newCast);
			emit <<
			  // clear form values
				$K('#formCastIntent input').val('')
			>>;
		  cloudUI:hideSpinner();
		}
		always {
		  set ent:intentCast{timestamp} castMap;
		  raise notification event status
			  with application = "Castor"
				and  subject     = event:attr("castLabel")
				and  description = "Intent cast for " + event:attr("castLabel")
				and  priority    = 0
				and  _api = "sky";
			raise explicit event castor_intentcast_brokers
			  for  thisRID
				with castID = timestamp
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_decast {
	  select when web cloudAppAction action re/decast/
		pre {
		  castID  = event:attr("castID");
			castSelector = "#castor-intent-" + castID;
			castLabel = ent:intentCast{[castID, "castLabel"]}
		}
		{
			emit <<
			  $K(castSelector).remove();
			>>;
		  cloudUI:hideSpinner();
		}
		fired {
		  clear ent:intentCast{castID};
		  raise notification event status
			  with application = "Castor"
				and  subject     = castLabel
				and  description = "Intentcast removed for " + castLabel
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_intentcast_brokers {
	  select when explicit castor_intentcast_brokers
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
		  raise explicit event send_intentcast_brokers
			  for  thisRID
				with subscribers = BrokerListMap
				and  castID = event:attr("castID")
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_send_intentcast_brokers {
	  select when explicit send_intentcast_brokers
		foreach event:attr("subscribers") setting (subscriber)
		  pre {
			  castID = event:attr("castID");
				eventChannel = subscriber{"eventChannel"};
				backChannel  = subscriber{"backChannel"};

				castAttrs = ent:intentCast{[castID, "castAttrs"]}.split(re/;/).head();

				eventType = "broker_intentcast_query";
			}
			{
			  event:send(subscriber, "explicit", eventType)
				  with attrs = {
					"castID"       : castID,
					"castAttrs"    : castAttrs,
			    "eventChannel" : eventChannel,
			    "backChannel"  : backChannel
					};
			}
	}

  // ------------------------------------------------------------------------
	rule castor_agent_intentcast_result {
	  select when explicit agent_intentcast_result
		pre {
		  castID       = event:attr("castID");
		  castAttrs    = event:attr("castAttrs");
		  castResult   = event:attr("castResult");
		  backChannel  = event:attr("eventChannel");
		  eventChannel = event:attr("backChannel");

			newCast = {
			  "castLabel" : ent:intentCast{[castID, "castLabel"]},
			  "castAttrs" : ent:intentCast{[castID, "castAttrs"]},
			  "castResult" : castResult.encode()
			};
		}
		always {
		  //set ent:castResult castAttrs;
		  set ent:intentCast{[castID,"castResult"]} castResult;
		  //set ent:intentCast{castID} newCast;
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_brokers {
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
					  <a href="#!/app/#{thisRID}/unsubscribe&backChannel=#{backChannel}&brokerName=#{channelName}" class="thumbnail mycloud-thumbnail">
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
					  <a href="#!/app/#{thisRID}/subscribe&doorbell=fe21fd60-f961-012f-39a0-00163e64d091&brokerName=FastStuff" class="thumbnail mycloud-thumbnail">
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
			replace_inner("#mycloud-castor", appContent);
		  cloudUI:hideSpinner();
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_shelf {
	  select when web cloudAppAction action re/shelf/
		pre {

		  // DEBUG
		  intentRequest = ent:intentRequest;
			intentCast = ent:intentCast;

			// convert request map to array
			requestArray = ent:intentRequest.keys().map(function(thingChannel) {
			  ent:intentRequest{thingChannel}
			});
			// filter request on status === "approved"
			requestList = requestArray.filter(function(x) {
			  (x{"status"} eq "approved" )
			});

			// iterate over approved request
			requestHTML = requestList.map(function(x) {
			  thingName    = x{"thingName"};
			  castID       = x{"castID"};
				thingChannel = x{"thingChannel"};
				backChannel  = x{"backChannel"};

				thingCast = ent:intentCast{[castID,"castResult"]}.decode().filter(function(x) {
				  (x{"thingChannel"} eq thingChannel)
				}).head();
				thingPhoto = thingCast{"thingPhoto"};

				foo = <<
				  <li class="span2" id="castor-shelf-#{backChannel}">
					<div class="thumbnail mycloud-thumbnail">
					  <a href="#!/app/#{thisRID}/become" class="thumbnail mycloud-thumbnail">
						  <img src="#{thingPhoto}" alt="#{thingName}">
						</a>
							<h5 class="cloudUI-center">#{thingName}</h5>
								<div class="btn-toolbar">
									<div class="btn-group mycloud-btn-nav" style="display:none;">
										<button data-toggle="dropdown" class="btn btn-mini dropdown-toggle"><span class="icon-cog"></span> <span class="caret"></span></button>
										<ul class="dropdown-menu">
											<li><a href="#!/app/#{thisRID}/removeRequest&backChannel=#{backChannel}">Remove</a></li>
											<li><a href="#!/become/#{thingChannel}">Become</a></li>
										</ul>
									</div>  <!-- /btn-group -->
								</div>  <!-- .btn-toolbar -->
					</div>  <!-- .thumbnail -->
				  </li>
				>>;
				foo
			}).join(" ");

			appContent = <<
			  <h4 style="margin-left:20px;">Preview Shelf</h4>
			  <ul class="thumbnails mycloud-thumbnails">
				  #{requestHTML}
			  </ul>
			>>;
		}
		{
			replace_inner("#mycloud-castor", appContent);
		  cloudUI:hideSpinner();
		}
  }

  // ------------------------------------------------------------------------
	rule castor_removeRequest {
		select when web cloudAppAction action re/removeRequest/
			pre {
				backChannel = event:attr("backChannel");
				shelfSelector = "#castor-shelf-" + backChannel;
			}
		{
			//notify("castor_removeRequest", backChannel) with sticky = true;
			emit <<
			  $K(shelfSelector).hide();
			>>;
		  cloudUI:hideSpinner();
		}
		always {
			raise system event unsubscribe
				with backChannel = backChannel
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_subscribe {
	  select when web cloudAppAction action re/^subscribe$/
		pre {
		  doorbell   = event:attr("doorbell");
			brokerName = event:attr("brokerName");
		}
		{
		  cloudUI:hideSpinner();
		}
		always {
		  raise system event subscribe
				with namespace = "IntentCasting"
			  and  channelName = "FastStuff"
				and  relationship = "agent-broker"
				and  targetChannel = doorbell
				and  subSummary = "Pending subscription request from " + pds:get_me('myProfileName')
				and  profileName   = pds:get_me('myProfileName')
				and  profilePhoto  = pds:get_me('myProfilePhoto')
				and  _api = "sky";
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Broker added"
				and  description = brokerName + " has been added as a broker."
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_unsubscribe {
	  select when web cloudAppAction action re/unsubscribe/
		pre {
		  backChannel = event:attr("backChannel");
			uiSelector  = "#myBroker-#{backChannel}";
			brokerName = event:attr("brokerName");
		}
		{
			emit << $K(uiSelector).remove(); >>;
		  cloudUI:hideSpinner();
		}
		always {
		  raise system event unsubscribe
			  with backChannel = backChannel
				and  _api = "sky";
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Broker removed"
				and  description = brokerName + " has been removed as a broker."
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_subscribe_thing {
	  select when web cloudAppAction action re/^subscribeThing$/
		pre {
		  thingChannel = event:attr("thingID");
			castID  = event:attr("castID");

			resultArray = ent:intentCast{[castID,"castResult"]}.decode();
			castThing = resultArray.filter(function(x) {
			  (x{"thingChannel"} eq thingChannel)
			}).head();
			thingName   = castThing{"thingName"};
			sellChannel = castThing{"backChannel"};

			intentRequest = {
			  "thingChannel" : thingChannel,
			  "backChannel"  : "",
				"sellChannel"  : sellChannel,
				"thingName"    : thingName,
				"castID"       : castID,
			  "status"       : "request"
			};
		}
		{
		  //notify("Subscribe to Thing", thingChannel) with sticky = true;
			//emit <<
			//  var modalid = '#modal-castor-thing-' + thingChannel;
			//	$K(modalid).modal('hide');
			//>>;
		  cloudUI:hideSpinner();
		}
		always {
		  set ent:intentRequest{thingChannel} intentRequest;
		  raise system event subscribe
				with namespace = "Castor"
			  and  channelName = "RequestInfo"
				and  relationship = "agent-thing"
				and  targetChannel = thingChannel
				and  subSummary = "Pending subscription request for " + thingName + " from " + pds:get_me('myProfileName')
				and  profileName   = pds:get_me('myProfileName')
				and  profilePhoto  = pds:get_me('myProfilePhoto')
				and  _api = "sky";
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Information Request"
				and  description = "Requested additional information about " + thingName + " from " + pds:get_me('myProfileName')
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	// harvest backChannel for subscription request for thing

	rule castor_subscriptionRequestAdded {
	  select when cloudos subscriptionRequestAdded
                        namespace re/Castor/
											  channelName re/RequestInfo/
												relationship re/agent\-thing/
		pre {
		  backChannel  = event:attr("backChannel");
			thingChannel = event:attr("targetChannel");

			sellChannel  = ent:intentRequest{[thingChannel, "sellChannel"]};
			thingName    = ent:intentRequest{[thingChannel, "thingName"]};
			castID       = ent:intentRequest{[thingChannel, "castID"]};

			intentRequest = {
			  "thingChannel" : thingChannel,
			  "backChannel"  : backChannel,
				"sellChannel"  : sellChannel,
				"thingName"    : thingName,
				"castID"       : castID,
			  "status"       : "request"
			};

			// --------------------------------------------
			// send info request to sell

			subscription_map = {
			      "cid" : sellChannel
			};
		}
		{
		  event:send(subscription_map, "explicit", "catchorInformationRequest")
			  with attrs = {
				  "thingChannel"     : thingChannel,
				  "thingBackChannel" : backChannel,
				  "thingName"        : thingName,
				  "profileName"      : pds:get_me('myProfileName'),
				  "profilePhoto"     : pds:get_me('myProfilePhoto'),
				  "profileDoorbell"  : pds:get_me('myDoorbell')
				};
		}
		always {
		  set ent:intentRequest{thingChannel} intentRequest;
//		  raise system event subscribe
//				with namespace = "Castor"
//			  and  channelName = "RequestInfo"
//				and  relationship = "agent-seller"
//				and  targetChannel = sellChannel
//				and  subSummary = "Pending information request for " + thingName + " from " + pds:get_me('myProfileName')
//				and  profileName   = pds:get_me('myProfileName')
//				and  profilePhoto  = pds:get_me('myProfilePhoto')
//				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_subscriptionInfoRequest_Added {
	  select when explicit subscriptionAdded
                        namespace re/Castor/
											  channelName re/RequestInfo/
												relationship re/agent/
    pre {
		  backChannel = event:attr("backChannel");

			// Convert from map to array
			requestArray = ent:intentRequest.keys().map(function(a) { ent:intentRequest{a} });

			// find matching info request
			myRequest = requestArray.filter(function(a) {
			  (a{"backChannel"} eq backChannel)
			}).head();

			thingChannel = myRequest{"thingChannel"};
		}
		always {
		  set ent:intentRequest{[thingChannel, "status"]} "approved";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_subscriptionInfoRequest_Rejected {
	  select when explicit subscriptionRejected
                         namespace re/Castor/
											   channelName re/RequestInfo/
    pre {
		  backChannel = event:attr("backChannel");

			// Convert from map to array
			requestArray = ent:intentRequest.keys().map(function(a) { ent:intentRequest{a} });

			// find matching info request
			myRequest = requestArray.filter(function(a) {
			  (a{"backChannel"} eq backChannel)
			}).head();

			thingChannel = myRequest{"thingChannel"};
		}
		always {
		  set ent:intentRequest{[thingChannel, "status"]} "rejected";
		}
	}

  // ------------------------------------------------------------------------
	// respond to an unsubscribe

	rule castor_subscriptionInfoRequest_Removed {
	  select when explicit CloudOS_subscriptionRemoved
                        namespace re/Castor/
											  channelName re/RequestInfo/
    pre {
		  backChannel = event:attr("backChannel");

			// Convert from map to array
			requestArray = ent:intentRequest.keys().map(function(a) { ent:intentRequest{a} });

			// find matching info request
			myRequest = requestArray.filter(function(a) {
			  (a{"backChannel"} eq backChannel)
			}).head();

			thingChannel = myRequest{"thingChannel"};
		}
		always {
		  clear ent:intentRequest{thingChannel};
		}
	}

	// ========================================================================
	// BUY RULES
	// 
	// ent:buyOffers
	//   thingChannel : {
	//     thingChannel
	//     sellChannel
	//     thingName
	//     castID
	//     status
	//   }

  // ------------------------------------------------------------------------
	rule castor_buy_offer {
	  select when web cloudAppAction action re/^buyThing$/
		pre {
		  thingChannel = event:attr("thingID");
			castID  = event:attr("castID");

			// harvest the thing for map of intentCast
			resultArray = ent:intentCast{[castID,"castResult"]}.decode();
			castThing = resultArray.filter(function(x) {
			  (x{"thingChannel"} eq thingChannel)
			}).head();

			thingName   = castThing{"thingName"};
			thingOwner  = castThing{"thingOwner"};
			thingPrice  = castThing{"thingPrice"};
			sellChannel = castThing{"backChannel"};

			// --------------------------------------------
			buyOffer = {
			  "thingChannel" : thingChannel,
				"sellChannel"  : sellChannel,
				"thingName"    : thingName,
				"castID"       : castID,
			  "status"       : "offer"
			};

			// --------------------------------------------
			// send buy offer to seller

			event_map = {
			      "cid" : sellChannel
			};

			buyerName    = pds:get_me('myProfileName');
			buyerPhoto   = pds:get_me('myProfilePhoto');
			buyerChannel = pds:get_me('myDoorbell');
		}
		{
		  // notify("Buy Thing", thingChannel) with sticky = true;

		  event:send(event_map, "explicit", "newBuyOffer")
			  with attrs = {
				  "thingChannel" : thingChannel,
				  "buyerChannel" : buyerChannel,
				  "buyerName"    : buyerName,
				  "buyerPhoto"   : buyerPhoto
				};

		  cloudUI:hideSpinner();
		}
		always {
		  set ent:buyOffers{thingChannel} buyOffer;
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Buy Offer Sent"
				and  description = "Offer to buy " + thingName + " for $" + thingPrice + " sent to " + thingOwner
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_buyOfferAccepted {
	  select when explicit buyOfferAccepted
		pre {
		  thingChannel = event:attr("thingChannel");
			sellerName   = event:attr("sellerName");
			sellerPhoto  = event:attr("sellerPhoto");

			// harvest the thing for map of intentCast
			castID = ent:buyOffers{[thingChannel, "castID"]};
			resultArray = ent:intentCast{[castID,"castResult"]}.decode();
			castThing = resultArray.filter(function(x) {
			  (x{"thingChannel"} eq thingChannel)
			}).head();

			thingName   = castThing{"thingName"};
			thingOwner  = castThing{"thingOwner"};
			thingPrice  = castThing{"thingPrice"};
		}
		always {
		  set ent:buyOffers{[thingChannel, "status"]} "accepted";
		  set ent:buyOffers{[thingChannel, "sellerName"]} sellerName;
		  set ent:buyOffers{[thingChannel, "sellerPhoto"]} sellerPhoto;
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Buy Offer Accepted"
				and  description = thingOwner + " accepted Offer to sell " + thingName + " for $" + thingPrice
				and  priority    = 0
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule castor_approveBuyThing {
	  select when web cloudAppAction action re/^approveBuyThing$/
		pre {
		  thingChannel = event:attr("thingChannel");

			// DEBUG
			//buyOffers = ent:buyOffers;

			sellChannel = ent:buyOffers{[thingChannel, "sellChannel"]};
			event_map = {
			      "cid" : sellChannel
			};

			// harvest the thing for map of intentCast
			castID = ent:buyOffers{[thingChannel, "castID"]};
			resultArray = ent:intentCast{[castID,"castResult"]}.decode();
			castThing = resultArray.filter(function(x) {
			  (x{"thingChannel"} eq thingChannel)
			}).head();

			thingName   = castThing{"thingName"};
			thingOwner  = castThing{"thingOwner"};
			thingPrice  = castThing{"thingPrice"};
    }
		{
		  // notify("Approve Buy Thing", thingChannel) with sticky = true;

		  event:send(event_map, "explicit", "buyTransferComplete")
			  with attrs = {
				  "thingChannel" : thingChannel
				};

			emit <<
			  $K('#castorBuyStatus-' + thingChannel).replaceWith('<h4>Funds Transferred - Purchase Complete</h4>');
				$K('#castorBuyNotificationPanel-' + thingChannel).hide();
			>>;
		  cloudUI:hideSpinner();
		}
		always {
		  clear ent:buyOffers{thingChannel};
		  raise notification event status
			  with application = "Castor"
				and  subject     = "Funds Transfer Approved"
				and  description = "Funds transfer of $" + thingPrice + " to " + thingOwner + " approved"
				and  priority    = 0
				and  _api = "sky";
		}
  }

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_resetbuy {
	  select when web cloudAppAction action re/resetbuy/
		{
		  cloudUI:hideSpinner();
		}
		always {
		  clear ent:buyOffers;
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_refresh {
	  select when web cloudAppAction action re/refresh/
		{
		  cloudUI:setHash("#!/app/"+thisRID+"/show");
		}
	}

  // ------------------------------------------------------------------------
	rule castor_cloudAppCommand_seek {
	  select when web cloudAppAction action re/seek/
		pre {
			appContent = <<
			  Seeking an you shall find ...
			>>;
		}
		{
			replace_inner("#mycloud-castor", appContent);
		  cloudUI:hideSpinner();
		}
	}

  // ------------------------------------------------------------------------
  // Beyond here there be dragons :)
  // ------------------------------------------------------------------------
}
