#lang s-exp framework/keybinding-lang

#|
Emacs:
* uncheck the __Enable keybindings__ in menus Preferences>Editing>General Editing.
* check the __Treat alt as meta__ in Preferences>Editing>General Editing.
* Edit>Keybindings>Add User-defined Keybindings...
|#


;(keybinding "c:x;k" (λ (editor evt) (send editor close-current-tab) ))
(keybinding "esc;tab" (λ (editor event) (send editor auto-complete)))





