<?php
namespace NethServer\Module;

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
 * Pseudonyms -- Manage mail aliases and mail boxes
 *
 * @author Davide Principi <davide.principi@nethesis.it>
 * @since 1.0
 */
class Pseudonym extends \Nethgui\Controller\TableController
{

    protected function initializeAttributes(\Nethgui\Module\ModuleAttributesInterface $base)
    {
        return \Nethgui\Module\SimpleModuleAttributesProvider::extendModuleAttributes($base, 'Management', 25);
    }

    public function initialize()
    {
        $columns = array(
            'Key',
            'Account',
            'Flag',
            'Actions'
        );

        $this
            ->setTableAdapter($this->getPlatform()->getTableAdapter('accounts', 'pseudonym'))
            ->setColumns($columns)
            ->addTableAction(new Pseudonym\Modify('create'))
            ->addTableAction(new \Nethgui\Controller\Table\Help('Help'))
            ->addRowAction(new Pseudonym\Modify('update'))
            ->addRowAction(new Pseudonym\Modify('delete'))
        ;
        parent::initialize();
    }


    public function prepareViewForColumnFlag(\Nethgui\Controller\Table\Read $action, \Nethgui\View\ViewInterface $view, $key, $values, &$rowMetadata)
    {
        $flag = '';
        if($values['Access'] === 'private') {
            $rowMetadata['rowCssClass'] = trim($rowMetadata['rowCssClass'] . ' user-new');
            $flag .= 'P';
        } else {
            $flag .= '-';
        }

        return $flag;
    }

}
