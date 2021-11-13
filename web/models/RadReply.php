<?php

namespace app\models;

use Yii;

/**
 *
 * @property integer $id
 * @property string $username
 * @property string $attribute
 * @property string $op
 * @property string $value
 */
class RadReply extends \yii\db\ActiveRecord
{
    /**
     * @inheritdoc
     */
    public static function tableName()
    {
        return 'radreply';
    }

    /**
     * @inheritdoc
     */
    public function rules()
    {
        return [
            [['username', 'attribute', 'value'], 'string', 'max' => 64],
            [['op'], 'string', 'max' => 4]
        ];
    }

    public function getRadUserGroup()
    {
		return $this->hasMany(RadUserGroup::className(), ['username' => 'username']);
    }



}
