#lang s-exp framework/keybinding-lang

#|
Emacs:
* uncheck the __Enable keybindings__ in menus preference.
* Edit>Keybindings>Add User-defined Keybindings...
|#


;(keybinding "c:x;k" (λ (editor evt) (send editor close-current-tab) ))
(keybinding "esc;tab" (λ (editor event) (send editor auto-complete)))





