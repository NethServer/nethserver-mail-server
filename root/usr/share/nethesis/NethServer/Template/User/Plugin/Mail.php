<?php

$quotaPanel = $view->fieldsetSwitch('MailQuotaType', 'custom', $view::FIELDSETSWITCH_EXPANDABLE
        | $view::FIELDSETSWITCH_CHECKBOX)->setAttribute('uncheckedValue', 'default')
    ->insert($view->slider('MailQuotaCustom', $view::LABEL_RIGHT | $view::SLIDER_ENUMERATIVE)
    ->setAttribute('label', '${0}')
    ->setAttribute('min', 1)
    ->setAttribute('max', 51)
    ->setAttribute('step', 5)
    )
;

$forwardPanel = $view->fieldsetSwitch('MailForwardStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($view->textInput('MailForwardAddress'))
    ->insert($view->checkbox('MailForwardKeepMessageCopy', 'yes')->setAttribute('uncheckedValue', 'no'))
;

echo $view->fieldsetSwitch('MailStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($quotaPanel)
    ->insert($forwardPanel)
;


