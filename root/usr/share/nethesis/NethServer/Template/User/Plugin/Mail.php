<?php

$quotaPanel = $view->fieldset()->setAttribute('template', $T('Quota'))
    ->insert($view->radioButton('MailQuotaType', 'default'))
    ->insert($view->fieldsetSwitch('MailQuotaType', 'custom', $view::FIELDSETSWITCH_EXPANDABLE)->insert($view->textInput('MailQuotaCustom')))
    ->insert($view->radioButton('MailQuotaType', 'unlimited'))
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


