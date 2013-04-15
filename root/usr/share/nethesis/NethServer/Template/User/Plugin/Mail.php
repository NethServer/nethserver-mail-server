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

/*
 * The jsCode below updates the mail address list with values from the
 * FirstName and LastName fields.
 */
$jsCode = <<<"EOJSCODE"
jQuery(document).ready(function($) {

    // The update view handler, invoked when the tab Service is shown:
    var updateMailAddresses = function() {
        var parts = [
            $('#User_create_FirstName').val(), 
            $('#User_create_LastName').val()
        ];

        if( ! parts[1]) {
            parts.splice(1);
        }

        if( ! parts[0]) {
            parts.splice(0);
        }

        var addressPart = parts.join('.').toLowerCase();

        $('.CreateMailAddresses li').each(function(index, node) {
            var address = $(node).text();
            $(node).text(addressPart + address.substr(address.lastIndexOf('@')));
        });

    }

    $('.CreateMailAddresses').parents('.Tabs').first().bind('tabsshow', updateMailAddresses);

    updateMailAddresses();
});
EOJSCODE;

if ($view->getModule()->getPluggableActionIdentifier() === 'create') {
    $view->includeJavascript($jsCode);
    $mailAddresses = $view->fieldsetSwitch('CreateMailAddresses', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
        ->setAttribute('uncheckedValue', 'disabled')
        ->insert($view->textList('MailAddressList')->setAttribute('tag', 'div.CreateMailAddresses labeled-control/ul/li'));
} else {
    $mailAddresses = $view->fieldset()->setAttribute('template', $T('MailAddressList_label'))
        ->insert($view->textList('MailAddressList'));
}

echo $view->fieldsetSwitch('MailStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($forwardPanel)
    ->insert($quotaPanel)
    ->insert($spamRetentionPanel)
    ->insert($mailAddresses)
;


