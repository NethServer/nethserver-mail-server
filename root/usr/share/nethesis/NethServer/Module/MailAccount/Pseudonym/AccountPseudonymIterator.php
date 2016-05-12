<?php
namespace NethServer\Module\MailAccount\Pseudonym;

/*
 * Copyright (C) 2013 Nethesis S.r.l.
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
 * TODO: add component description here
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 * @since 1.0
 */
class AccountPseudonymIterator implements \IteratorAggregate
{
    /**
     *
     * @var \Nethgui\System\PlatformInterface
     */
    private $platform;

    /**
     *
     * @var string
     */
    private $account;

    public function __construct($account, \Nethgui\System\PlatformInterface $platform)
    {
        $this->platform = $platform;
        $this->account = $account;
    }

    private function getLocalDomains()
    {
        static $localDomains;

        if ( ! isset($localDomains)) {
            $localDomains = array();

            foreach ($this->platform->getDatabase('domains')->getAll('domain') as $domainKey => $domainRecord) {
                if (isset($domainRecord['TransportType']) && $domainRecord['TransportType'] === 'LocalDelivery') {
                    $localDomains[] = $domainKey;
                }
            }
        }

        return $localDomains;
    }

    private function getPseudonymList()
    {
        static $pseudonymList;

        if ( ! isset($pseudonymList)) {
            $pseudonymList = new \ArrayObject();

            if ($this->account) {
                // Temporary native array to manipulate
                $tmpList = array();

                // Find all pseudonyms (mail addresses) that point to this account:
                foreach ($this->platform->getDatabase('accounts')->getAll('pseudonym') as $pseudonymKey => $pseudonymRecord) {
                    if ( ! isset($pseudonymRecord['Account']) || $pseudonymRecord['Account'] !== $this->account) {
                        // skip unrelated records
                        continue;
                    }

                    // Expand domain-less pseudonyms, if required:
                    if (preg_match('/@$/', $pseudonymKey)) {
                        foreach ($this->getLocalDomains() as $domain) {
                            $tmpList[] = $pseudonymKey . $domain;
                        }
                    } else {
                        $tmpList[] = (string) $pseudonymKey;
                    }

                    $pseudonymList->exchangeArray(array_values(array_unique($tmpList)));
                }

            } else {
                $pseudonymList = new \ArrayObject(array_map(function ($domain) {
                        return '@' . $domain;
                    }, $this->getLocalDomains()));
            }

            $pseudonymList->asort();
        }

        return $pseudonymList;
    }

    public function getIterator()
    {
        return $this->getPseudonymList();
    }

}