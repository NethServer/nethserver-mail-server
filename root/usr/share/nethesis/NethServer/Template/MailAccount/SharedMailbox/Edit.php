<?php
/* @var $view \Nethgui\Renderer\Xhtml */

if ($view->getModule()->getIdentifier() === 'create') {
    $headerText = $T('SharedMailbox_create_header');
} else {
    $headerText = $T('SharedMailbox_modify_header');
}

echo $view->header('Name')->setAttribute('template', $headerText);

echo $view->textInput('Name');

echo $view->fieldset()->setAttribute('template', $T('OwnersSelector_label'))
        ->insert($view->objectPicker('Owners')->setAttribute('objects', 'OwnersDatasource'))
;

echo $view->fieldset()->setAttribute('template', $T('Others_label'))
        ->insert($view->textList('Others'));
;


echo $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_CANCEL | $view::BUTTON_HELP);
