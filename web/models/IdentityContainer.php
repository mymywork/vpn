<?php

namespace app\models;

use Yii;
use app\models\SocialProvider;
use app\models\NativeProvider;
use app\models\Utils;

class IdentityContainer extends \yii\base\Object implements \yii\web\IdentityInterface
{
/*  
	public $username;
    public $password;
    public $AuthKey;
    public $accessToken;
*/
	public $social_provider;
	public $native_provider;


/*	
	NativeProvider

	public $id;
	public $Name;
	public $Password;
	public $Email;
	public $EPassword;
	public $TimePlan;
	public $TrafficPlan;
	public $FirstStart;
	public $LastStop;
	public $TrafficInCount;
	public $TrafficOutCount;
	public $TimeCount;
	public $TrafficInMax;
	public $TrafficOutMax;
	public $TimeMax;
	public $RateIn;
	public $RateOut;
	public $Balance;
	public $Active;
*/
/*
	SocialProvider

	public $identity;
	public $type;
	public $name;
	public $tid;
*/

    /**
     * Finds user by username
     *
     * @param  string      $username
     * @return static|null
     */
    public static function findByUsername($login)
    {
		$n = NativeProvider::find()->where(['weblogin' => $login ])->joinWith('socialProvider')->all();

		//print("findByUsername:".$username);

		if ( $n == null ) return null;

 		$usr = new IdentityContainer();
		$usr->social_provider = $n[0]->socialProvider;
		$usr->native_provider = $n[0];

		return $usr;
    }

    /**
     * Validates password
     *
     * @param  string  $password password to validate
     * @return boolean if password provided is valid for current user
     */
    public function validatePassword($password)
    {
        return $this->native_provider->webpassword === $password;
    }

    /**
     * Validates token
     *
     * @param  string  $token token to validate
     * @return boolean if password provided is valid for current user
     */
	public static function validateToken($token) {

			$curl = curl_init();
			
			curl_setopt_array($curl,array(
				CURLOPT_URL => 'http://loginza.ru/api/authinfo?token='.$token,
				CURLOPT_RETURNTRANSFER => true,         // return web page
				CURLOPT_HEADER         => false,        // don't return headers
				CURLOPT_FOLLOWLOCATION => true,         // follow redirects
				CURLOPT_ENCODING       => "",           // handle all encodings
				CURLOPT_USERAGENT      => "agent",      // who am i
				CURLOPT_AUTOREFERER    => true,         // set referer on redirect
				CURLOPT_CONNECTTIMEOUT => 120,          // timeout on connect
				CURLOPT_TIMEOUT        => 120,      
                		//CURLOPT_POST            => 0,
				//CURLOPT_POSTFIELDS     => $curl_data,
			));
			
			
			$json = curl_exec($curl);
			$result = json_decode($json,true);
			
			if ( isset($result['error_type']) ) {
				return ['status' => false , 'error' => $result['error_message'] , 'json' => $result ];
			} else {
				return ['status' => true , 'json' => $result ];
			}	
	}

	/**********************
	 * Interface Identify *
	 **********************/
	
    /**
     * @inheritdoc
     */
    public static function findIdentity($id)
    {

		$s = SocialProvider::find()->where(['tid' => $id ])->all();
		$n = NativeProvider::find()->where(['id' => $id ])->all();

		//print("findIdentity:".$id);

		if ( count($n) == 0 ) return null;

 		$usr = new IdentityContainer();
		$usr->social_provider = $s;
		$usr->native_provider = $n[0];

		return $usr;
    }

    /**
     * @inheritdoc
     */
    public static function findIdentityByAccessToken($token,$type = NULL)
    {

		if ( !Yii::$app->user->isGuest ) {
			
			$usr = Yii::$app->user->identity;			

			foreach ( $usr->social_provider as $s ) {

				// if social already linked to us.
				
				if ( $s->identity == $token['identity'] ) {

					return $usr;
				}

			}

			// if social already linked to other return null
			$soc = SocialProvider::find()->where(['identity' => $token['identity'] ])->all();

			if ( count($soc) != 0 ) {

				return null;
			}
			
			if ( $usr->native_provider != null ) {

				$soc = self::createSocialProvider($token,$usr->native_provider);

				/* Link native and social providers to new Identity object */
				$usr->social_provider[] = $soc;
				
			} else {

				return null;
			}

		} else {

			/* Find social provider by identity=token  */
	
			$usr = new IdentityContainer();
			$soc = SocialProvider::find()->where(['identity' => $token ])->joinWith('nativeProvider')->all();
		    
			if ( count($soc) == 0 ) {

				/* If social NOT found  */
				/* Create Native provider */
			
				$n = self::createNativeProvider();

				/* Create radius account */
				$radchk = new RadCheck();
				$radchk->addCleartextPassword($n->vpnlogin,$n->vpnpassword);
				$radchk->save();

				/* Create and set social provider */
				$soc = self::createSocialProvider($token,$n);

				/* Create key provider request*/
				self::createKeyProvider($n);
				
				/* Link native and social providers to new Identity object */
				$usr->native_provider = $n;
				$usr->social_provider = [$soc];
			
		
			} else {

				/* If social found  */
				/* Get native provider */

				$usr->native_provider = $soc[0]->nativeProvider;
				$usr->social_provider = $soc;
			}

		}
		
        	return $usr;
    	}

