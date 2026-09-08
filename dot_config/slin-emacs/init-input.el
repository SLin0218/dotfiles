;;; init-input.el --- Input method and system modifier keys configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; emacs-rime 中文输入法配置以及 macOS 系统按键映射。
;;

;;; Code:

;; Rime (emacs-rime) 输入法配置
(use-package rime
  :custom
  (default-input-method "rime")
  (rime-user-data-dir "~/.config/rime")
  (rime-posframe-style 'horizontal)
  (rime-show-candidate 'posframe)
  :config
  (setq rime-disable-predicates
        '(rime-predicate-evil-mode-p)))

(provide 'init-input)
;;; init-input.el ends here
