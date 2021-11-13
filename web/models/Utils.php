<?php

namespace app\models;

use Yii;
use yii\base\Component;


class Utils extends Component
{

	public static function humanFileSize($size)
	{
    	if ($size >= 1073741824) {
      		$fileSize = round($size / 1024 / 1024 / 1024,1) . 'GB';
    	} elseif ($size >= 1048576) {
	        $fileSize = round($size / 1024 / 1024,1) . 'MB';
    	} elseif($size >= 1024) {
        	$fileSize = round($size / 1024,1) . 'KB';
    	} else {
        	$fileSize = $size . 'B';
    	}
    	return $fileSize;
	}

	public static function shortProviderType($provider) 
	{
		if ( preg_match("/www\.google\./",$provider) ) {

			return 'google';

		} else if ( preg_match("/vk\.com/",$provider)  ) {

			return 'vkontakte';

		}

	}
}