	public static function createKeyProvider($n) {

		$keys = KeyProvider::find()->where(['accountid' => $n->id, 'state' => 1 ])->all();	
		print_r($keys);
		exit();
		if ( count($keys) != 0 ) {
			return;
		}

		$keys = KeyProvider::find()->where(['accountid' => $n->id, 'state' => 0 ])->all();	

		if ( count($keys) != 0 ) {
        		return;
		}

		// insert key in state request

		$key = new KeyProvider();
		$key->accountid = $n->id;
		$key->state = 0;		
		$key->save();

		// signaling

		if ( substr(Yii::$app->db->dsn,0,5) == 'pgsql' ) {
			Yii::$app->db->createCommand("SELECT pg_notify('genmgr','".$n->vpnlogin."');")->execute();
		}
	}

	public static function createSocialProvider($token,&$nativeProvider) {

		$soc = new SocialProvider();
		$soc->identity = $token['identity'];
		$soc->name = ( isset($token['nickname']) && $token['nickname'] != null ? $token['nickname'] : ( isset($token['name']) ? implode(" ", $token['name']) : 'empty' ));
		$soc->type = $token['shorttype'];
		$soc->tid = $nativeProvider->getPrimaryKey();
		$o = $soc->save();

		return $soc;
	}

	public static function createNativeProvider() {

    		$n = new NativeProvider();

		if ( substr(Yii::$app->db->dsn,0,5) == 'mysql' ) {

			// mysql

			$n->firststart = '0000-00-00 00:00:00';
			$n->laststop = '0000-00-00 00:00:00';

		} else {

			// pgsql
	
			$n->firststart = null;
			$n->laststop = null;
		}

        	$n->timeplan=1;
		$n->trafficplan=0;
		$n->trafficincount=0;
		$n->trafficoutcount=0;
		$n->timecount=0;
		$n->trafficinmax=0;
		$n->trafficoutmax=0;
		$n->timemax=0;
		$n->ratein=0;
		$n->rateout=0;
		$n->balance=50;
		$n->active=0;
                
		$o = $n->save();

		/* Generate login by id */			
			
		$login = 'tm'.$n->getPrimaryKey().'@tunnel.me';
		$password = rand(0,9) . rand(0,9) . rand(0,9) . rand(0,9) . rand(0,9) . rand(0,9); 

		/* Set Native provider */			

		$n->vpnlogin= $login;
		$n->vpnpassword = $password;
		$n->weblogin = $login;
		$n->webpassword = $password;
		$n->authkey = md5($n->webpassword);		
		$n->save();

		return $n;
	}


	/**
	 * Extened functional: deleteSocialAccount
	 */
	public static function deleteSocialAccount($id) {

		$identity = Yii::$app->user->identity;
		$accounts = array();

		$deleted=false;

		foreach ( $identity->social_provider as $idx=>$social ) {

			if ( $social->identity == $id ) {
				$social->delete();
				unset($identity->social_provider[$idx]);
				$deleted = true;
			} else {
				$accounts[]=['identity' => $social->identity, 'name'=> $social->name, 'type' => $social->type ];
			}
		}
 			
  		if ( $deleted ) {

			return ['status' => true, 'socials' => $accounts ];
		} else {

			return ['status' => false, 'error' => 'Social for delete not found.' ];
		}
	}	

    /**
     * @inheritdoc
     */
    public function getId()
    {

		return $this->native_provider->id;
    }

    /**
     * @inheritdoc
     */
    public function getAuthKey()
    {
        return $this->native_provider->authkey;
    }

    /**
     * @inheritdoc
     */
    public function validateAuthKey($authKey)
    {
        return $this->authKey === $authKey;
    }

}
