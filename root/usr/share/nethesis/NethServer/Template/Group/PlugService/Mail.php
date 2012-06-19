<?php
echo $view->fieldsetSwitch('MailStatus', 'enabled', $view::FIELDSETSWITCH_CHECKBOX | $view::FIELDSETSWITCH_EXPANDABLE)
    ->setAttribute('uncheckedValue', 'disabled')
    ->insert($view->radioButton('MailDeliveryType', 'copy'))
    ->insert($view->radioButton('MailDeliveryType', 'shared'))
;


