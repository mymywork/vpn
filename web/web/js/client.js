
var client = new function () {
	var self = this;
	
	self.ready = function() {
		$(".tab").click(self.tab_click);
		self.scrollfix();
	};

	self.tab_click = function (item) {
		$(".tab-line-default").removeClass("tab-line-active");
		$(".tab").removeClass("tab-active");

		var tab = $(item.currentTarget);

		tab.addClass("tab-active");
		tab.prev().addClass("tab-line-active");
		tab.next().addClass("tab-line-active");

		$(".tabbody").addClass("hide");
		var tabbody = $("."+tab.attr("tabclass"));
		tabbody.removeClass("hide");	

		return false;
	}
	self.scrollfix = function() {

		var e = $("body");

		if ($(document).height() > $(window).height()) {
			e.width(e.width()-17);
		}	
	}


}

$(document).ready(client.ready);
