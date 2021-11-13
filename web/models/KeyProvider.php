<?php

namespace app\models;

use Yii;

/**
 *
 * @property integer $accountid
 * @property string  $path
 * @property integer $state
 *

  CREATE TABLE IF NOT EXISTS key_provider (
 	accountid	integer default null,
 	path		varchar(256) DEFAULT '',
 	state		integer default null,
	PRIMARY KEY(accountid,path)
  ); 

 */

class KeyProvider extends \yii\db\ActiveRecord
{
    /**
     * @inheritdoc
     */
    public static function tableName()
    {
        return 'key_provider';
    }

    /**
     * @inheritdoc
     */
    public function rules()
    {
        return [
            [['accountid','state'], 'integer'],
            [['path'], 'string'],
        ];
    }

}
