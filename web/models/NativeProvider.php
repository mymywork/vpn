<?php

namespace app\models;

use Yii;

/**
 * This is the model class for table "accounts".
 *
 * @property integer $id
 * @property string $VpnLogin
 * @property string $VpnPassword
 * @property string $WebLogin
 * @property string $WebPassword
 * @property integer $TimePlan
 * @property integer $TrafficPlan
 * @property string $FirstStart
 * @property string $LastStop
 * @property string $TrafficInCount
 * @property string $TrafficOutCount
 * @property string $TimeCount
 * @property string $TrafficInMax
 * @property string $TrafficOutMax
 * @property string $TimeMax
 * @property integer $RateIn
 * @property integer $RateOut
 * @property integer $Balance
 * @property integer $Active
 */
class NativeProvider extends \yii\db\ActiveRecord
{
    /**
     * @inheritdoc
     */
    public static function tableName()
    {
        return 'accounts';
    }

    /**
     * @inheritdoc
     */
    public function rules()
    {
        return [
            [['timeplan', 'trafficplan', 'trafficincount', 'trafficoutcount', 'timecount', 'trafficinmax', 'trafficoutmax', 'timemax', 'ratein', 'rateout', 'balance', 'active'], 'integer'],
            [['firststart', 'laststop'], 'safe'],
            [['vpnlogin', 'vpnpassword', 'weblogin', 'webpassword'], 'string', 'max' => 64],
            [['authkey'], 'string', 'max' => 32]
        ];
    }

    /**
     * @inheritdoc
     */
    public function attributeLabels()
    {
        return [
            'id' => 'ID',
            'vpnlogin' => 'VpnLogin',
            'vpnpassword' => 'VpnPassword',
            'weblogin' => 'WebLogin',
            'webpassword' => 'WebPassword',
            'authkey' => 'AuthKey',
            'timeplan' => 'Time Plan',
            'trafficplan' => 'Traffic Plan',
            'firststart' => 'First Start',
            'laststop' => 'Last Stop',
            'trafficincount' => 'Traffic In Count',
            'trafficoutcount' => 'Traffic Out Count',
            'timecount' => 'Time Count',
            'trafficinmax' => 'Traffic In Max',
            'trafficoutmax' => 'Traffic Out Max',
            'timemax' => 'Time Max',
            'ratein' => 'Rate In',
            'rateout' => 'Rate Out',
            'balance' => 'Balance',
            'active' => 'Active',
        ];
    }
    public function getSocialProvider()
    {
		return $this->hasMany(SocialProvider::className(), ['tid' => 'id']);
    }

}
