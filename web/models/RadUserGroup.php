<?php

namespace app\models;

use Yii;

/**
 *
 * @property string $username
 * @property string $groupname
 * @property string $priority
 */
class RadUserGroup extends \yii\db\ActiveRecord
{
    /**
     * @inheritdoc
     */
    public static function tableName()
    {
        return 'radusergroup';
    }

    /**
     * @inheritdoc
     */
    public function rules()
    {
        return [
            [['username', 'groupname'], 'string', 'max' => 64],
            [['priority'], 'integer']
        ];
    }

    public function getRadGroupReply()
    {
		return $this->hasMany(RadGroupReply::className(), ['groupname' => 'groupname']);
    }

    public function getRadGroupCheck()
    {
		return $this->hasMany(RadGroupCheck::className(), ['groupname' => 'groupname']);
    }

}
