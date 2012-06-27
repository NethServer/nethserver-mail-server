<?php
namespace NethServer\Module\User\Plugin;

/*
 * Copyright (C) 2011 Nethesis S.r.l.
 * 
 * This script is part of NethServer.
 * 
 * NethServer is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 * 
 * NethServer is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with NethServer.  If not, see <http://www.gnu.org/licenses/>.
 */

use Nethgui\System\PlatformInterface as Validate;
use Nethgui\Controller\Table\Modify as Table;

/**
 * Email user plugin
 * 
 * @since 1.0
 * @author Davide Principi <davide.principi@nethesis.it> 
 */
class Mail extends \Nethgui\Controller\Table\RowPluginAction
{

    protected function initializeAttributes(\Nethgui\Module\ModuleAttributesInterface $base)
    {
        return \Nethgui\Module\SimpleModuleAttributesProvider::extendModuleAttributes($base, 'Service', 30);
    }

    public function initialize()
    {
        $quotaValidator1 = $this->createValidator()->greatThan(0)->lessThan(501);
        $quotaValidator2 = $this->createValidator()->equalTo('unlimited');
                    
        $this->setSchemaAddition(array(
            array('MailStatus', Validate::SERVICESTATUS, Table::FIELD),
            array('MailQuotaType', $this->createValidator()->memberOf('custom', 'default'), Table::FIELD),
            array('MailQuotaCustom', $this->createValidator()->orValidator($quotaValidator1, $quotaValidator2), Table::FIELD),
            array('MailForwardStatus', Validate::SERVICESTATUS, Table::FIELD),
            array('MailForwardAddress', Validate::ANYTHING, Table::FIELD), // FIXME implement EMAIL ADDRESS validator
            array('MailForwardKeepMessageCopy', Validate::YES_NO, Table::FIELD)
        ));
        $this->setDefaultValue('MailStatus', 'enabled');
        parent::initialize();
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);
        if ( ! $this->getRequest()->isMutation()) {
            $h = array();
            for($i = 1; $i <= 50; $i += ($i === 1) ? 4 : 5) {
                $h[$i * 10] = $i . ' GB';
            }
            
            $h['unlimited'] = $view->translate('Unlimited_quota');
            
            $view['MailQuotaCustomDatasource'] = \Nethgui\Renderer\AbstractRenderer::hashToDatasource($h);
        } else {
            $view['MailQuotaCustomDatasource'] = array();
        }
    }

}