<?php

echo $view->fieldset()->setAttribute('template', $T('Mailbox access protocols'))
    ->insert(
        $view->checkbox('ImapStatus', 'enabled')
        ->setAttribute('uncheckedValue', 'disabled')
    )
    ->insert(
        $view->checkbox('PopStatus', 'enabled')
        ->setAttribute('uncheckedValue', 'disabled')
    )
    ->insert(
        $view->checkbox('TlsSecurity', 'optional')
        ->setAttribute('uncheckedValue', 'required')
    )
;

echo $view->fieldset()->setAttribute('template', $T('Disk space'))
    ->insert($view->radioButton('QuotaStatus', 'disabled'))
    ->insert($view->fieldsetSwitch('QuotaStatus', 'enabled', $view::FIELDSETSWITCH_EXPANDABLE)
        ->insert(
            $view->slider('QuotaDefaultSize', $view::SLIDER_ENUMERATIVE | $view::LABEL_ABOVE)
            ->setAttribute('label', $T('Quota default size ${0}'))
        ))
;

echo $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_HELP);

