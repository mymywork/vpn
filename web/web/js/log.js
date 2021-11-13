var LOGINZA = {
    providers: {
        google: {
            identity: false,
            popup: true,
            name: 'Google',
            url: 'http://google.com'
        },
        yandex: {
            identity: false,
            popup: false,
            name: '������',
            url: 'http://yandex.ru'
        },
        mailruapi: {
            identity: false,
            call: 'mailRuOAuthLogin',
            name: 'mail.ru',
            url: 'http://my.mail.ru'
        },
        vkontakte: {
            identity: false,
            call: 'oauthLogin',
            name: '���������',
            url: 'http://vkontakte.ru'
        },
        odnoklassniki: {
            identity: false,
            call: 'odnoklassnikiLogin',
            name: '�������������',
            url: 'http://www.odnoklassniki.ru'
        },
        facebook: {
            identity: false,
            call: 'fbLogin',
            name: 'Facebook',
            url: 'http://www.facebook.com'
        },
        loginza: {
            identity: false,
            popup: false,
            name: 'Loginza',
            url: 'http://loginza.ru'
        },
        twitter: {
            identity: false,
            call: 'oauthLogin',
            name: 'Twitter',
            url: 'http://twitter.com'
        },
        linkedin: {
            identity: false,
            call: 'oauthLogin',
            name: 'LinkedIn',
            url: 'http://www.linkedin.com'
        },
        livejournal: {
            identity: true,
            popup: false,
            name: '����� ������',
            url: 'http://livejournal.ru'
        },
        myopenid: {
            identity: false,
            popup: false,
            name: 'myOpenID',
            url: 'http://myopenid.com'
        },
        webmoney: {
            identity: true,
            popup: false,
            name: 'WebMoney',
            url: 'http://webmoney.ru'
        },
        rambler: {
            identity: true,
            popup: false,
            name: 'Rambler',
            url: 'http://rambler.ru'
        },
        flickr: {
            identity: false,
            popup: true,
            name: 'Flickr',
            url: 'http://flickr.com'
        },
        lastfm: {
            identity: false,
            popup: false,
            name: 'last.fm',
            url: 'http://www.last.fm'
        },
        openid: {
            identity: true,
            popup: false,
            name: 'OpenID',
            url: null
        },
        mailru: {
            identity: true,
            popup: false,
            name: 'Mail.Ru',
            url: 'http://openid.mail.ru/'
        },
        steam: {
            identity: false,
            popup: false,
            name: 'Steam',
            url: 'https://steamcommunity.com/'
        },
        aol: {
            identity: true,
            popup: true,
            name: 'Aol',
            url: 'http://aol.com'
        },
        verisign: {
            identity: false,
            popup: false,
            name: 'VeriSign',
            url: 'http://pip.verisignlabs.com'
        }
    },
    pages: null,
    sid: null,
    token_url: null,
    root_width: 0,
    selected_provider: null,
    providers_set: null,
    ajax: false,
    overlay: false,
    start: function () {
        var providers_set_len = 0;
        if (LOGINZA.providers_set != null && LOGINZA.providers_set != 'null' && LOGINZA.providers_set != '') {
            LOGINZA.providers_set = LOGINZA.providers_set.split(',');
            providers_set_len = LOGINZA.providers_set.length
        }
        LOGINZA.pages = new Array();
        if (providers_set_len > 0) {
            for (var i = 0; i < providers_set_len; i++) {
                var key = LOGINZA.providers_set[i];
                if (LOGINZA.checkProvider(key)) {
                    LOGINZA.pages[LOGINZA.pages.length] = [
                        key,
                        LOGINZA.providers[key].identity
                    ]
                }
            }
        } else {
            for (key in LOGINZA.providers) {
                LOGINZA.pages[LOGINZA.pages.length] = [
                    key,
                    LOGINZA.providers[key].identity
                ]
            }
        }
        widgetForm.log('start, loginza_last_provider: ' + $.cookie('loginza_last_provider'));
        var cookie_provider = $.cookie('loginza_last_provider');
        if (LOGINZA.selected_provider && LOGINZA.selected_provider != cookie_provider && LOGINZA.checkProvider(LOGINZA.selected_provider)) {
            LOGINZA.goProviderForm(LOGINZA.selected_provider);
            return
        } else if ((cookie_provider != '' && cookie_provider != null) && ($.cookie('loginza_' + cookie_provider + '_identity') != '' && $.cookie('loginza_' + cookie_provider + '_identity') != null) && ($.cookie('loginza_' + cookie_provider + '_fullname') != '' && $.cookie('loginza_' + cookie_provider + '_fullname') != null)) {
            if (LOGINZA.providerAllow(cookie_provider)) {
                LOGINZA.setProvider(cookie_provider);
                widgetForm.showProviderReady($.cookie('loginza_last_provider'), $.cookie('loginza_' + cookie_provider + '_identity'), decodeURIComponent($.cookie('loginza_' + cookie_provider + '_fullname')));
                return
            }
        }
        widgetForm.showProviders()
    },
    providerAllow: function (provider) {
        for (var i = 0; i < LOGINZA.pages.length; i++) {
            if (LOGINZA.pages[i][0] == provider) {
                return true
            }
        }
        return false
    },
    checkProvider: function (provider) {
        for (key in LOGINZA.providers) {
            if (provider == key) return true
        }
        return false
    },
    resetImmediateResult: function () {
        widgetForm.log('called resetImmediateResult');
        LOGINZA.resetProvider();
        widgetForm.showProviders()
    },
    checkPopupResult: function (identity) {
        widgetForm.log('called checkPopupResult');
        if (typeof identity == undefined || identity == '') {
            widgetForm.showProviders()
        } else {
            widgetForm.log('pre called showProviderReady(' + LOGINZA.selected_provider + ', ' + identity + ')');
            LOGINZA.redirect('/api/redirect?rnd=' + Math.random())
        }
    },
    setProvider: function (provider) {
        widgetForm.log('called setProvider(' + provider + ')');
        if (provider != '' && provider != undefined) {
            widgetForm.setProviderLogo(provider)
        }
        LOGINZA.selected_provider = provider;
        $.cookie('loginza_last_provider', provider)
    },
    resetProvider: function () {
        widgetForm.log('called resetProvider');
        LOGINZA.setProvider('')
    },
    goProviderForm: function (provider) {
        if (typeof provider == 'object') {
            provider = provider.data.provider
        }
        widgetForm.log('called goProviderForm for ' + provider);
        LOGINZA.setProvider(provider);
        widgetForm.showProviderProperty(provider, $.cookie('loginza_' + provider + '_identity'));
    },
    gotoProviderSignIn: function (identity) {
        var url;
        widgetForm.log('called gotoProviderSignIn');
        if (typeof identity == 'object') {
            identity = ''
        }
        if (LOGINZA.require_identity(LOGINZA.selected_provider) && identity == '') {
            widgetForm.errorMessage('������� ����� ����� ������� ������!')
        } else {
            if (LOGINZA.providers[LOGINZA.selected_provider].call != undefined) {
                LOGINZA[LOGINZA.providers[LOGINZA.selected_provider].call]()
            } else {
                url = '/api/discovery?provider=' + encodeURIComponent(LOGINZA.selected_provider) + '&identity=' + encodeURIComponent(identity) + '&token_url=' + encodeURIComponent(LOGINZA.token_url);
                widgetForm.log('called gotoProviderSignIn for ' + url);
                widgetForm.showSmallLoading();
                $.cookie('loginza_' + LOGINZA.selected_provider + '_identity', identity);
                if (LOGINZA.providers[LOGINZA.selected_provider].popup) {
                    widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width)
                } else {
                    if (LOGINZA.selected_provider == 'lastfm') {
                        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 950, 590)
                    } else if (LOGINZA.selected_provider == 'steam') {
                        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 1000, 590)
                    } else {
                        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 800, 600)
                    }
                }
            }
        }
    },
    require_identity: function (provider) {
        if (!provider || provider == 'null') {
            return false
        } else {
            return LOGINZA.providers[provider].identity
        }
    },
    redirect: function (url) {
        if (LOGINZA.ajax) {
            document.location = '/api/redirect?ajax=1&rnd=' + Math.random()
        } else {
            if (typeof url == 'object') {
                parent.location = url.data.url
            } else {
                parent.location = url
            }
        }
    },
    newUser: function () {
        LOGINZA.setProvider('loginza');
        widgetForm.popupOpen('/reg.php?mode=popup&token_url=' + encodeURIComponent(LOGINZA.token_url), LOGINZA.root_width, 500, 570)
    },
    fbLogin: function () {
        var url = '/api/discovery?provider=' + encodeURIComponent(LOGINZA.selected_provider) + '&token_url=' + encodeURIComponent(LOGINZA.token_url);
        widgetForm.showLoading();
        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 500, 500)
    },
    oauthLogin: function () {
        var url = '/api/discovery?provider=' + encodeURIComponent(LOGINZA.selected_provider) + '&token_url=' + encodeURIComponent(LOGINZA.token_url);
        widgetForm.showLoading();
        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 800, 500)
    },
    mailruApiLogin: function () {
        var url = '/api/discovery?provider=' + encodeURIComponent(LOGINZA.selected_provider) + '&token_url=' + encodeURIComponent(LOGINZA.token_url);
        widgetForm.showLoading();
        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 540, 500)
    },
    mailRuOAuthLogin: function () {
        var url = '/api/discovery?provider=' + encodeURIComponent(LOGINZA.selected_provider) + '&token_url=' + encodeURIComponent(LOGINZA.token_url);
        widgetForm.showLoading();
        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 540, 500)
    },
    odnoklassnikiLogin: function () {
        var url = '/api/discovery?provider=' + encodeURIComponent(LOGINZA.selected_provider) + '&token_url=' + encodeURIComponent(LOGINZA.token_url);
        widgetForm.showLoading();
        widgetForm.popupOpen(url + '&mode=popup', LOGINZA.root_width, 580, 350)
    }
};
var widgetForm = {
    popupInterval: null,
    popupWindow: null,
    countCells: 9,
    countFootCells: 9,
    page: 1,
    footPage: 1,
    logerKey: 0,
    popupOpen: function (url, screen_width, width, height) {
        if (!width) {
            width = 450
        }
        if (!height) {
            height = 500
        }
        var left = (screen_width / 2) - (width / 2);
        widgetForm.popupWindow = window.open(url, 'loginzaPopup', 'left=' + left + ',width=' + width + ',height=' + height + ',location=1,toolbar=0,menubar=0,status=0,scrollbars=0,resizable=1');
        if (widgetForm.popupWindow == null) {
            alert('Please unlock popup window!')
        } else {
            widgetForm.popupInterval = setInterval(widgetForm.popupClosed, 650);
            widgetForm.popupWindow.focus()
        }
    },
    popupClosed: function (scriptClose) {
        if (widgetForm.popupWindow.closed || scriptClose) {
            clearInterval(widgetForm.popupInterval);
            widgetForm.hideSmallLoading();
            if (!$('#loading').is(':hidden')) {
                widgetForm.showProviderProperty(LOGINZA.selected_provider)
            }
        }
    },
    showNextProviders: function () {
        this.pageController(1);
        this.showProviders()
    },
    showPrevProviders: function () {
        this.pageController( - 1);
        this.showProviders()
    },
    pageController: function (delta) {
        var max_page = Math.ceil(LOGINZA.pages.length / widgetForm.countCells);
        var next_val = widgetForm.page + delta;
        if (next_val <= max_page && next_val >= 1) {
            widgetForm.page = next_val;
            widgetForm.log('pageSet(' + next_val + ')')
        }
        if (widgetForm.page >= max_page) {
            $('#providers_list span.next').hide()
        } else {
            $('#providers_list span.next').show()
        }
        if (widgetForm.page <= 1) {
            $('#providers_list span.prev').hide()
        } else {
            $('#providers_list span.prev').show()
        }
    },
    showLoginzaLogin: function () {
        $('#loginza_login').show();
        $('#providers_list').hide();
        $('#provider_ready').hide();
        $('#provider_property').hide();
        $('#provider_redirect').hide();
        widgetForm.hideLoading()
    },
    showProviders: function () {
        if (LOGINZA.pages.length <= this.countCells) {
            $('span.next').hide()
        }
        $('#providers_list .providers_set').html('');
        for (var i = 0; i < 9; i++) {
            index = i + (widgetForm.page - 1) * widgetForm.countCells;
            if (LOGINZA.pages[index] != undefined) {
                var t = $('#providers_list .providers_set').append('<div class="provider" title="' + LOGINZA.providers[LOGINZA.pages[index][0]].name + '"><div class="providers_sprite ' + LOGINZA.pages[index][0] + '"></div></div>');
                $('.' + LOGINZA.pages[index][0], t).bind('click', {
                    provider: LOGINZA.pages[index][0]
                }, LOGINZA.goProviderForm)
            }
        }
        $('#providers_list').show();
        $('#loginza_login').hide();
        $('#provider_ready').hide();
        $('#provider_property').hide();
        $('#provider_redirect').hide();
        widgetForm.hideLoading()
    },
    showContinueForm: function (identity, fullname) {
        widgetForm.showProviderReady(LOGINZA.selected_provider, identity, fullname, true)
    },
    showProviderReady: function (provider, identity, fullname, continueFrom) {
        if (fullname) {
            $('#provider_ready .welcome_message .full_name').show();
            $('#provider_ready .welcome_message .full_name > b').html(widgetForm.getProviderIcoHtml(provider) + '&nbsp;' + fullname);
            $('#provider_ready #identity').html(identity)
        } else {
            $('#provider_ready .welcome_message .full_name').hide();
            $('#provider_ready #identity').html(identity).attr('style', 'font-size:14pt;')
        }
        if (continueFrom) {
            $('.welcome_continue').show();
            $('.welcome_again').hide();
            $('#provider_ready .bigButton > input[type="button"]').unbind('click').bind('click', {
                url: '/api/redirect?rnd=' + Math.random()
            }, LOGINZA.redirect);
            if (LOGINZA.overlay && !LOGINZA.ajax) {
                if (window.addEventListener) {
                    parent.window.postMessage('redirect', LOGINZA.token_url)
                } else {
                    window.parent.postMessage('redirect', LOGINZA.token_url)
                }
            } else {
                LOGINZA.redirect('/api/redirect?rnd=' + Math.random())
            }
        } else {
            $('.welcome_continue').hide();
            $('.welcome_again').show();
            $('#provider_ready .bigButton > input[type="button"]').unbind('click').bind('click', LOGINZA.gotoProviderSignIn)
        }
        $('#provider_ready').show();
        $('#loginza_login').hide();
        $('#providers_list').hide();
        $('#provider_property').hide();
        $('#provider_redirect').hide();
        widgetForm.hideLoading()
    },
    showProviderProperty: function (provider, identity) {
        if (identity) {
            $('#openid_identity').val(identity)
        } else {
            $('#openid_identity').val('')
        }
        if (LOGINZA.require_identity(provider)) {
            $('#provider_property').show();
            $('#provider_redirect').hide()
        } else {
            $('#provider_redirect').show();
            $('#provider_property').hide()
        }
        $('#loginza_login').hide();
        $('#provider_ready').hide();
        $('#providers_list').hide();
        widgetForm.hideLoading()
    },
    setProviderLogo: function (provider) {
        $('.trust_domain .providers_ico_sprite').removeClass().addClass('providers_ico_sprite').addClass(provider + '_ico');
        $('.provider_name').text(LOGINZA.providers[provider].name);
        $('.providerIco').html(LOGINZA.providers[provider].name)
    },
    getProviderIcoHtml: function (provider) {
        widgetForm.log('call getProviderIcoHtml for ' + provider);
        return '<span class="providers_ico_sprite ' + provider + '_ico">&nbsp;</span>';
    },
    showLoading: function () {
        $('#loading').show();
        $('#loginza_login').hide();
        $('#provider_ready').hide();
        $('#providers_list').hide();
        $('#provider_property').hide();
        $('#provider_redirect').hide()
    },
    showSmallLoading: function () {
        $('.bigButton > input.bigButton').hide();
        $('.bigButton > div.loading_anim_s').show()
    },
    hideSmallLoading: function () {
        $('.bigButton > input.bigButton').show();
        $('.bigButton > div.loading_anim_s').hide()
    },
    hideLoading: function () {
        $('#loading').hide()
    },
    hideLoadingAndShow: function (show_page) {
        widgetForm.hideLoading();
        $('#' + show_page).show()
    },
    errorMessage: function (message) {
        $('.errorBox div').html(message);
        $('.errorBox').show();
        $('.errorMsg').show().delay(800).fadeOut(2200)
    },
    log: function (message) {
        $('#log').text('>: ' + message + '\r\n' + $('#log').text())
    }
};
var ifr = {
    timeout: null,
    load: function (url, show_after, callback, obj_params) {
        widgetForm.log('iframe loading START');
        ifr.loadingStart();
        $('#ifrRes').bind('load', {
            show_after: show_after,
            callback: callback,
            obj_params: obj_params
        }, ifr.loadingEnd);
        $('#ifrRes').attr({
            src: url
        });
        ifr.timeout = setInterval(ifr.loadingEnd, 5000)
    },
    loadingStart: function () {
        widgetForm.showLoading()
    },
    loadingEnd: function (event) {
        widgetForm.log('iframe loading END');
        clearInterval(ifr.timeout);
        if (typeof event != 'undefined') {
            event.data.callback(event.data.obj_params)
        }
        if (typeof event != 'undefined') {
            widgetForm.hideLoadingAndShow(event.data.show_after)
        } else {
            widgetForm.showProviders()
        }
    },
    getIframeDocument: function (iframeNode) {
        if (iframeNode.contentDocument) return iframeNode.contentDocument;
        if (iframeNode.contentWindow) return iframeNode.contentWindow.document;
        return iframeNode.document
    },
    getVar: function (input_id) {
        var iframe = ifr.getIframeDocument(document.getElementById('ifrRes'));
        return $(iframe).find('#' + input_id).attr('value')
    }
};
$(document).ready(function () {
    LOGINZA.start();
    $(document).bind('keydown', function (e) {
        if (e.keyCode == 76) {
            widgetForm.logerKey = 1
        }
    });
    $(document).bind('keyup', function (e) {
        if (e.keyCode == 76) {
            widgetForm.logerKey = 0
        }
    });
    $('.poweredby').bind('click', function () {
        if (widgetForm.logerKey == 1) {
            $('#log').show()
        }
    });
    $('#log').bind('keydown', function (e) {
        if (e.keyCode == 27 && $('#log').is(':visible')) {
            $('#log').hide()
        }
    })
});
