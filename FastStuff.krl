ruleset a169x682 {
	meta {
		name "FastStuff Broker"
		description <<
			
		>>
		author "Ed Orcutt"
		logging on

		// --------------------------------------------
		// ent:fastThings

    use module a169x625 alias CloudOS
		use module a169x664 alias cloudUI
		use module a169x676 alias pds
	}

	global {
    thisRID = meta:rid();
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_Selected {
		select when web cloudAppSelected
		pre {
		  appMenu = [
				{ "label"  : "Refresh",
				  "action" : "refresh" }
			];
		}
		{
		  // notify("faststuffBroker", "Selected, ready to load") with sticky = true;
			noop();
		}
		fired {
		  raise cloudos event appReadyToLoad
			  with appName = "FastStuff Broker"
				and  appRID  = thisRID
				and  appMenu = appMenu
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_Loaded {
	  select when explicit appLoaded
		pre {
		  appContentSelector = event:attr("appContentSelector");

			// foo = CloudOS:subscriptionList("IntentCasting", "broker");
			// oneThing = fastArray.pick("$.[?(@.thingAttributes eq 'camera')].thingChannel",true);
			// oneThing = ent:fastThings.pick("$..?(@.thingAttributes eq 'camera')");

			//fastThings = ent:fastThings;
			//fastArray = ent:fastThings.keys().map(function(a) { ent:fastThings{a}	});
			//castAttrs = "camera";
			//oneThing = fastArray.filter(function(a) {
			//  (a{"thingAttributes"} eq castAttrs)
			//});

			thingContent = ent:fastThings.keys().map(function(thingChannel) {
			  thingName  = ent:fastThings{[thingChannel, "thingName"]};
			  thingPhoto = ent:fastThings{[thingChannel, "thingPhoto"]};
			  thingPrice = ent:fastThings{[thingChannel, "thingPrice"]};
			  thingDescription = ent:fastThings{[thingChannel, "thingDescription"]};
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
					    <h3>#{thingName}</h3>
							<h4>Price: $#{thingPrice}</h4>
							<p>#{thingDescription}</p>
					  </div>
					</div>
				>>
				foo
			}).join(" ");
			appContent = "<div id='mycloud-broker'>" + thingContent + "</div>";
		}
		{
		  // notify("faststuffBroker", "Loaded, ready to show") with sticky = true;
			replace_inner(appContentSelector, appContent);
			CloudOS:skyWatchSubmit("#formAppTemplate", "");
		}
		fired {
		  raise cloudos event appReadyToShow
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_Shown {
		select when explicit appShown
		{
		  // notify("faststuffBroker", "Shown, app ready") with sticky = true;
		  cloudUI:hideSpinner();
		}
		fired {
		  raise cloudos event cloudAppReady
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_cloudAppCommand_refresh {
	  select when web cloudAppAction action re/refresh/
		{
		  cloudUI:setHash("#!/app/"+thisRID+"/show");
		}
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_add_new_thing {
	  select when explicit broker_thing_add
		pre {
		  thingChannel = event:attr("thingChannel");
		}
		fired {
		  set ent:fastThings{thingChannel} event:attrs();
		}
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_delist_thing {
	  select when explicit broker_thing_delist
		pre {
		  thingChannel = event:attr("thingChannel");
		}
		fired {
		  clear ent:fastThings{thingChannel};
		}
	}

  // ------------------------------------------------------------------------
	rule faststuffBroker_intentcast_query {
	  select when explicit broker_intentcast_query
		pre {
		  castID       = event:attr("castID");
		  castAttrs    = event:attr("castAttrs");
		  backChannel  = event:attr("eventChannel");
		  eventChannel = event:attr("backChannel");

			mymap = {
				"cid"          : eventChannel,
				"eventChannel" : eventChannel,
				"backChannel"  : backChannel
			};

			eventType = "agent_intentcast_result";

			fastArray = ent:fastThings.keys().map(function(a) { ent:fastThings{a}	});
			castResult = fastArray.filter(function(a) {
			  (a{"thingAttributes"}.lc() eq castAttrs.lc())
			});			
		}
		{
			  event:send(mymap, "explicit", eventType)
				  with attrs = {
					"castID"       : castID,
					"castAttrs"    : castAttrs,
					"castResult"   : castResult.encode(),
			    "eventChannel" : eventChannel,
			    "backChannel"  : backChannel
					};
		}
	}

  // ------------------------------------------------------------------------
	// Automatic subscription request approval

	rule AutoSubscriptionRequestApproval {
	  select when cloudos subscriptionRequestPending
		always {
		  raise cloudos event subscriptionRequestApproved
			  with eventChannel = event:attr("eventChannel")
				and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
  // Beyond here there be dragons :)
  // ------------------------------------------------------------------------
}
