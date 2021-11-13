<link type="text/css" rel="stylesheet" href="/css/profile.css"></link>
<script src="/js/profile.js" type="text/javascript"></script>

<div class="layout_container">

			<!-- templates -->

			<div class="hide account_change_template">
				<div class="account_change_text_container">
    				<span class="account_change_message">Change password</span><br>
				</div>
				<div class="account_change_container">
					<input class="account_change_input" value="" /><br>
					<button class="account_change_button account_change_save">Сохранить все при все</button>
					&nbsp;<button class="account_change_button account_change_cancel">Отменить</button>										
				</div>
				<img class="account_change_preloader hide" src="/img/pload.gif"/>
			</div>

			<table class="hide account_social_template">
				<tr class="account_social_item">
					<td class="account_social_item_name">
						<img src="http://loginza.ru/img/providers/vkontakte.png">
						<span>Alexander</span>
					</td>
					<td class="account_social_item_link">
						<a class="profile_delete_social">Удалить</a>
					</td>
				</tr>

				<tr class="account_social_item_empty">
					<td><span class="account_social_empty">Empty</span></td>
				</tr>												

				<tr class="account_social_item_error">
					<td><span class="account_social_error">Error social operation</span></td>
				</tr>												

			</table>

			<!-- templates -->


			<div class="profile_menu">
				<a href="/site/account"><div class="profile_menu_active">Account</div></a>
				<a href="/site/servers"><div class="profile_menu_item">Servers</div></a>
				<a href="/site/payments"><div class="profile_menu_item">Payments</div></a>
				<div class="profile_menu_item">Wizard Connection</div>
			</div>
			<div class="profile_container">
				<table class="account_table">
					<tr>
						<td>
							<div class="account_table_block">
								<div class="account_table_block_content">
									<span class="account_block_title">Your time balance</span><br>
									<div class="account_table_block_place account_timestamp_font">
										<span class="account_timestamp_sup"></span><span class="account_timestamp timestamp" value="{$timehas}" timehalt="{$timehalt}" >-:-:-</span>
									</div>
								</div>
								<div class="account_table_block_tip">
									<span class="account_block_text_small">It's time balance of your account, time start for first vpn connection and can't stop after.</span><br>
								</div>
							</div>	
						</td>
					</tr>
					<tr>
						<td>
							<div class="account_table_block">
								<div class="account_table_block_content">
									<span class="account_block_title">Your PPTP, L2TP and OpenVPN account</span><br><br>
									<div class="account_table_block_place">
										<span class="account_block_text">
											<b>Login:</b>&nbsp;<span value="{$identity->native_provider->vpnlogin}">{$identity->native_provider->vpnlogin}</span>
										</span>
										<br>
										<span class="account_block_text">
											<b>Password:</b>&nbsp;<a class="profile_change profile_change_pass" action="/site/change_vpn_password" param="newpassword" value="{$identity->native_provider->vpnpassword}">****</a>&nbsp;&larr;&nbsp;<a class="profile_showhide">Показать</a>
										</span>
										<br>
										<br>
									</div>
								</div>
								<div class="account_table_block_tip">
									<span class="account_block_text_small">This is your vpn server login/password for connection by pptp,l2tp,openvpn protocols, ypu may change your login,password by click right button.</span><br>
								</div>
							</div>	
						</td>
					</tr>
					<tr>
						<td class="account_table_space">
						</td>
					</tr>
					<tr>
						<td>
							<div class="account_table_block">
								<div class="account_table_block_content">
									<span class="account_block_title">Your Certificate for OpenVPN</span><br>
									<div class="account_table_block_place">
										<div class="profile_download_cfg account_cert_button">Download certificate.</div><img src="/img/pload.gif" class="account_download_preloader hide"><br>
									</div>
								</div>
								<div class="account_table_block_tip">
									<span class="account_block_text_small">For download configuration file and pkcs12 certificate for your account and all countries,simply click on button.</span>
								</div>
							</div>	
						</td>
					</tr>
					<tr>
						<td class="account_table_space">
						</td>
					</tr>
					<tr>
						<td>
							<div class="account_table_block">
								<div class="account_table_block_content">
									<span class="account_block_title">Your Web account profile</span><br><br>
									<div class="account_table_block_place">
										<span class="account_block_text">
											<b>Login:</b>&nbsp;<span value="{$identity->native_provider->weblogin}">{$identity->native_provider->weblogin}</span>
										</span>
										<br>
										<span class="account_block_text">
											<b>Password:</b>&nbsp;<a class="profile_change profile_change_pass" action="/site/change_web_password" param="newpassword" value="{$identity->native_provider->webpassword}">****</a>&nbsp;&larr;&nbsp;<a class="profile_showhide">Показать</a>
										</span>
										<br>
										<br>
										<span style="font-size:14px;font-weight:bold;">Linked social accounts</span><br>
										<img class="account_social_preloader hide" src="/img/pload.gif"/>
										<table class="account_social">
											{if count($identity->social_provider) == 0 }
												<tr>
													<td><span class="account_social_empty">Empty</span></td>
												</tr>												
											{else}
												{foreach $identity->social_provider as $social}
													<tr identity="{$social->identity}">
														<td>
															<img src="/img/social/{$social->type}.png" />
															<span> {$social->name} </span>
														</td>
														<td>
															<a class="profile_delete_social">Удалить</a>
														</td>
													</tr>
												{/foreach}
											{/if}
										</table>
										<br>
										<span style="font-size:14px;">Click on icon for add social account</span><br>																				
										<span class="form_social_group">
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=yandex">
												<img src="http://loginza.ru/img/providers/yandex.png" alt="Yandex" title="Yandex">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=google">
												<img src="http://loginza.ru/img/providers/google.png" alt="Google" title="Google Accounts">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=vkontakte">
    											<img src="http://loginza.ru/img/providers/vkontakte.png" alt="VKontakte" title="VKontakte">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=mailru">
    											<img src="http://loginza.ru/img/providers/mailru.png" alt="Mail.ru" title="Mail.ru">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=twitter">
    											<img src="http://loginza.ru/img/providers/twitter.png" alt="Twitter" title="Twitter">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=loginza">
    											<img src="http://loginza.ru/img/providers/loginza.png" alt="Loginza" title="Loginza">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=myopenid">
    											<img src="http://loginza.ru/img/providers/myopenid.png" alt="MyOpenID" title="MyOpenID">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=openid">
    											<img src="http://loginza.ru/img/providers/openid.png" alt="OpenID" title="OpenID">
											</a>
											<a class="form_social_button loginza" href="https://loginza.ru/api/widget?token_url={$homeUrl}/site/authtoken&link=1&provider=webmoney">
    											<img src="http://loginza.ru/img/providers/webmoney.png" alt="WebMoney" title="WebMoney">
											</a>
										</span>
										<br><br>
									</div>
								</div>								
								<div class="account_table_block_tip">									
									<span class="account_block_text_small">This is your web login/password for this page access and control your vpn account.</span><br>
								</div>
							</div>	
						</td>
					</tr>
					<tr>
						<td class="account_table_space">
						</td>
					</tr>
					<tr>
						<td>
							<div class="account_table_block">
							    <div class="account_table_block_content">
									<span class="account_block_title">Traffic statistic</span><br><br>
									<div class="account_table_block_place">
										<span class="account_block_text"><b>In:</b>&nbsp;{$in}</span><br>
										<span class="account_block_text"><b>Out:</b>&nbsp;{$out}</span><br><br>
									</div>
								</div>
								<div class="account_table_block_tip">
									<span class="account_block_text_small">This show your account traffic in/out traffic.</span><br>
								</div>
							</div>	
						</td>
					</tr>

				</table>						
			</div>
</div>
