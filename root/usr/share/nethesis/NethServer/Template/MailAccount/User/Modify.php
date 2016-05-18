<?php

/* @var $view \Nethgui\Renderer\Xhtml */

$quotaPanel = $view->fieldsetSwitch('MailQuotaType', 'custom', $view::FIELDSETSWITCH_EXPANDABLE
            | $view::FIELDSETSWITCH_CHECKBOX)->setAttribute('uncheckedValue', 'default')
        ->insert($view->slider('MailQuotaCustom', $view::LABEL_RIGHT | $view::SLIDER_ENUMERATIVE)
        ->setAttribute('label', '${0}')
        )
    ;

$forwardPanel = $view->fieldsetSwitch('MailForwardStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($view->textInput('MailForwardAddress'))
    ->insert($view->checkbox('MailForwardKeepMessageCopy', 'yes')->setAttribute('uncheckedValue', 'no'))
;

$slider = $view->slider('MailSpamRetentionTime', $view::LABEL_ABOVE | $view::SLIDER_ENUMERATIVE)->setAttribute('label', $T('Hold for ${0}'));
$spamRetentionPanel = $view->fieldsetSwitch('MailSpamRetentionStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($slider)
;



echo $view->panel()
    ->insert($view->checkBox('MailStatus', 'enabled')->setAttribute('uncheckedValue', 'disabled'))
    ->insert($forwardPanel)
    ->insert($quotaPanel)
    ->insert($spamRetentionPanel)
;

echo $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_CANCEL | $view::BUTTON_HELP);
