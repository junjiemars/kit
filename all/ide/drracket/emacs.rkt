#lang s-exp framework/keybinding-lang

#|
Emacs:
* uncheck the __Enable keybindings__ in menus preference.
* Edit>Keybindings>Add User-defined Keybindings...
|#

(keybinding "c:a:i" (λ (editor evt) (send editor auto-complete) ))




