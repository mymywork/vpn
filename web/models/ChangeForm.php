<?php

namespace app\models;

use Yii;
use yii\base\Model;
use yii\validators\RegularExpressionValidator;

use app\models\RadReply;
use app\models\RadCheck;
use app\models\RadUserGroup;

/**
 * AuthForm is the model behind the login form.
 */
class ChangeForm extends Model
{
	public $newlogin;
	public $newpassword;

    /**
     * @return array the validation rules.
     */
    public function rules()
    {
        return [
            // username and password are both required
            [['newlogin', 'newpassword'], 'required','message' => 'Parameter no pass.'],
            // password is validated by validatePassword()
            ['newlogin', 'email','message' => 'Login has not valid email.'],
			//['newlogin', 'regexexpression', 'pattern' => '/tm[0-9]+@tunnel.so/', 'not'=> true]
            ['newlogin', 'validateEmail'],

		    // token is validated by validateToken()
		    ['newpassword', 'validatePassword'],
        ];
    }

    public function scenarios()
    {
        return [
	    	'webchangelogin' => ['newlogin'],
            'webchangepassword' => ['newpassword'],
	    	'vpnchangelogin' => ['newlogin'],
            'vpnchangepassword' => ['newpassword'],
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
     * Validates the email extended
     */
    public function validateEmail()
	{
		/* check if we want change in default ? */

		/* regex pattern internal email */

		$validator = new RegularExpressionValidator([ 'pattern' => '/tm[0-9]+@tunnel.so/' ]);

   		$error;

		if ($validator->validate($this->newlogin, $error)) {
			$this->addError('newlogin','You not change email for domain @tunnel.so');
		} 
		

		/* check and change by scenario */

       	if ( $this->getScenario() == 'webchangelogin' ) {

			$identity = Yii::$app->user->identity;
			if ( $identity->native_provider->weblogin != $this->newlogin ) {

				/* not match with emails in database */		

				$n = NativeProvider::find()->where(['weblogin' => $this->newlogin ])->all();
				if ( count($n) != 0 ) {
					
					/* error login already present */
					$this->addError('newlogin','This login already exist');

				}

			} else {

				$this->addError('newlogin','New email matches with old.');

			}

			/* send email approve reference */
			

		} else if ( $this->getScenario() == 'vpnchangelogin') {

			$identity = Yii::$app->user->identity;
			if ( $identity->native_provider->vpnlogin != $this->newlogin ) {

				/* not match with emails in database */		

				$n = NativeProvider::find()->where(['vpnlogin' => $this->newlogin ])->all();
				if ( count($n) != 0 ) {
					
					/* error login already present */
					$this->addError('newlogin','This login already exist');
				}

				/* not match with emails in database */		

				$n = RadCheck::find()->where(['username' => $this->newlogin ])->all();
				if ( count($n) != 0 ) {
					
					/* error login already present */
					$this->addError('newlogin','This login already exist');
				}

				/* not match with emails in database */		

				$n = RadUserGroup::find()->where(['username' => $this->newlogin ])->all();
				if ( count($n) != 0 ) {
					
					/* error login already present */
					$this->addError('newlogin','This login already exist');
				}

	        } else {

				/* error email matches old */
				$this->addError('newlogin','New email matches with old.');

			}
		} else {

			/* other scenario failed for login */
			$this->addError('newlogin','Internal scenario error.');

		}
	}

    /**
     * Validates the password.
     */
    public function validatePassword()
    {
       	if ( $this->getScenario() == 'webchangepass' ) {

			$identity = Yii::$app->user->identity;
			if ( $identity->native_provider->webpassword == $this->newpassword ) {

				/* error email matches old */
				$this->addError('newpassword','New password matches with old.');
			}			

		} else if ( $this->getScenario() == 'vpnchangepass') {

			$identity = Yii::$app->user->identity;
			if ( $identity->native_provider->vpnpassword == $this->newpassword ) {

				/* error email matches old */
				$this->addError('newpassword','New password matches with old.');
			}			
		
		}

    }

    /**
     * Change Value
     */
    public function change()
    {
		/* Identity object */

		$identity = Yii::$app->user->identity;

		if ( $this->validate() ) {

       		if ( $this->getScenario() == 'webchangelogin' ) {

				$identity->native_provider->weblogin = $this->newlogin;
				$identity->native_provider->save();

			} else if ( $this->getScenario() == 'webchangepassword' ) {

				$identity->native_provider->webpassword = $this->newpassword;
				$identity->native_provider->save();

			} else if ( $this->getScenario() == 'vpnchangelogin' ) {

				$oldlogin = $identity->native_provider->vpnlogin;

				RadCheck::updateAll(['username' => $this->newlogin], 'username=:username', [':username' => $oldlogin]);
				RadReply::updateAll(['username' => $this->newlogin], 'username=:username', [':username' => $oldlogin]);
				RadUserGroup::updateAll(['username' => $this->newlogin], 'username=:username', [':username' => $oldlogin]);

				$identity->native_provider->vpnlogin = $this->newlogin;
				$identity->native_provider->save();

			} else if ( $this->getScenario() == 'vpnchangepassword' ) {

				$oldlogin = $identity->native_provider->vpnlogin;

				RadCheck::updateAll(['value' => $this->newpassword], ['and','username=:username','attribute=\'Cleartext-Password\''],[':username' => $oldlogin]);

				$identity->native_provider->vpnpassword = $this->newpassword;
				$identity->native_provider->save();
			}

			return true;
		} else {
			return false;			
		}
	}

	/**
	 * Get Result Json
	 */
	public function getResultJson()
    {
		$errors = $this->getErrors();
		return [ 'status' => ( count($errors) == 0 ? true : false  ) ,  'errors' => $errors ];
	}

}
