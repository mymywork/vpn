<?php

namespace app\controllers;

use Yii;
use yii\filters\AccessControl;
use yii\web\Controller;
use yii\filters\VerbFilter;
use yii\validators\EmailValidator;
use yii\web\Session;
use app\models\AuthForm;
use app\models\ChangeForm;
use app\models\ContactForm;
use app\models\IdentityContainer;
use app\models\Utils;

use app\models\RadUserGroup;
use app\models\KeyProvider;


class SiteController extends Controller
{

    var $enableCsrfValidation = false;

	var $langs_links = [ 'ru-RU' => [ 'ru','be','uk','ky','ab','mo','et','lv' ], 
	                     'de-DE' => [ 'de' ],
						 'en-EN' => [ 'en' ],
						];

    public function behaviors()
    {
        return [
            'access' => [
                'class' => AccessControl::className(),
                'only' => ['account','servers','payments','getconfig'],
                'rules' => [
                    [
                        'allow' => true,
                        'roles' => ['@'],
                    ],
                ],
            ],
			/*'verbs' => [
                'class' => VerbFilter::className(),
                'actions' => [
                    'logout' => ['options'],
                    'contact' => ['GET'],
                ],
            ],*/
        ];
    }

    public function actions()
    {
        return [
            'error' => [
                'class' => 'yii\web\ErrorAction',
            ],
            'captcha' => [
                'class' => 'yii\captcha\CaptchaAction',
                'fixedVerifyCode' => YII_ENV_TEST ? 'testme' : null,
            ],
        ];
    }

	public function beforeAction($action)
	{
		$headers = Yii::$app->request->headers;
		$cookies = Yii::$app->request->cookies;
		$language = [];


		if ( $list = strtolower(Yii::$app->request->get("lang")) ) {
			
           	if (preg_match('/([a-z]{1,4})/', $list, $list)) {

				$language = array_combine([$list[1]],[1]);

				$l=$this->getSupportedLangs($language);
				\Yii::$app->language = ( $l != null ) ? $l : 'en';

				if ( $l != null ) { 
					$cookies = Yii::$app->response->cookies;
					$cookies->add(new \yii\web\Cookie([
    					'name' => 'language',
    					'value' => $list[1],
						'httpOnly' => false
					]));
				}
        	}

		} else if (($cookie = $cookies->get('language')) !== null) {
    		$list = $cookie->value;

           	if (preg_match('/([a-z]{1,4})/', $list, $list)) {

				$x = $list[0];
				$language[$x] = 1;
        	}
			\Yii::$app->language = ( ($l=$this->getSupportedLangs($language)) != null ) ? $l : 'en';

		} else if ( $headers->has('Accept-Language') ) {

  			if ($list = strtolower($headers->get('Accept-Language'))) {
            	if (preg_match_all('/([a-z]{1,8}(?:-[a-z]{1,8})?)(?:;q=([0-9.]+))?/', $list, $list)) {
		    	    $language = array_combine($list[1], $list[2]);
					// set default as 1
                	foreach ($language as $n => $v)
                    	$language[$n] = $v ? $v : 1;
                	arsort($language, SORT_NUMERIC);
            	}
        	} 
			\Yii::$app->language = ( ($l=$this->getSupportedLangs($language)) != null ) ? $l : 'en';
       	} 


    	if (parent::beforeAction($action)) {
        	// your custom code here
        	return true;  // or false if needed
    	} else {
        	return false;
    	}
	}

	public function getSupportedLangs($language)
	{
		// Перечисляем языки от браузера или из кук.
 		foreach ($language as $l => $v) {
			// Убираем страну
           	$short_lang = strtok($l, '-'); 

			// Перечисляем языки сайта
			foreach ( $this->langs_links as $lang=>$lang_value ) {
				// Массив
				if ( is_array($lang_value) ) {
					// Перечисляем языки линки на основной язык
					foreach ( $lang_value as $local_lang ) {
						// Нашли совпадение ? устанавливаем 
						if ( strtolower($local_lang) == $short_lang ) {
							return $lang;
						}
					}
				} else {
					// Если не массив просто сравниваем
					if ( strtolower($local_lang) == $lang_value ) {
						return $lang;
					}
				}
			}
       	}
		return null;
	}


    public function actionIndex()
    {
        return $this->render('index.tpl');
    }

    public function actionLogin()
    {
        if (!\Yii::$app->user->isGuest) {
            return $this->goHome();
        }

        $model = new AuthForm();
		$model->scenario = 'login';

        if ($model->load(Yii::$app->request->post()) && $model->login()) {

			return $this->redirect(Yii::$app->homeUrl.'/site/account');
        } else {

			$msg = [ 'title' =>  'Oops. Error authentication.' ,
					 'reason' => 'Login or password is invalid',
					 'comment' => 'Please try again or select another account.' , 
					 'href' => '/site/index/' ,
					 'link' => 'Goto main page'];
		
			return $this->render('autherror.tpl',[ 'msg' => $msg ] );

/*            return $this->render('login', [
                'model' => $model,
            ]);
*/
        }
    }

