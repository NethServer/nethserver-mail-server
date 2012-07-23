<?php

if ($view->getModule()->getIdentifier() == 'update') {
    $headerText = 'Edit pseudonym `${0}`';
    $keyWidgets = '';
} else {
    $headerText = 'Create a new pseudonym';

    $keyWidgets = $view->panel()->setAttribute('class', 'labeled-control label-above');

    $keyWidgets
        ->insert($view->literal('<label>' . $T('pseudonym_label'). '</label>'))
        ->insert($view->textInput('localAddress', $view::LABEL_NONE))
        ->insert($view->literal(' @ '))
        ->insert($view->selector('domainAddress', $view::SELECTOR_DROPDOWN | $view::LABEL_NONE))
    ;
}

echo $view->header('pseudonym')->setAttribute('template', $view->translate($headerText));
echo $keyWidgets;
echo $view->textInput('Description');
echo $view->selector('Account', $view::SELECTOR_DROPDOWN)->setAttribute('choices', 'AccountDatasource');
echo $view->checkbox('Access', 'private')->setAttribute('uncheckedValue', 'public');

echo $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_CANCEL | $view::BUTTON_HELP);



