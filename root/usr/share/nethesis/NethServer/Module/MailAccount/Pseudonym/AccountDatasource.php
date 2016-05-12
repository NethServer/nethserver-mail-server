<?php
namespace NethServer\Module\MailAccount\Pseudonym;

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

/**
 * 
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 * @since 1.0
 */
class AccountDatasource implements \IteratorAggregate
{
    /**
     *
     * @var \Nethgui\Module\ModuleInterface
     */
    private $module;

    /**
     *
     * @var \Nethgui\View\TranslatorInterface
     */
    private $translator;
    private $current;

    public function __construct(\Nethgui\Module\ModuleInterface $module, \Nethgui\View\TranslatorInterface $translator, $current)
    {
        $this->module = $module;
        $this->translator = $translator;
        $this->current = $current;
        if ( ! $this->module instanceof \Nethgui\System\PlatformConsumerInterface) {
            throw new \UnexpectedValueException(sprintf('%s: the module must be an instance of PlatformConsumerInterface', __CLASS__), 1343144050);
        }
    }

    public function getDatasource()
    {
        $userProvider = new \NethServer\Tool\UserProvider($this->module->getPlatform());
        $mbxProvider = new \NethServer\Module\MailAccount\SharedMailbox\SharedMailboxAdapter($this->module->getPlatform());

        $users = $userProvider->getUsers();
        
        $hash = array();

        $keyFound = FALSE;

        foreach ($users as $key => $prop) {
            $hash[$key] = $key;
            if ($this->current === $key) {
                $keyFound = TRUE;
            }
        }

        foreach($mbxProvider->getSharedMailboxList() as $mbx) {
            $hash['vmail+' . $mbx['name']] = $mbx['name'];
        }

        if ( $keyFound === FALSE && ! is_null($this->current)) {
            $hash[$this->current] = $this->current;
        }

        return \Nethgui\Renderer\AbstractRenderer::hashToDatasource($hash, TRUE);
    }

    public function getIterator()
    {
        return new \ArrayIterator($this->getDatasource());
    }

}