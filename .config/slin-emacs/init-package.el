(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

(add-to-list 'load-path (expand-file-name "lisp/awesome-tab" user-emacs-directory))
(add-to-list 'load-path (expand-file-name "lisp/lsp-bridge" user-emacs-directory))

(provide 'init-package)
