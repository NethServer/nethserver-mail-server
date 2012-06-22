<?php
namespace NethServer\Module\Pseudonym;

/*
 * Copyright (C) 2012 Nethesis S.r.l.
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
 * CRUD actions on Pseudonym records
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 * @since 1.0
 */
class Modify extends \Nethgui\Controller\Table\Modify
{

    public function initialize()
    {
        $parameterSchema = array(
            array('pseudonym', Validate::EMAIL, Table::KEY),
            array('Description', Validate::ANYTHING, Table::FIELD),
            array('Account', Validate::USERNAME, Table::FIELD),
            array('Access', $this->createValidator()->memberOf('public', 'private'), Table::FIELD),
        );

        $this->setSchema($parameterSchema);

        parent::initialize();
    }

    protected function calculateKeyFromRequest(\Nethgui\Controller\RequestInterface $request)
    {
        return trim($request->getParameter('localAddress')) . '@' . $request->getParameter('domainAddress');
    }

    public function validate(\Nethgui\Controller\ValidationReportInterface $report)
    {
        parent::validate($report);
        // we must explicitly validate the pseudonym parameter because is not posted with create request
        if ($this->getRequest()->isMutation() && $this->getIdentifier() === 'create') {
            if ($this->getValidator('pseudonym')->evaluate($this->parameters['pseudonym']) !== TRUE) {
                $report->addValidationError($this, 'localAddress', $this->getValidator('pseudonym'));
            }
        }
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);
        $templates = array(
            'create' => 'NethServer\Template\Pseudonym\Modify',
            'update' => 'NethServer\Template\Pseudonym\Modify',
            'delete' => 'Nethgui\Template\Table\Delete',
        );
        $view->setTemplate($templates[$this->getIdentifier()]);

        if ( ! $this->getRequest()->isMutation() && $this->getRequest()->isValidated()) {
            $view['AccountDatasource'] = $this->readAccountDatasource($view['Account'], $view);

            if ($this->getIdentifier() === 'create') {
                $view['domainAddressDatasource'] = $this->readDomainAddressDatasource();
            }
        }
    }

    public function onParametersSaved($changedParameters)
    {
        if ($this->getIdentifier() === 'update') {
            $event = 'modify';
        } else {
            $event = $this->getIdentifier();
        }
        $this->getPlatform()->signalEvent(sprintf('pseudonym-%s@post-process', $event), array($this->parameters['pseudonym']));
    }

    private function readDomainAddressDatasource()
    {
        $domains = array();

        foreach ($this->getPlatform()->getDatabase('domains')->getAll('domain') as $key => $prop) {
            $domains[] = array($key, $key);
        }

        return $domains;
    }

    private function readAccountDatasource($current, \Nethgui\View\ViewInterface $view)
    {
        $users = $this->getPlatform()->getDatabase('accounts')->getAll('user');
        $groups = $this->getPlatform()->getDatabase('accounts')->getAll('group');

        $hash = array();

        $keyFound = FALSE;

        $usersLabel = $view->translate('Users_label');
        $groupsLabel = $view->translate('Groups_label');

        foreach ($users as $key => $prop) {
            if ( ! isset($prop['MailStatus']) || $prop['MailStatus'] !== 'enabled') {
                continue;
            }
            $hash[$usersLabel][$key] = $prop['FirstName'] . ' ' . $prop['LastName'] . ' (' . $key . ')';
            if ($current === $key) {
                $keyFound = TRUE;
            }
        }

        foreach ($groups as $key => $prop) {
            if ( ! isset($prop['MailStatus']) || $prop['MailStatus'] !== 'enabled') {
                continue;
            }
            $hash[$groupsLabel][$key] = $prop['Description'] . ' (' . $key . ')';
            if ($current === $key) {
                $keyFound = TRUE;
            }
        }

        if ( ! $keyFound) {
            $hash[$view->translate('Current_label')][$current] = $current;
        }

        return \Nethgui\Renderer\AbstractRenderer::hashToDatasource($hash, TRUE);
    }

}
