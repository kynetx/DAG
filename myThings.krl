
ruleset a169x667 {
	meta {
		name "myThings"
		description <<

		>>
		author "Jessie A. Morris"
		logging on

		use module a169x664 alias CloudUI
		use module a169x625 alias CloudOS

		key accounts {
			"key": "REDACTED"
		}
	}

	global {
		/** ent:myThings
		 * An entity variable (hash) which contains thing information
		 * keyed off of the ECI.
		 * Example:
		 * 
		 *		"ab1235ba-123b5b15c12356-12c356d12356c231d123": {
		 *			"thingName": "test thing name",
		 *			"thingTag": "abcode34no",
		 *			"thingPhoto": null
		 *		}
		 * }
		 */


		defaultThing = {
			"thingName": "",
			"thingTag": "",
			"thingDescription": "",
			"thingAttributes": "",
			"thingPhoto": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAJwAAACcCAMAAAC9ZjJ/AAAAAXNSR0IArs4c6QAAAG9QTFRF29vb/Pz8/v7+/f39+/v7+vr68fHx8vLy+fn58/Pz9fX19vb29PT08PDw+Pj49/f3////7+/v7u7u7e3t7Ozs6+vr3Nzc4uLi5+fn6urq4ODg5eXl6enp4+Pj5ubm3t7e39/f6Ojo4eHh3d3d5OTk7uBouAAAAAlwSFlzAAALEwAACxMBAJqcGAAAAAd0SU1FB9wIFREAKaHJy7MAAAL7SURBVHja7dppc6JAEIfx3ktESVw5hkMOEb//Z1yqUm4Z12P6D/T0puZ5n/SvEBnAod+KI4/7krjvivM4j/M4j5sD90NxHudxHudxc+C+Kc7jPM7jPG4O3E/FeZzH/a+4dXgY6NKQ7BThdjXdVKzWM+B+TW5b0IPqLNlO+c8z4Aw9K3CJo5dFrnBR9RpnIje4nqxygmvtbPB5NwH3XpFtnTjO3jaedyWEW6O1xCoERsC4kpglcrgdscvEcDkfR3shnCGkswyOsERwG8U41Ea9AK5FcYaJewciuJo3RxaXL4474DhaHNcpxmWkGJdrxpEcbsduEo43yeM8bjKu04yrNeNi3qQtuwm2hjlJFJcsjpuw7m8Xx5WacQFsq5bHbeF7pkgAF8l8VyFcBN6mm60ArhM640bchtsKX1i5o/i4GL+SLI8LYdtpedwGvyVRjDtuBHCd1IFDcD2IyzTjej4uYncCcQV70lfDvaG3wRK46AzeMIngItU46CcSI4QrZb4PEYVICXvpygNgDIYLE+brTWwK+Gdh6HEed9SMKzTjSnBGAMa6loAzYFzNOeWkcUHDeHoQxzGWsEQcFyx+yn1ZnPUuMOMAV1j/sA/jVni2OzhidMAU3N7ypeHKBc7yNWLqBnde9sBNw1k9hRVucJYLWOMCZ724NuK4PWMnboni3sAGzsN+is0AcdxXr6UcLubvGDoL4Q7YVtdBABfDu+eGQ7workRfuWKfLgvX0+RYR4/2tp0NzdLQW4+0xaU5zdYhmw2X9tVAi2SqNpuE6xtaNFMkIK4ikQYAVwrZRl3BxaUkWMnCidIe8R7gSiONo+YOLr5XTg7q0lsGqbGNlxUbnCPbqMte4pzZxk/2Fa4mhzXPcalxiaP+KY4c98mSfC5zjWuvMDe4npyXP8Qd3eOofIQjDT3A1YpxmVGBa+/iWhU2qu7iSEmXQ0fpVVpwp4tHI85oxtEdXKEZ12jGHTXjOjW44l8cqcNlf6v14JoP0RWu0Iw76MEdP0R/AEhZCR2ukRMcAAAAAElFTkSuQmCC"
		};


		thisRID = meta:rid();
	}

	// ------------------------------------------------------------------------
	rule myThings_cloudAppSelected {
		select when web cloudAppSelected
		pre {
			appMenu = [
				{
					"label"  : "Add New Thing",
					"action" : "showCreateNewThing"
				}
			];
		}
		{
			//notify("myThings_cloudAppSelected", "Cloud App Selected") with sticky = true;
			noop();
		}
		fired {
			raise cloudos event appReadyToLoad
				with appName = "myThings"
				and  appRID  = thisRID
				and  appMenu = appMenu
				and  _api = "sky";
		}
	}

	// ------------------------------------------------------------------------
	rule myThings_cloudAppLoaded {
		select when explicit appLoaded
		{
			//notify("myThings_cloudAppLoaded", "Cloud App Loaded") with sticky = true;
			noop();
		}
		fired {
			raise cloudos event appReadyToShow
				with appRID  = thisRID
				and  _api = "sky";
		}
	}

	// ------------------------------------------------------------------------
	rule myThings_appShown {
		select when explicit appShown
		pre {
			appContentSelector = event:attr("appContentSelector");
			myThings = ent:myThings;

			thingList = ent:myThings.keys().map(
				function(doorbell) {

					thingName  = ent:myThings{[doorbell,"thingName"]};
					thingTag = ent:myThings{[doorbell,"thingTag"]};
					thingPhoto = ent:myThings{[doorbell,"thingPhoto"]};
					backChannel  = ent:myThings{[doorbell,"backChannel"]};
					authChannel  = ent:myThings{[doorbell,"authChannel"]};

					thisThing = <<
						<li class="span2">
							<div class="thumbnail mycloud-thumbnail">
								<a href="#!/app/#{thisRID}/showInfo&backChannel=#{backChannel}">
									<img src="#{thingPhoto}" alt="#{thingName}">
								</a>
								<h5 class="cloudUI-center">#{thingName}</h5>
								<div class="btn-toolbar">
									<div class="btn-group mycloud-btn-nav" style="display:none;">
										<button data-toggle="dropdown" class="btn btn-mini dropdown-toggle"><span class="icon-cog"></span> <span class="caret"></span></button>
										<ul class="dropdown-menu">
											<li><a href="#!/app/#{thisRID}/unsubscribe&backChannel=#{backChannel}">Unsubscribe</a></li>
											<li><a href="#!/become/#{authChannel}">Become</a></li>
											<li><a href="#!/app/#{thisRID}/showInfo&backChannel=#{backChannel}">Show Info</a></li>
											<li><a href="#!/app/#{thisRID}/sellme&backChannel=#{backChannel}">Sellme</a></li>
										</ul>
									</div>  <!-- /btn-group -->
								</div>  <!-- .btn-toolbar -->
							</div>  <!-- .thumbnail -->
						</li>
					>>;
					thisThing

				}
			).join(" ");

			thingGallery = <<
				<ul class="thumbnails mycloud-thumbnails">
					#{thingList}
				</ul>
			>>;
		}
		{
			replace_inner(appContentSelector, thingGallery);
			//notify("myThings_cloudAppShown", "Showing Thing Gallery") with sticky = true;
			CloudUI:hideSpinner();
		}
		fired {
			set ent:appContentSelector appContentSelector;
			raise cloudos event cloudAppReady
				with appRID  = thisRID
				and  _api = "sky";
		}
	}

	// ========================================================================
	// myThings Things
	// 
	// ent:myThings {
	//    "backChannel" : {
	//      "thingName"   : ,
	//      "thingTag"   : ,
	//      "thingPhoto"  : ,
	//      "eventChannel"  : ,
	//      "backChannel"   : 
	//    }
	// }
	// 
	// ========================================================================

	// ------------------------------------------------------------------------
	rule myThings_subscriptionUpdate {
		select when explicit myThings_master_thing_subscriptionUpdate
		pre {
			eventChannel = event:attr("eventChannel");
			backChannel  = event:attr("backChannel");
			thingName  = event:attr("thingName");
			thingTag = event:attr("thingTag");
			thingDescription = event:attr("thingDescription");
			thingAttributes = event:attr("thingAttributes");
			thingPhoto = event:attr("thingPhoto");
			thingEmail = event:attr("thingEmail");
			thingPassword = event:attr("thingPassword");
			authChannel = event:attr("authChannel");

			// --------------------------------------------
			// build user profile to whom we subscribed

			thingProfile = {
				"thingName"  : thingName,
				"thingTag" : thingTag,
				"thingDescription" : thingDescription,
				"thingAttributes" : thingAttributes,
				"thingPhoto" : thingPhoto,
				"thingEmail" : thingEmail,
				"thingPassword" : thingPassword,
				"authChannel" : authChannel,
				"eventChannel" : eventChannel,
				"backChannel"  : backChannel
			};
		}
		fired {
			set ent:myThings{backChannel} thingProfile;
		}
	}

	// -----------------------------------------------------------------------
	rule myThings_showCreateNewThing {
		select when web cloudAppAction action re/showCreateNewThing/
		pre {
			appContentSelector = ent:appContentSelector;
			thingPhoto = defaultThing{"thingPhoto"};

			createNewForm = <<
				<form id="createNewThing" class="form-horizontal">
					<fieldset>
						<div class="control-group">
							<label class="control-label" for="thingName">Name</label>
							<div class="controls">
								<input type="text" name="thingName" value="#{thingName}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingTag">Tag</label>
							<div class="controls">
								<input type="text" name="thingTag" value="#{thingTag}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingDescription">Description</label>
							<div class="controls">
								<input type="text" name="thingDescription" value="#{thingDescription}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingAttributes">Attributes</label>
							<div class="controls">
								<input type="text" name="thingAttributes" value="#{thingAttributes}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="myThingPhotoPreview">Photo</label>
							<div class="controls">
								<img id="myThingPhotoPreview" src="#{thingPhoto}" class="mycloud-photo-preview" alt="">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingPhoto"></label>
							<div class="controls">
								<input type="file" id="thingPhotoFile" onchange="KOBJ.a169x667.loadPhotoPreview(this)">
								<input type="hidden" id="thingPhoto" name="thingPhoto" value="#{thingPhoto}">
								<!-- <input type="text" name="myThingPhoto"> -->
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
			replace_inner(appContentSelector, createNewForm);
			CloudUI:hideSpinner();


			emit <|
				$K(":file").filestyle({
				  textField: false,
					icon: true
				});


				KOBJ.a169x667.loadPhotoPreview = function(input) {
					if (input.files && input.files[0]) {
						var reader = new FileReader();

						reader.onload = function (e) {
							$K('#myThingPhotoPreview')
								.attr('src', e.target.result);
							$K('#thingPhoto')
								.val(e.target.result);
						};

						reader.readAsDataURL(input.files[0]);
					}
				}			

				$K('#createNewThing').submit(function(event) {
					var _form = '#createNewThing';
					var _token = KOBJ.skyNav.sessionToken;
					var _postlude = 'createNewThingPostlude';
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
						// Now call the postlude
						var dom = 'web';
						var type = 'createNewThingPostlude';
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
			|>;
		}
	}

	rule myThings_createNewThing_storeDetailsTemporary {
		select when web submit "#createNewThing"
		fired {
			set ent:tempCreateThingDetails event:attrs()
		}
	}

	rule myThings_createNewThing {
		select when web createNewThingPostlude
		pre {

			// The characters in these strings (which get turned into arrays)
			// determine the valid characters for the generated email and password
			possibleEmailCharacters = 'abcdefghijklmnopqrstuvwxyz1234567890'.split(re##);
			possiblePasswordCharacters = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!@#%^*()[]<>"|?.,;'.split(re##);

			// The length of these strings (which get turned into arrays) determine
			// how long the generated email and password will be.
			emailArray = '000000000000000000000000000000000000'.split(re##);
			passwordArray = '000000000000000000000000000000000000'.split(re##);



			thingName = ent:tempCreateThingDetails{"thingName"} || defaultThing{"thingName"};
			thingTag = ent:tempCreateThingDetails{"thingTag"} || defaultThing{"thingTag"};
			thingDescription = ent:tempCreateThingDetails{"thingDescription"} || defaultThing{"thingDescription"};
			thingAttributes = ent:tempCreateThingDetails{"thingAttributes"} || defaultThing{"thingAttributes"};
			thingPhoto = ent:tempCreateThingDetails{"thingPhoto"} || defaultThing{"thingPhoto"};




			password = passwordArray.map(
				function(item){
					possiblePasswordCharacters[math:random(possiblePasswordCharacters.length())]
				}
			).join("");



			email = emailArray.map(
				function(item){
					possibleEmailCharacters[math:random(possibleEmailCharacters.length())]
				}
			).join("") + "@kynetx.com";

			penAuth    = CloudOS:cloudCreate(email, password, keys:accounts("key"));
			authStatus = penAuth{"status"};
			authChannel  = penAuth{"token"};

			thingProfile = {
				"thingName"  : thingName,
				"thingTag" : thingTag,
				"thingDescription" : thingDescription,
				"thingAttributes" : thingAttributes,
				"thingPhoto" : thingPhoto,
				"authChannel" : authChannel,
				"thingEmail" : email,
				"thingPassword" : password
			};
			
		}

		if (authStatus) then {
			noop();
		}

		fired {
			set ent:myThings{authChannel} thingProfile;

			raise explicit event createThingSuccess for thisRID
				with SkySessionToken = authChannel;


			raise notification event status
				with application = "myThing"
				and  subject     = "New thing #{thingName} created"
				and  description = "You have created a new thing named #{thingName}"
				and  priority    = 0
				and  _api = "sky";


		} else {
			raise explicit event createThingFailure for thisRID
				with penAuth = penAuth;
		}
	}


	rule myThings_creationFailed {
		select when explicit createThingFailure
		pre {
			message = <<
				Creation of new thing failed, please try again.
			>>;
		}
		{
			alert(message);
		}
	}


	rule myThings_subscribeAfterCreation { // Should install apps into the things cloud
		select when explicit createThingSuccess
		pre {
			authChannel = event:attr("SkySessionToken");

			apps = [
				"a41x172",
				"a169x667",
				"a169x669",
				"a169x664",
				"a169x625",
				"a169x676",
				"a16x161"
			];

			appsInstalled = apps.map(
				function(appId){
					CloudOS:rulesetAdd(appId, authChannel)
				}
			);

			myThing = ent:myThings{authChannel};

			cid = {
				"cid": authChannel
			};
		}
		{
			event:send(cid, "myThing", "created") with
				attrs = myThing;
			CloudUI:setHash("/app/"+thisRID+"/show");
		}

		always {
			clear ent:myThings{authChannel};
			raise system event subscribe
				with namespace = "myThings"
				and  channelName = "thing"
				and  relationship = "master-slave"
				and  targetChannel = authChannel
				and  _api = "sky";
		}
	}

	// -----------------------------------------------------------------------
	rule myThings_showInfo {
		select when web cloudAppAction action re/showInfo/
		pre {
			backChannel = event:attr("backChannel");

			appContentSelector = ent:appContentSelector;
			thingProfile = ent:myThings{backChannel};

			thingName = thingProfile{"thingName"};
			thingEmail = thingProfile{"thingEmail"};
			thingPassword = thingProfile{"thingPassword"};
			thingTag = thingProfile{"thingTag"};
			thingDescription = thingProfile{"thingDescription"};
			thingAttributes = thingProfile{"thingAttributes"};
			thingPhoto = thingProfile{"thingPhoto"};

			updateThingForm = <<
				<form id="thingUpdateForm" class="form-horizontal">
					<fieldset>
						<div class="control-group">
							<label class="control-label" for="thingName">Name</label>
							<div class="controls">
								<input type="text" name="thingName" value="#{thingName}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingTag">Tag</label>
							<div class="controls">
								<input type="text" name="thingTag" value="#{thingTag}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingDescription">Description</label>
							<div class="controls">
								<input type="text" name="thingDescription" value="#{thingDescription}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingAttributes">Attributes</label>
							<div class="controls">
								<input type="text" name="thingAttributes" value="#{thingAttributes}">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label">Email</label>
							<div class="controls">
								<input type="text" value="#{thingEmail}" disabled>
							</div>
						</div>
						<div class="control-group">
							<label class="control-label">Password</label>
							<div class="controls">
								<input type="text" value="#{thingPassword}" disabled>
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="myThingPhotoPreview">Photo</label>
							<div class="controls">
								<img id="myThingPhotoPreview" src="#{thingPhoto}" class="mycloud-photo-preview" alt="">
							</div>
						</div>
						<div class="control-group">
							<label class="control-label" for="thingPhotoFile"></label>
							<div class="controls">
								<input type="file" id="thingPhotoFile" onchange="KOBJ.a169x667.loadPhotoPreview(this)">
								<input type="hidden" id="thingPhoto" name="thingPhoto" value="#{thingPhoto}">
								<input type="hidden" id="backChannel" name="backChannel" value="#{backChannel}">
								<!-- <input type="text" name="myThingPhoto"> -->
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
			replace_inner(appContentSelector, updateThingForm);
			CloudUI:hideSpinner();


			emit <|
				$K(":file").filestyle({
				  textField: false,
					icon: true
				});


				KOBJ.a169x667.loadPhotoPreview = function(input) {
					if (input.files && input.files[0]) {
						var reader = new FileReader();

						reader.onload = function (e) {
							$K('#myThingPhotoPreview')
								.attr('src', e.target.result);
							$K('#thingPhoto')
								.val(e.target.result);
						};

						reader.readAsDataURL(input.files[0]);
					}
				}			

				$K('#thingUpdateForm').submit(function(event) {
					var _form = '#thingUpdateForm';
					var _token = KOBJ.skyNav.sessionToken;
					var _postlude = 'updateThingPostlude';
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
						// Now call the postlude
						var dom = 'web';
						var type = 'updateThingPostlude';
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
			|>;
		}
	}



	rule myThings_updateThing_storeDetailsTemporary {
		select when web submit "#thingUpdateForm"
		fired {
			set ent:tempUpdateThingDetails event:attrs()
		}
	}


	rule myThings_update {
		select when web updateThingPostlude
		pre {
			myThing = ent:tempUpdateThingDetails;
			
			toSend = {
				"thingName": myThing{"thingName"},
				"thingTag": myThing{"thingTag"},
				"thingDescription": myThing{"thingDescription"},
				"thingAttributes": myThing{"thingAttributes"},
				"thingPhoto": myThing{"thingPhoto"}
			};

			cid = {
				"cid" : myThing{"backChannel"}
			};
		}
		{
			event:send(cid, "myThing", "updated") with
				attrs = toSend;
				/*{
					"tagName" : "test"
				};*/
			CloudUI:hideSpinner();
		}
		always {
			clear ent:tempUpdateThingDetails;
		}
	}


	// ------------------------------------------------------------------------
	rule myThings_unsubscribe {
		select when web cloudAppAction action re/unsubscribe/
			pre {
				backChannel = event:attr("backChannel");
			}
		{
			//notify("myThings_unsubscribe", backChannel) with sticky = true;
			CloudUI:hideSpinner();
		}
		always {
			raise system event unsubscribe
				with backChannel = backChannel
				and  _api = "sky";
		}
	}

	// ------------------------------------------------------------------------
	rule myThings_sellme {
		select when web cloudAppAction action re/sellme/
			pre {
				backChannel = event:attr("backChannel");
				thingProfile = ent:myThings{backChannel};

				thingName = thingProfile{"thingName"};
				thingDescription = thingProfile{"thingDescription"};
				thingAttributes = thingProfile{"thingAttributes"};
				thingPhoto = thingProfile{"thingPhoto"};
			}
		{
			//notify("myThings_unsubscribe", backChannel) with sticky = true;
			CloudUI:hideSpinner();
		}
		always {
			raise explicit event thing_ready_sell
				with eventChannel		= backChannel
				and  thingName			= thingName
				and  thingDescription	= thingDescription
				and  thingAttributes			= thingAttributes
				and  thingPhoto			= thingPhoto
				and  _api = "sky";
		}
	}

	// ------------------------------------------------------------------------
	rule myThings_subscriptionRemoved {
		select when explicit CloudOS_subscriptionRemoved
			namespace re/myThings/
			channelName re/thing/
			relationship re/master/
			pre {
				eventChannel = event:attr("eventChannel");
			}
		always {
			clear ent:myThings{eventChannel};
		}
	}

	// ------------------------------------------------------------------------
	// DEBUG

	rule myThings_resetMyThings {
		select when web cloudAppAction action re/resetMyThings/
			fired {
				clear ent:myThings;
			}
	}

	// ------------------------------------------------------------------------
	// Beyond here there be dragons :)
	// ------------------------------------------------------------------------
}
