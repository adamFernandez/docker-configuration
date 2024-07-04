<?php

namespace wl\craftforgedeploy\models;

use craft\base\Model;

/**
 * forge-deploy settings
 */
class Settings extends Model
{
  public $forgeAuth = '';

  public $serverId = '';
  
  public $siteId = '';

  public $siteDomain = '';

  public $forgeDeployEnabled = true;
}
