<?php

namespace app\models;

use Yii;

/**
 *
 * @property integer $id
 * @property string $groupname
 * @property string $attribute
 * @property string $op
 * @property string $value
 */
class RadGroupCheck extends \yii\db\ActiveRecord
{
    /**
     * @inheritdoc
     */
    public static function tableName()
    {
        return 'radgroupcheck';
    }

    /**
     * @inheritdoc
     */
    public function rules()
    {
        return [
            [['groupname', 'attribute', 'value'], 'string', 'max' => 64],
            [['op'], 'string', 'max' => 4]
        ];
    }

    public function getRadUserGroup()
    {
		return $this->hasMany(RadUserGroup::className(), ['groupname' => 'groupname']);
    }

}
