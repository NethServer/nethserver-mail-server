<?php

namespace NethServer\Module\MailAccount\SharedMailbox;

/*
 * Copyright (C) 2016 Nethesis Srl
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

use Nethgui\System\PlatformInterface as Validate;

/**
 * Create and modify a SharedMailbox
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 */
class Edit extends \Nethgui\Controller\Table\AbstractAction
{
    private $others = array();

    public function initialize()
    {
        parent::initialize();

        $ownersAdapter = $this->getPlatform()->getMapAdapter(array($this, 'readOwners'), NULL, array());

        $this->declareParameter('Name', Validate::NOTEMPTY);
        $this->declareParameter('NewName', FALSE);
        $this->declareParameter('Owners', $this->createValidator()->collectionValidator($this->createValidator(Validate::NOTEMPTY)), $ownersAdapter);
    }

    public function readOwners()
    {
        static $owners;

        if (isset($owners)) {
            return $owners;
        }

        $proc = $this->getPlatform()->exec('/usr/bin/sudo /usr/bin/doveadm -f tab acl get -u vmail ${@}', array($this->parameters['Name']));

        if ($proc->getExitCode() !== 0 || $proc->getOutput() === NULL) {
            return array();
        }

        $owners = array();
        $others = array();
        foreach (\Nethgui\array_rest($proc->getOutputArray()) as $line) {
            list($id, $global, $rights) = explode("\t", $line);
            if ($rights === 'admin create delete expunge insert lookup post read write write-deleted write-seen') {
                $owners[] = str_replace('group=', '', $id);
            } else {
                $this->others[] = preg_replace('/^(group=|user=)/', '', $id) . sprintf(' (%s)', $rights);
            }
        }

        return $owners;
    }

    public function bind(\Nethgui\Controller\RequestInterface $request)
    {
        parent::bind($request);
        if ($this->getIdentifier() !== 'create') {
            $this->parameters['Name'] = \Nethgui\array_end($request->getPath());
        }
        if ($this->getRequest()->isMutation()) {
            $this->parameters['NewName'] = $this->getRequest()->getParameter('Name');
        }
    }

    private function getChangeEventArgs()
    {
        $args = array($this->parameters['Name'], $this->parameters['NewName']);

        $owners = $this->readOwners();

        foreach ($this->parameters['Owners'] as $o) {
            $args[] = 'group=' . $o;
            $args[] = 'ADMIN';
        }

        foreach (array_diff($owners, $this->parameters['Owners']) as $o) {
            $args[] = 'group=' . $o;
            $args[] = 'CLEAR';
        }

        return $args;
    }

    public function process()
    {
        if ( ! $this->getRequest()->isMutation()) {
            return;
        }
        if ($this->getIdentifier() === 'create') {
            $this->getPlatform()->signalEvent('sharedmailbox-create', $this->getChangeEventArgs());
        } elseif ($this->getIdentifier() === 'update') {
            $this->getPlatform()->signalEvent('sharedmailbox-modify', $this->getChangeEventArgs());
        } elseif ($this->getIdentifier() === 'delete') {
            $this->getPlatform()->signalEvent('sharedmailbox-delete', array($this->parameters['Name']));
        }
    }

    private function getOwnersDatasource(\Nethgui\View\ViewInterface $view)
    {
        $gp = new \NethServer\Tool\GroupProvider($this->getPlatform());
        return array_map(function ($x) {
            return array($x, $x);
        }, array_keys($gp->getGroups()));
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);
        if ($this->getIdentifier() === 'create') {
            $view['OwnersDatasource'] = $this->getOwnersDatasource($view);
            $view->setTemplate('NethServer\Template\MailAccount\SharedMailbox\Edit');
        } elseif ($this->getIdentifier() === 'delete') {
            $view['__key'] = 'Name';  // tell what is the key parameter
            $view->setTemplate('Nethgui\Template\Table\Delete');
        } elseif ($this->getIdentifier() === 'update') {
            $view['OwnersDatasource'] = $this->getOwnersDatasource($view);
            $view['Others'] = $this->others;
            $view->setTemplate('NethServer\Template\MailAccount\SharedMailbox\Edit');
        }
    }

}
