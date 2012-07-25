<?php

echo $view->fieldset()->setAttribute('template', $T('Mailbox access protocols'))
;

echo $view->fieldsetSwitch('QuotaStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX)->setAttribute('uncheckedValue', 'disabled')
    ->insert($view->slider('QuotaDefaultSize', $view::SLIDER_ENUMERATIVE | $view::LABEL_ABOVE)->setAttribute('label', $T('Quota default size ${0}')))
;

echo $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_CANCEL | $view::BUTTON_HELP);

