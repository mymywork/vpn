<?php

namespace app\models;

use Yii;
use yii\base\Model;
use app\models\Utils;

/**
 * AuthForm is the model behind the login form.
 */
class AuthForm extends Model
{
    public $username;
    public $password;
    public $rememberMe = true;

    public $token;

    private $_user = false;

    private $providers = ['google', 'yandex', 'mailruapi', 'mailru', 'vkontakte', 'facebook', 'odnoklassniki', 'livejournal', 'twitter', 'linkedin', 'loginza', 'myopenid', 'webmoney', 'rambler', 'flickr', 'lastfm', 'verisign', 'aol', 'steam', 'openid'];
    private $validate_json;


    /**
     * @return array the validation rules.
     */
    public function rules()
    {
        return [
            // username and password are both required
            [['username', 'password','token'], 'required'],
            // password is validated by validatePassword()
            ['password', 'validatePassword'],
		    // token is validated by validateToken()
		    ['token', 'validateToken'],
        ];
    }

    public function scenarios()
    {
        return [
	    	'token' => ['token'],
            'login' => ['username', 'password'],
        ];
    }

	/**
	 * formName() for linkage form
	 */
	public function formName()
	{
		return '';
	}

	/**
	 * Validate the token.
	 */
	public function validateToken()
	{
        if (!$this->hasErrors()) {
			
			$result = IdentityContainer::validateToken($this->token);
			
			if ( !$result['status'] ) {
	       		$this->addError('token', 'Error:'.( isset($result['json']['error_message']) ? $result['json']['error_message'] : 'Unknow' ));
			} else {
				$this->validate_json = $result['json'];	
				$type = Utils::shortProviderType($this->validate_json['provider']);

				$this->validate_json['shorttype'] = $type;

				// check if provider in not array

				if ( !in_array($type,$this->providers) ) {
		       		$this->addError('token', 'Error: Provider not allowed for authentication.');
				}
				
			}			
    	}
	}


    /**
     * Validates the password.
     * This method serves as the inline validation for password.
     */
    public function validatePassword()
    {
        if (!$this->hasErrors()) {
            $user = $this->getIdentityContainerAndKeep();

            if (!$user || !$user->validatePassword($this->password)) {
                $this->addError('password', 'Incorrect username or password.');
            }
        }
    }

    /**
     * Logs in a user using the provided username and password.
     * @return boolean whether the user is logged in successfully
     */
    public function login()
    {
	
        if ($this->validate()) {

        	if ( $this->getScenario() == 'token' ) {
			    $identity = Yii::$app->user->loginByAccessToken($this->validate_json);
			    return $identity;
			} else if ( $this->getScenario() == 'login' ) {
			    return Yii::$app->user->login($this->getIdentityContainerAndKeep(), $this->rememberMe ? 3600*24*30 : 0);
			} else {
				// Other not support
				return false;
			}
        } else {
            return false;
        }
    }

    /**
     * Finds user by [[username]]
     *
     * @return User|null
     */
    public function getIdentityContainerAndKeep()
    {
        if ($this->_user === false) {
            $this->_user = IdentityContainer::findByUsername($this->username);
        }

        return $this->_user;
    }

}
