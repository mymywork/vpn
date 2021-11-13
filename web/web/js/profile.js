var profile = new function () {
	var self = this;

	self.timestamp = 0;

	self.request_timeout = 3000;
	
	self.ready = function() {
		$(".profile_change").click(self.profile_change);
		$(".profile_showhide").click(self.profile_showhide);
		$(".profile_delete_social").click(self.profile_delete_social);
		$(".profile_download_cfg").click(self.profile_download_cfg);

		if ( $(".timestamp").length != 0  ) {
			self.timestamp = $(".timestamp").attr("value");
			var timehalt = $(".timestamp").attr("timehalt");
			
			if ( self.timestamp != 0 && !timehalt ) {
				setInterval(self.timer,1000);
			} else {
				self.timer();
			}
		}
	};


	self.profile_change = function (event) {
		var obj =  $(event.target);

		var chg = $(".account_change_template").clone();		
		chg.removeClass("account_change_template");
		chg.removeClass("hide");
		chg.addClass("account_change");

		var a = obj.attr("value");
		chg.find("input").val(a);

		if ( obj.hasClass("profile_change_login") ) {
			chg.find(".account_change_message").text("Change login");
		} else {
			chg.find(".account_change_message").text("Change password");
		}

		chg.find(".account_change_save").click(self.profile_change_save);
		chg.find(".account_change_cancel").click(self.profile_change_cancel);
		
		obj.after(chg);
		obj.addClass("hide");

	};

	self.profile_change_save = function (event) {
		var obj =  $(event.target);
		var chg = obj.parent().parent();
		var value = chg.find("input").val();

		var plink = chg.prev();
		var action = plink.attr("action");
		var param = plink.attr("param");

		/* show preloader */

		chg.find(".account_change_container").addClass("hidden");
		chg.find(".account_change_preloader").removeClass("hide");

		var p = {};
		p[param] = value;

		$.post(action,p,function (result) {

			if ( result.status ) {

				if ( plink.attr("value") == plink.text() ) {
					plink.text(value);
				}

				/* hide preloader and dialog */

				plink.attr("value",value);
				plink.removeClass("hide");
				chg.remove();

			} else {

				chg.find(".account_change_message").addClass("red").text(result.errors[param]);
				chg.find(".account_change_container").removeClass("hidden");
				chg.find(".account_change_preloader").addClass("hide");
			}

		},'json');
	}

	self.profile_change_cancel = function (event) {
		var obj =  $(event.target);
		var chg = obj.parent().parent();
		chg.prev().removeClass("hide");
		chg.remove();
	}

	self.profile_showhide = function (event) {
		var obj =  $(event.target);
		var chg = obj.parent();

		
		var pass = chg.parent().find(".profile_change_pass")				
		if ( pass.text() == pass.attr("value") ) {
			pass.text("***");
			obj.text("Показать")
		} else {
			pass.text(pass.attr("value"));
			obj.text("Скрыть")
		}
	
	}

	self.profile_delete_social = function (event) {
		var obj = $(event.target);
		var tr = obj.parent().parent();

		var tbl = $(".account_social > tbody");
		tbl.find("tr").remove();
		$(".account_social_preloader").removeClass("hide");


		$.post( "/site/delete_social_account",{ 'identity': tr.attr("identity") },function( result ) {
			if ( result.status ) {

				self.profile_update_social(tbl,result.socials);				

			} else {
				// show error
				$(".account_social_preloader").addClass("hide");

				var item = $(".account_social_template").find(".account_social_item_error").clone();
				item.find(".account_social_error").text("Error - "+result.error);
				tbl.append(item); 
			}						

		},'json');

		// call json		
	}

	self.profile_download_cfg = function () {

		window.open("/site/download_config");								
		
	
		/*

		$(".account_download_preloader").removeClass("hide");

		$.post( "/site/request_config",{},function( result ) {
			if ( result.status == "pending" || result.status == "requested" ) {
				setTimeout(self.profile_download_cfg, self.request_timeout);
				self.request_timeout = self.request_timeout * 2;
			} else {
				$(".account_download_preloader").addClass("hide");
				window.open("/site/download_config");								
			}						
		},'json');
		*/
	}


	self.profile_update_social = function (tbl,accounts) {
		$(".account_social_preloader").addClass("hide");

		// construct table of account	
		if ( accounts.length != 0 ) { 

			for ( var x in accounts ) {
				var item = $(".account_social_template").find(".account_social_item").clone();

				item.attr("type",accounts[x]['type']);
				item.attr("identity",accounts[x]['identity']);
				item.find("img").attr("src",accounts[x]['img']);
				item.find("span").text(accounts[x]['identity']);
				item.find("a").click(self.profile_delete_social);
			
				tbl.append(item); 
			}		
		} else {
			// show empty			
			var item = $(".account_social_template").find(".account_social_item_empty").clone();
			tbl.append(item); 
		}
	}


	self.timer =  function() {
		var allmin = self.timestamp / 60;
		var absmin = allmin - (allmin % 1);
		var sec = self.timestamp % 60;

		var allhour = absmin / 60;		
		var abshour = allhour - (allhour % 1);
		var min = absmin % 60;

		var allday = abshour / 24;
		var absday = allday - (allday % 1);
		var hour = abshour % 24;

		$(".account_timestamp").text(self.pad(hour,2)+":"+self.pad(min,2)+":"+self.pad(sec,2));		
		$(".account_timestamp_sup").text(absday+"d");		

		if ( self.timestamp ) {
			self.timestamp--;
		}
	}

	self.pad = function(num, size) {
    	var s = "000000000" + num;
    	return s.substr(s.length-size);
	}

}

$(document).ready(profile.ready);
