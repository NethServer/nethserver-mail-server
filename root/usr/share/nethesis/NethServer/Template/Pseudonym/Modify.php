<?php

if ($view->getModule()->getIdentifier() == 'update') {
    $keyFlags = $view::STATE_READONLY;
    $template = 'Edit pseudonym `${0}`';
} else {
    $keyFlags = 0;
    $template = 'Create a new pseudonym';
}

echo $view->header('pseudonym')->setAttribute('template', $view->translate($template));
echo $view->textInput('pseudonym', $keyFlags);
echo $view->textInput('Description');
echo $view->selector('Account', $view::SELECTOR_DROPDOWN)->setAttribute('choices', 'AccountDatasource');
echo $view->checkbox('Access', 'private')->setAttribute('uncheckedValue', 'public');

echo $view->buttonList($view::BUTTON_SUBMIT | $view::BUTTON_CANCEL | $view::BUTTON_HELP);



