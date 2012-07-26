<?php
namespace NethServer\Module\Mail;

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
 * Change mailbox access parameters
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 * @since 1.0
 */
class Mailbox extends \Nethgui\Controller\AbstractController
{

    public function initialize()
    {
        $this->declareParameter('ImapStatus', Validate::SERVICESTATUS, array('configuration', 'dovecot', 'ImapStatus'));
        $this->declareParameter('PopStatus', Validate::SERVICESTATUS, array('configuration', 'dovecot', 'PopStatus'));
        $this->declareParameter('TlsSecurity', '/^(required|optional)$/', array('configuration', 'dovecot', 'TlsSecurity'));
        $this->declareParameter('QuotaStatus', Validate::SERVICESTATUS, array('configuration', 'dovecot', 'QuotaStatus'));
        $this->declareParameter('QuotaDefaultSize', Validate::POSITIVE_INTEGER, array('configuration', 'dovecot', 'QuotaDefaultSize'));
        parent::initialize();
    }

    public function prepareView(\Nethgui\View\ViewInterface $view)
    {
        parent::prepareView($view);
        if ( ! $this->getRequest()->isMutation()) {
            $h = array();
            for ($i = 1; $i <= 50; $i += ($i === 1) ? 4 : 5) {
                $h[$i * 10] = $i . ' GB';
            }
            $view['QuotaDefaultSizeDatasource'] = \Nethgui\Renderer\AbstractRenderer::hashToDatasource($h);
        } else {
            $view['QuotaDefaultSizeDatasource'] = array();
        }
    }

}
