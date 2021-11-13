<?php

namespace app\models;
use app\models\NativeProvider;

use Yii;

/**
 * This is the model class for table "social_provider".
 *
 * @property integer $id
 * @property string $identity
 * @property string $type
 * @property string $name
 * @property integer $tid
 */
class SocialProvider extends \yii\db\ActiveRecord
{

    /**
     * @inheritdoc
     */
    public static function tableName()
    {
        return 'social_provider';
    }

    /**
     * @inheritdoc
     */
    public function rules()
    {
        return [
            [['identity', 'type', 'name'], 'required'],
            [['tid'], 'integer'],
            [['identity', 'type', 'name'], 'string', 'max' => 256]
        ];
    }

    /**
     * @inheritdoc
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'identity' => 'Identity',
            'type' => 'Type',
            'name' => 'Name',
            'tid' => 'Tid',
        ];
    }

    /**
     * @inheritdoc
     */
    public function getNativeProvider()
    {
		return $this->hasOne(NativeProvider::className(), ['id' => 'tid']);
    }
}
