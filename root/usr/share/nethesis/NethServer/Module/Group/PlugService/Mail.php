<?php
namespace NethServer\Module\Group\PlugService;

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
        return \Nethgui\Module\SimpleModuleAttributesProvider::extendModuleAttributes($base, 'PlugService', 30);
    }

    public function initialize()
    {
        $this->declareParameter('CreateMailAddresses', Validate::SERVICESTATUS);

        $this->setSchemaAddition(array(
            array('MailStatus', Validate::SERVICESTATUS, Table::FIELD),
            array('MailDeliveryType', $this->createValidator()->memberOf('copy', 'shared'), Table::FIELD),
        ));
        $this->setDefaultValue('MailStatus', 'disabled');
        $this->setDefaultValue('MailDeliveryType', 'copy');
        parent::initialize();
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);

        if ($this->hasAdapter()) {
            $view['MailAddressList'] = new \NethServer\Module\Pseudonym\AccountPseudonymIterator($this->getAdapter()->getKeyValue(), $this->getPlatform());
            if ($this->getPluggableActionIdentifier() === 'create') {
                $view['CreateMailAddresses'] = 'enabled';
            }
        }
    }

    protected function onParametersSaved($changedParameters)
    {
        if ($this->parameters['CreateMailAddresses'] === 'enabled') {
            $this->getPlatform()->signalEvent('group-create-pseudonyms@post-process', array($this->getAdapter()->getKeyValue()));
        }
    }

}