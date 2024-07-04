<?php
namespace wl\craftforgedeploy\controllers;

use Craft;
use craft\web\Controller;
use GuzzleHttp\Client;
use wl\craftforgedeploy\ForgeDeploy as fd;
use craft\services\Plugins;
use craft\events\PluginEvent;
use craft\web\twig\variables\Cp;
use yii\base\Event;

class DeploymentController extends Controller
{

  public function actionDeploy()
  {

    // $request = \Craft::$app->getRequest();
    
    $forgeAuth = Craft::parseEnv(fd::getInstance()->settings->forgeAuth);
    $serverId = Craft::parseEnv(fd::getInstance()->settings->serverId);
    $siteId = Craft::parseEnv(fd::getInstance()->settings->siteId);
    $siteDomain = Craft::parseEnv(fd::getInstance()->settings->siteDomain);

    $client = new Client();

    try {
      $response = $client->request('POST', "https://forge.laravel.com/api/v1/servers/$serverId/sites/$siteId/deployment/deploy", [
        'headers' => [
          'Authorization' => 'Bearer ' . $forgeAuth,
          'Accept' => 'application/json',
          'Content-Type' => 'application/json',
        ],
      ]);
      
      Craft::$app->getSession()->setNotice("Laravel Forge site deployment sent to $siteDomain.");

    } catch (ClientException $e) {

      Craft::$app->getSession()->setError("Failed to send deployment request to Laravel Forge. Please check your API key.");

    } catch (\Exception $e) {
      
      Craft::$app->getSession()->setError("An error occurred while fetching pages from Laravel Forge. $e");

    }
  }

  public function actionLoadList() 
  {
    // GET ALL CMS SECTIONS ENTRIES
    // $sectionsService = Craft::$app->getSections();

    // $sections = $sectionsService->getAllSections();
    


    // $forgeAuth = Craft::parseEnv(fd::getInstance()->settings->forgeAuth);

    // $client = new Client();
    
    // try {
    //   $response = $client->request('GET', "https://forge.laravel.com/api/v1/servers", [
    //     'headers' => [
    //       'Authorization' => 'Bearer ' . $forgeAuth,
    //       'Accept' => 'application/json',
    //       'Content-Type' => 'application/json',
    //     ],
    //   ]);
      
    //   $servers = json_decode($response->getBody(), true);
    //   $serversString = json_encode($servers);

    //   // $session = Craft::$app->getSession();

    //   // $session->setNotice("Request successful.");

    //   // $session->set('servers',json_encode($servers));
      Craft::dd("Testing.");
      // return $this->renderTemplate('forge-deploy/deploy_settings', [
      //     'servers' => $servers,
      //     'settings' => fd::getInstance()->getSettings(),
      // ]);

    // } catch (ClientException $e) {

    //   Craft::$app->getSession()->setError("Failed to send deployment request to Laravel Forge. Please check your API key.");

    // } catch (\Exception $e) {
      
    //   Craft::$app->getSession()->setError("An error occurred while fetching pages from Laravel Forge. $e");

    // }

    // Craft::dd("Action Load List Deployment Controller.");
  }

}