<?php
use yii\helpers\Html;


/* @var $this \yii\web\View */
/* @var $content string */

?>
<?php $this->beginPage() ?>
<!DOCTYPE html>
<html lang="<?= Yii::$app->language ?>">
<head>
    <meta charset="<?= Yii::$app->charset ?>"/>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <?= Html::csrfMetaTags() ?>
    <title><?= Html::encode($this->title) ?></title>

    <link type="text/css" rel="stylesheet" href="http://fonts.googleapis.com/css?family=Open+Sans:300,400,600,700,800|Shadows+Into+Light"></link>
	<link href='http://fonts.googleapis.com/css?family=Source+Sans+Pro:400,700,700italic,600italic,600,400italic,900|Raleway:400,700,500|Ubuntu:400,700,500|Arimo:400,700,400italic|Monda:400,700&subset=latin,cyrillic' rel='stylesheet' type='text/css'>
	<link href='http://fonts.googleapis.com/css?family=Cabin|PT+Serif|Rajdhani:400,700,600,500,300|Overlock:400,900,400italic,700,700italic,900italic|Lato:400,900,400italic,700,700italic|Sarpanch:400,500,600,700,800&subset=latin,cyrillic' rel='stylesheet' type='text/css'>

    <link type="text/css" rel="stylesheet" href="/css/ru-RU/template.css"></link>

	<script src="/js/jquery-2.1.1.js" type="text/javascript"></script>
	<script src="/js/frontend.js" type="text/javascript"></script>

	<script src="http://loginza.ru/js/widget.js" type="text/javascript"></script>
	<!--script type="text/javascript">
    var widget_id = '3';

    // назначаем callback-функцию
    LOGINZA.Widget.setAjaxCallback(getToken);

    // инициализация
    LOGINZA.Widget.init(widget_id);

    // callback-функция обработки token
    function getToken (token){
        // test
        alert("Token: " + token);
    }
	</script-->


</head>
<body>

<?php $this->beginBody() ?>

<body>
    <div class="wrap">

		<div class="header">
	 		<div class="layout_container">

				<div class="logo_container">
					<img class="logo_image" src="/img/logotype2.png">
					<a class="logo_link" href="/">tunnel.me</a>
				</div>

				<div class="menu_bar">
					<a class="menu_link" href="/site/download">Загрузка</a>
					<a class="menu_link" href="/site/price">Цены</a>
					<a class="menu_link">Помощь</a>
					<a class="menu_link" href="/site/contact">Контакты</a>
					<?php if (!Yii::$app->user->isGuest) { ?>
    					<a class="menu_link" style="color:#fb1c05" href="/site/logout">Выход</a>
					<?php } ?>
				</div>

				<?php if (!Yii::$app->user->isGuest) { ?>
    			<a href="/site/account">
					<div class="menu_user menu_right">
						<span class="menu_user_text">
							<?php echo Yii::$app->user->identity->native_provider->weblogin ?>
						</span>
						<img class="menu_user_img" src="/img/usrnew.png" />
					</div>
				</a>
				<?php } ?>

				<div class="menu_language menu_right">
					<table class="popup_content">
						<tr>
							<td class="popup_item" lang="ru">
								<span>Русский</span>
							</td>
						</tr>
						<tr class="popup_menu">
							<td class="popup_item" lang="en">					
								<span>English</span>
							</td>
						</tr>
						<tr class="popup_menu">
							<td class="popup_item" lang="de">					
								<span>Deutch</span>
							</td>
						</tr>
						<tr class="popup_menu">
							<td class="popup_item" lang="yk">					
								<span>Украiнскiй</span>
							</td>

						</tr>
					</table>
				</div>

			</div>
		</div>

		<div class="popup_panel hide">
			<div class="layout_container">
				<div class="popup_language ">
					<table class="popup_content">
						<tr>
							<td class="lang_item" lang="ru">
								<span>Русский</span>
							</td>
						</tr>
						<tr>
							<td class="lang_item" lang="en">					
								<span>English</span>
							</td>

						</tr>
						<tr>
							<td class="lang_item" lang="de">					
								<span>Deutch</span>
							</td>
						</tr>
						<tr>
							<td class="lang_item" lang="yk">					
								<span>Украiнскiй</span>
							</td>

						</tr>
					</table>
				</div>
			</div>
		</div>

		<?php if (Yii::$app->user->isGuest) { ?>
		<div class="header_panel">
				
				<div class="login_bar_error hide">
					<span class="login_bar_error_message">Authentication failed.</span>
				</div>

   				<div class="login_bar">
					<form class="form_login" action="/site/login" method="post">
   						<input name="username" type="text" class="form_input" placeholder="Email">
   						<input name="password" type="password" class="form_input" placeholder="Password">
						<button type="submit" class="form_button">Войти</button>
						<a href="/site/sign" class="form_link_big">Регистрация</a>
						<span class="form_link">&nbsp;&nbsp;или войдите через:</span>
						<span class="form_social_group">
							 
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=yandex">
								<img src="http://loginza.ru/img/providers/yandex.png" alt="Yandex" title="Yandex">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=google">
								<img src="http://loginza.ru/img/providers/google.png" alt="Google" title="Google Accounts">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=vkontakte">
    							<img src="http://loginza.ru/img/providers/vkontakte.png" alt="VKontakte" title="VKontakte">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=mailru">
    							<img src="http://loginza.ru/img/providers/mailru.png" alt="Mail.ru" title="Mail.ru">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=twitter">
    							<img src="http://loginza.ru/img/providers/twitter.png" alt="Twitter" title="Twitter">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=loginza">
    							<img src="http://loginza.ru/img/providers/loginza.png" alt="Loginza" title="Loginza">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=myopenid">
    							<img src="http://loginza.ru/img/providers/myopenid.png" alt="MyOpenID" title="MyOpenID">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=openid">
    							<img src="http://loginza.ru/img/providers/openid.png" alt="OpenID" title="OpenID">
							</a>
							<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url=<?php echo Yii::$app->homeUrl; ?>/site/authtoken&provider=webmoney">
    							<img src="http://loginza.ru/img/providers/webmoney.png" alt="WebMoney" title="WebMoney">
							</a>
						</span>
						<br>
						<a class="form_link forget_password">Забыли пароль?</a>

					</form>
				</div>
		
		</div>
		<?php } ?>


		<div class="body_container <?php if (Yii::$app->user->isGuest) { ?>body_panel_padding<?php } ?>">
		    <?= $content ?>
		</div>

		<div class="footer_space">
		</div>
	</div>
   	<footer class="footer-top">
       	<div class="layout_container">
       		<table>
				<tr>
					<td class="footer-column">
						<a class="footer-main-link">О нас</a>
						<ul class="footer-list">
							<li><a>Где находимся ?</a></li>
							<li><a>Правила</a></li>
							<li><a>О компании</a></li>
							</ul>
					</td>
					<td class="footer-column">
						<a class="footer-main-link">Инструкции</a>
						<ul class="footer-list">
							<li><a>Настройка под Win32</a></li>
							<li><a>Настройка под Win64</a></li>
							<li><a>Настройка под Linux</a></li>
							<li><a>Настройка под FreeBSD</a></li>
						</ul>
					</td>
					<td class="footer-column">
						<a class="footer-main-link">Помощь</a>
						<ul class="footer-list">
							<li><a>Тех.поддержка.</a></li>
							<li><a>Часто задаваймые вопросы.</a></li>
						</ul>
					</td>
				</tr>
			</table>
       	</div>
   	</footer>

<?php $this->endBody() ?>
</body>
</html>
<?php $this->endPage() ?>
