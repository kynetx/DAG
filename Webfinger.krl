ruleset a16x163 {
  meta {
    name "WebFinger"
    description <<
Simple app to create a connection to another personal cloud using a WebFinger ID.
>>
 
    // Copyright 2012 Kynetx, Inc. — All Rights Reserved 

    author "Phil Windley"
    logging off

    use module a169x625 alias CloudOS
    use module a169x664 alias cloudUI
    use module a169x676 alias pds
  }

  global {
    thisRID = meta:rid();
    myDivID ="WebFinger-#{thisRID}";
    myDivIDSelector ="##{myDivID}";
    webfinger_fields = <<
    <fieldset>
       <div class="control-group">
         <label class="control-label" for="webfinger_uri">WebFinger Identifier</label>
         <div class="controls">
           <input type="text" name="webfinger_uri" value=""/>
         </div>
       </div>
       <div class="form-actions">
        <button type="submit" class="btn btn-primary">Locate</button>
       </div>
     </fieldset>
   >>;
    
  }

  // ------------------------------------------------------------------------
  rule WebFinger_Selected {
    select when web cloudAppSelected
    pre {
        // appMenu = [
        //  	{ "label"  : "Refresh",
        // 		  "action" : "refresh" }
        //  ];

    }
//    {
//      notify("appTemplate", "Selected, ready to load") with sticky = true;
//    }
    always {
      raise cloudos event appReadyToLoad
	  with appName = "WebFinger"
  	   and  appRID  = thisRID
	   and  appMenu = appMenu
	   and  _api = "sky";
    }
  }

  // ------------------------------------------------------------------------
  rule WebFinger_Loaded {
    select when explicit appLoaded
    pre {
      appContent = <<
<div id="#{myDivID}">
<form id="formWebFinger" class="form-horizontal">
 <p style="margin-left:20px;margin-right:20px">
The <a target="_blank" href="http://hueniverse.com/2009/08/introducing-webfinger/">WebFinger</a> 
app allows you to locate someone's personal cloud using an WebFinger URI. 
 </p>
 <p style="margin-left:20px;margin-right:20px">
Type the email address of the person whose cloud you are trying to locate below:
 </p>
 #{webfinger_fields}
</form>
</div>
>>;
    }
    {
//     notify("appTemplate", "Loaded, ready to show") with sticky = true;
     replace_inner(event:attr("appContentSelector"), appContent);
     CloudOS:skyWatchSubmit("#formWebFinger", "");
    }
    fired {
      raise cloudos event appReadyToShow
	with appRID  = thisRID
	 and  _api = "sky";
    }
  }

  // ------------------------------------------------------------------------
  rule WebFinger_Shown {
    select when explicit appShown
    {
//     notify("appTemplate", "Shown, app ready") with sticky = true;
     cloudUI:hideSpinner();
    }
    fired {
      raise cloudos event cloudAppReady
	with appRID  = thisRID
         and  _api = "sky";
    }
  }

  // ------------------------------------------------------------------------
  rule WebFinger_formSubmit {
    select when web submit "#formWebFinger"
    pre {
      host = event:attr('webfinger_uri').extract(re#.+@(.+)$#).head();
      host_url = "http://#{host}/.well-known/host-meta.json";
      host_meta = http:get(host_url).pick("$.content").decode();
      template = host_meta.pick("$.links[?(@.rel eq 'lrdd')].href");

      acct_url = template.replace(re#\{uri\}#, "acct:#{event:attr('webfinger_uri')}");
      webfinger = http:get(acct_url).pick("$.content").decode();
      webfinger_entry = webfinger.pick("$.links[?(@.rel eq 'http://kynetx.org/rel/well-known-eci')]",true).head();
      well_known_eci = webfinger_entry{'href'};
      eci_name = webfinger_entry{'name'};

//      well_known_eci = webfinger.pick("$.links[?(@.rel eq 'http://kynetx.org/rel/well-known-eci')].href",true).head();
//      eci_name = webfinger.pick("$.links[?(@.rel eq 'http://kynetx.org/rel/well-known-eci')].name",true).head();
//      well_known_eci = webfinger.pick("$.subject");

    }
    if(webfinger_entry) then {
      noop();
      //notify("WebFinger_formSubmit", "Saw #{event:attr('webfinger_uri')}.<br/>Acct URL: #{acct_url}<br/>WEfinger return: #{webfinger}<br/>WKE: #{well_known_eci}") with sticky = true;
    }
    fired {
      raise explicit event wke_found attributes event:attrs().put({"wke": well_known_eci, "eci_name": eci_name});
 //       with acct_uri = event:attr('webfinger_uri')
 //        and appContentSelector = event:attr("appContentSelector")
 //        and wke = well_known_eci;
    } else {
      raise explicit event wke_not_found attributes event:attrs();
 //       with acct_uri = event:attr('webfinger_uri')
 //        and appContentSelector = event:attr("appContentSelector");
    }
  }
  
// ------------------------------------------------------------------------
  rule WebFinger_connect {
    select when explicit wke_found
    pre {
      appContent = <<
<form id="formConnect" class="form-horizontal">
<h2 style="margin-left:20px;margin-right:20px">Good News!</h2>
<p style="margin-left:20px;margin-right:20px">
We've located a personal cloud for <b>#{event:attr("eci_name")}</b> associated with <tt>#{event:attr("webfinger_uri")}</tt>. Click below to connect. 
</p>
<fieldset>
   <div class="control-group">
     <label class="control-label" for="relationship">Nature of relationship:</label>
     <div class="controls">
       <input type="text" name="relationship" value=""/>
    </div>
  <div class="form-actions">
    <input type="hidden" name="well_known_eci" value="#{event:attr('wke')}"/>
    <button type="submit" class="btn btn-primary">Connect</button>
  </div>
</fieldset>

</form>
      >>;
    }
    {
//     notify("WebFinger", "Found a WKE for #{event:attr('webfinger_uri')}: #{event:attr('wke')}")
//        with sticky=true;
     replace_inner(myDivIDSelector, appContent);
     CloudOS:skyWatchSubmit("#formConnect", "");
     cloudUI:hideSpinner();
    }
 }

// ------------------------------------------------------------------------
  rule WebFinger_tryagain {
    select when explicit wke_not_found
    pre {
       appContent = <<
<form id="formWebFinger" class="form-horizontal">
 <h2 style="margin-left:20px;margin-right:20px">Not Found!</h2>
 <p style="margin-left:20px;margin-right:20px">
The WebFinger URI you entered did not have an associated personal cloud. Please try again.
 </p>
 <p style="margin-left:20px;margin-right:20px">
Type the email address of the person whose cloud you are trying to locate below:
 </p>
 #{webfinger_fields}
</form>
>>;
    }    {
//      notify("WebFinger", "No WKE for #{event:attr('webfinger_uri')}")
//        with sticky=true;
      replace_inner(myDivIDSelector, appContent);
      CloudOS:skyWatchSubmit("#formWebFinger", "");
      cloudUI:hideSpinner();
    }
  }
  
// ------------------------------------------------------------------------
  rule WebFinger_subscribe {
    select when web submit "#formConnect"
    //select when web cloudAppAction action re/subscribe/
  	pre {
  	  wke = event:attr("well_known_eci");
        appContent = <<
<form id="formWebFinger" class="form-horizontal">
 <h2 style="margin-left:20px;margin-right:20px">Connected!</h2>
 <p style="margin-left:20px;margin-right:20px">
Enter another WebFinger URI to locate:
 </p>
 #{webfinger_fields}
</form>
>>;
         relationship = event:attr("relationship") || "I'd like to connect";
  	}
  	{
 	 // notify("WebFinger", "Connecting to #{wke} for #{relationship}") with sticky = true;
        replace_inner(myDivIDSelector, appContent);
        CloudOS:skyWatchSubmit("#formWebFinger", "");
        cloudUI:hideSpinner();     
  	}
  	always {
  	  raise system event subscribe
  		with namespace = "myConnections"
  	         and  channelName = "userProfile"
   		 and  targetChannel = wke
  		 and  relationship = "friend-friend"
		 and  subSummary =  relationship
		 and  profileName   = pds:get_me('myProfileName')
		 and  profilePhoto  = pds:get_me('myProfilePhoto')
  		 and  _api = "sky";
  	}
  }

  // ------------------------------------------------------------------------
     // rule myProfile_cloudAppCommand_refresh {
     //   select when web cloudAppAction action re/refresh/
     //   cloudUI:setHash("#!/app/"+thisRID+"/show");
     // }


}
