<?php

/* @var $view \Nethgui\Renderer\Xhtml */

if ($view['QuotaStatus'] === 'enabled') {
    $quotaPanel = $view->fieldsetSwitch('MailQuotaType', 'custom', $view::FIELDSETSWITCH_EXPANDABLE
            | $view::FIELDSETSWITCH_CHECKBOX)->setAttribute('uncheckedValue', 'default')
        ->insert($view->slider('MailQuotaCustom', $view::LABEL_RIGHT | $view::SLIDER_ENUMERATIVE)
        ->setAttribute('label', '${0}')
        )
    ;
} else {
    $quotaPanel = $view->checkbox('MailQuotaType', 'default', $view::STATE_DISABLED);
}

$forwardPanel = $view->fieldsetSwitch('MailForwardStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($view->textInput('MailForwardAddress'))
    ->insert($view->checkbox('MailForwardKeepMessageCopy', 'yes')->setAttribute('uncheckedValue', 'no'))
;

$spamRetentionPanel = $view->fieldsetSwitch('MailSpamRetentionStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert(
    $view->slider('MailSpamRetentionTime', $view::LABEL_ABOVE | $view::SLIDER_ENUMERATIVE)
    ->setAttribute('label', $T('Hold for ${0}'))
    )
;


if ($view->getModule()->showPseudonymControls) {
    $createPseudonyms = $view->fieldsetSwitch('CreatePseudonyms', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
        ->setAttribute('uncheckedValue', 'disabled')
        ->insert($view->textList('DefaultPseudonyms')->setAttribute('tag', 'div.labeled-control/ul/li.DefaultMailAddress'));
} else {
    $createPseudonyms = $view->literal('');
}

echo $view->fieldsetSwitch('MailStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($forwardPanel)
    ->insert($quotaPanel)
    ->insert($spamRetentionPanel)
    ->insert($createPseudonyms)
;


