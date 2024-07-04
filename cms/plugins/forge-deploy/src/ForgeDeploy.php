<?php

namespace wl\craftforgedeploy;

use Craft;
use craft\base\Model;
use craft\base\Plugin;
use wl\craftforgedeploy\models\Settings;    
use craft\elements\Entry;
use craft\events\DefineHtmlEvent;
use craft\helpers\UrlHelper;
use craft\events\RegisterCpNavItemsEvent;
use craft\web\twig\variables\Cp;
use yii\base\Event;

/**
 * forge-deploy plugin
 *
 * @method static ForgeDeploy getInstance()
 * @method Settings getSettings()
 * @author wl <alejandro@wiedemannlampe.com>
 * @copyright wl
 * @license MIT
 */
class ForgeDeploy extends Plugin
{
    public string $schemaVersion = '1.0.0';

    public bool $hasCpSection = true;

    public bool $hasCpSettings = true;

    public function getCpNavItem(): ?array
    {
        $item = parent::getCpNavItem();
        $item['label'] = "Forge Deploy";
        return $item;
    }

    public static function config(): array
    {
        return [
            'components' => [
                // Define component configs here...
            ],
        ];
    }



    public function init(): void
    {
        parent::init();

         /** @var SettingsModel $settings */
         $settings = $this->getSettings();
         $this->hasCpSection = $settings->forgeDeployEnabled;

        // Defer most setup tasks until Craft is fully initialized
        Craft::$app->onInit(function() {
            $this->attachEventHandlers();
            // ...
        });

        // Event::on(
        //     Entry::class,
        //     Entry::EVENT_DEFINE_SIDEBAR_HTML,
        //     function(DefineHtmlEvent $event) {
        
        //         /** @var Entry $entry */
        //         $entry = $event->sender;
        
        //         // Make sure this is the correct section
        //         if ($entry->sectionId == 5)
        //         {
        //             // Return the button HTML
        //             $url = UrlHelper::url('some/path/' . $entry->id);
        //             $event->html .= '<a href="' . $url . '" class="btn">My Button!</a>';
        //         }
        
        //     }
        // );

        Event::on(
            Cp::class,
            Cp::EVENT_REGISTER_CP_NAV_ITEMS,
            function(RegisterCpNavItemsEvent $event) {
                $event->navItems[] = [
                    'url' => 'section-url',
                    'label' => 'Section Label',
                ];
            }
        );
    }

    protected function createSettingsModel(): ?Model
    {
        return Craft::createObject(Settings::class);
    }

    public function getSettingsResponse(): mixed
    {
        // $url = \craft\helpers\UslHelper::actionUrl('forge-deploy/')
        return Craft::$app
            ->controller
            ->renderTemplate('forge-deploy/deploy_settings',[
            'plugin' => $this,
            'settings' => $this->getSettings(),
        ]);
    }

    // protected function settingsHtml(): ?string
    // {
    //     return Craft::$app->view->renderTemplate('forge-deploy/deploy_settings', [
    //         'plugin' => $this,
    //         'settings' => $this->getSettings(),
    //     ]);
    // }

    private function attachEventHandlers(): void
    {
        // Register event handlers here ...
        // (see https://craftcms.com/docs/4.x/extend/events.html to get started)
    }
}
