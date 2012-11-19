ruleset a169x685 {
	meta {
		name "Maintenance"
		description <<
		  myCloud Motorcycle Maintenance logs
			
      Copyright 2012 Kynetx, All Rights Reserved
		>>
		author "Ed Orcutt"
		logging on

    use module a169x625 alias CloudOS
		use module a169x664 alias cloudUI
	}

	global {
    thisRID = meta:rid();
	}

  // ------------------------------------------------------------------------
	rule motoMaint_Selected {
		select when web cloudAppSelected
		{
		  // notify("motoMaint", "Selected, ready to load") with sticky = true;
			noop();
		}
		fired {
		  raise cloudos event appReadyToLoad
			  with appName = "Motorcycle Maintenance"
				and  appRID  = thisRID
				and  appMenu = appMenu
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
	rule motoMaint_Loaded {
	  select when explicit appLoaded
		pre {
		  appContentSelector = event:attr("appContentSelector");

			appContent = <<
			  <table class="table" style="background-color:#cccccc;color:#333333;">
				  <thead>
					  <tr>
					    <th>Date</th>
					    <th>Odometer</th>
					    <th>Service</th>
					  </tr>
					</thead>
					<tbody>
					  <tr>
					    <td>August 19, 2012</td>
					    <td>10,018.0</td>
					    <td>New Oil &amp; Filter</td>
					  </tr>
					  <tr>
					    <td>August 19, 2012</td>
					    <td>10,018.0</td>
					    <td>Chain Lube</td>
					  </tr>
					  <tr>
					    <td>March 13, 2012</td>
					    <td>9,020.0</td>
					    <td>Chain Lube</td>
					  </tr>
					  <tr>
					    <td>November 1, 2011</td>
					    <td>8,700.0</td>
					    <td>New Tires</td>
					  </tr>
					</tbody>
				</table>
			>>;
		}
		{
		  // notify("motoMaint", "Loaded, ready to show") with sticky = true;
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
	rule motoMaint_Shown {
		select when explicit appShown
		{
		  // notify("motoMaint", "Shown, app ready") with sticky = true;
		  cloudUI:hideSpinner();
		}
		fired {
		  raise cloudos event cloudAppReady
				with appRID  = thisRID
			  and  _api = "sky";
		}
	}

  // ------------------------------------------------------------------------
  // Beyond here there be dragons :)
  // ------------------------------------------------------------------------
}
