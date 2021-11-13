
var frontend = new function () {
	var self = this;
	
	self.ready = function() {
		//$(".menu_right_language").hover(self.show_languages_hover);
		$(".popup_item").click(self.select_language);
	};

	self.show_languages = function (event) {


		if ( ( event.target.hasClass("menu_right_language") && event.type == "mouse_enter" ) || ( event.relatedTarget.hasClass("lang_item") && event.type == "mouse_leave" )  )
		var z = $(".popup_panel");
		var x = $(".menu_right_language");
		if ( z.hasClass("hide") ) {
			z.removeClass("hide");
			x.addClass("menu_right_language_clicked");		
		} else {
			z.addClass("hide");
			x.removeClass("menu_right_language_clicked");		
		}
	};

	self.select_language = function () {
		window.location = window.location.origin+window.location.pathname+"?lang="+$(this).attr("lang");
	}

	self.ajax_login = function (token) {
		$.post( "/site/authtoken",{ 'token':token },function( result ) {
			if ( ! result.status ) {
				
				//document.location = result.refer;

			} else {

				$(".login_bar_error").text(result.error);								
				$(".login_bar").addClass("hide");
				$(".login_bar_error").removeClass("hide");								

			}						

		},'json');
		return false;
	} 

}

$(document).ready(frontend.ready);