	public function actionAuthtoken() 
	{   	
		$mix_input = array_merge(Yii::$app->request->post(),Yii::$app->request->get());

		//if ( !\Yii::$app->user->isGuest && !isset($mix_input['link']) ) {
		//	return $this->goHome();
		//}
        
		$model = new AuthForm();
		$model->scenario = 'token';

		if ( $model->load($mix_input) && $model->login()) {

			return $this->redirect(Yii::$app->homeUrl.'/site/account');

		} else {
			$msg = [ 'title' =>  'Oops. Error authentication.' ,
					 'reason' => 'Social account is not valid',
					 'comment' => 'Please try again or select another account.' , 
					 'href' => '/site/index/' ,
					 'link' => 'Goto main page'];
		
			return $this->render('autherror.tpl',[ 'msg' => $msg ] );
		}
	}

/*	public function actionChange_vpn_login() 
	{	
		Yii::$app->response->format = 'json';

		$mix_input = array_merge(Yii::$app->request->post(),Yii::$app->request->get());

		$model = new ChangeForm();
		$model->scenario = 'vpnchangelogin';

		if ( $model->load($mix_input) && $model->change()) {
		
		} else {

		}

		return $model->getResultJson();
	}
*/	

	public function actionChange_vpn_password() 
	{
		Yii::$app->response->format = 'json';

		$mix_input = array_merge(Yii::$app->request->post(),Yii::$app->request->get());

		$model = new ChangeForm();
		$model->scenario = 'vpnchangepassword';

		if ( $model->load($mix_input) && $model->change()) {
		
		} else {

		}

		return $model->getResultJson();
	}

/*	public function actionChange_web_login() 
	{	
		Yii::$app->response->format = 'json';

		$mix_input = array_merge(Yii::$app->request->post(),Yii::$app->request->get());

		$model = new ChangeForm();
		$model->scenario = 'webchangelogin';

		if ( $model->load($mix_input) && $model->change()) {
		
		} else {

		}

		return $model->getResultJson();
	}
*/
	public function actionChange_web_password() 
	{
		Yii::$app->response->format = 'json';

		$mix_input = array_merge(Yii::$app->request->post(),Yii::$app->request->get());

		$model = new ChangeForm();
		$model->scenario = 'webchangepassword';

		if ( $model->load($mix_input) && $model->change()) {
		
		} else {

		}

		return $model->getResultJson();
	}

	public function actionDelete_social_account() {
		Yii::$app->response->format = 'json';

		$identity = ( Yii::$app->request->getMethod() == 'POST' ) ? Yii::$app->request->getBodyParam('identity',null) : Yii::$app->request->getQueryParam('identity',null);

		if ( $identity == null ) {
   			return ['status'=> false, 'error' => 'Function call without params.'];
		}
		
		$result = IdentityContainer::deleteSocialAccount($identity);
		return $result;
	}

	public function actionLogout()
	{
		Yii::$app->user->logout();

		return $this->goHome();
	}

 /*   public function actionContact()
    {
        $model = new ContactForm();
        if ($model->load(Yii::$app->request->post()) && $model->contact(Yii::$app->params['adminEmail'])) {
            Yii::$app->session->setFlash('contactFormSubmitted');

            return $this->refresh();
        } else {
            return $this->render('contact', [
                'model' => $model,
            ]);
        }
    }
 */

    public function actionAccount()
    {
		$identity = Yii::$app->user->identity;

		$in = Utils::humanFileSize($identity->native_provider->trafficincount);
		$out = Utils::humanFileSize($identity->native_provider->trafficoutcount);

        if ( $identity->native_provider->firststart != null ) {
        	$lasttime = time() - strtotime($identity->native_provider->firststart);
			if ( $lasttime > $identity->native_provider->timemax ) {
				$timehas = 0;
				$timehalt = true;
			} else {
				$timehas = $identity->native_provider->timemax - $lasttime;
				$timehalt = false;
			}
		} else {
			$timehas = $identity->native_provider->timemax;
			$timehalt = true;
		}
        return $this->render('account.tpl',['identity' => $identity, 'homeUrl' => Yii::$app->homeUrl , 'in' => $in, 'out' => $out , 'timehas' => $timehas , 'timehalt' => $timehalt ]);
    }

	public function actionDownload_config()
	{
		$identity = Yii::$app->user->identity;

		$id = $identity->native_provider->id;
		
		$key = KeyProvider::findOne(['accountid' => $id, 'state' => 1 ]);	

		if ( $key != null ) {
			return Yii::$app->response->sendFile($key->path,basename($key->path));		
		}

		$msg = [ 'title' =>  'Oops. Key error.' ,
				 'reason' => 'Certificate and configuration not ready.',
				 'comment' => 'Please try again later.' , 
				 'href' => '/site/account/' ,
				 'link' => 'Goto account page'];
		
		return $this->render('autherror.tpl',[ 'msg' => $msg ] );
	}

    public function actionAbout()
    {
        return $this->render('about');
    }

    public function actionDownload()
    {
        return $this->render('download.tpl');
    }

    public function actionContact()
    {
        return $this->render('contact.tpl');
    }

    public function actionServers()
    {
        return $this->render('servers.tpl');
    }

    public function actionPayments()
    {
        return $this->render('payments.tpl');
    }

    public function actionPrice()
    {
        return $this->render('price.tpl');
    }

    public function actionSign()
    {
        return $this->render('sign.tpl');
    }

    public function actionTest()
    {
		$n = RadUserGroup::find()->innerJoinWith('radGroupCheck')->where(['username' => 'vasiya'])->all();
		print_r($n);

		exit();

		if ( count($n) != 0 ) {
					
			/* error login already present */
			$this->addError('newlogin','This login already exist');
		}

    }

}
