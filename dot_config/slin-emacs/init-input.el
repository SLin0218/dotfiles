;;; init-input.el --- Input method and system modifier keys configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; emacs-rime 中文输入法配置以及系统按键映射。
;;

;;; Code:

;; Rime (emacs-rime) 输入法配置
(use-package rime
  :init
  (when (bound-and-true-p nix-librime-path)
    (setq rime-librime-root nix-librime-path))
  :custom
  (default-input-method "rime")
  (rime-user-data-dir "~/.config/rime")
  (rime-posframe-style 'horizontal)
  (rime-show-candidate 'posframe)
  (rime-share-data-dir
   (cond
    ((bound-and-true-p nix-rime-share-data-path)
     (expand-file-name "share/rime-data" nix-rime-share-data-path))
    ((and (bound-and-true-p nix-librime-path)
          (file-directory-p (expand-file-name "share/rime-data" nix-librime-path)))
     (expand-file-name "share/rime-data" nix-librime-path))
    ((eq system-type 'darwin)
     "/Library/Input Methods/Squirrel.app/Contents/SharedSupport")
    (t "/usr/share/rime-data")))
  :config
  (when (bound-and-true-p nix-librime-path)
    (setq rime-librime-root nix-librime-path))
  (when (eq system-type 'gnu/linux)
    (setq rime-emacs-module-header-root (file-name-concat nix-emacs-dir "include"))
    (setq rime-share-data-dir nix-rime-share-data-dir))
  (setq rime-disable-predicates
        '(rime-predicate-evil-mode-p)))

(provide 'init-input)
;;; init-input.el ends here
