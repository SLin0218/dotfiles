;;; init-input.el --- Input method and system modifier keys configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; emacs-rime 中文输入法配置以及系统按键映射。
;;

;;; Code:

;; Rime (emacs-rime) 输入法配置
;; (use-package rime
;;   :init
;;   (when (bound-and-true-p nix-librime-path)
;;     (setq rime-librime-root nix-librime-path))
;;   :custom
;;   (default-input-method "rime")
;;   (rime-user-data-dir "~/.config/rime")
;;   (rime-posframe-style 'horizontal)
;;   (rime-show-candidate 'posframe)
;;   (rime-share-data-dir
;;    (cond
;;     ((bound-and-true-p nix-rime-share-data-dir)
;;      nix-rime-share-data-dir)
;;     ((bound-and-true-p nix-rime-share-data-path)
;;      (expand-file-name "share/rime-data" nix-rime-share-data-path))
;;     ((and (bound-and-true-p nix-librime-path)
;;           (file-directory-p (expand-file-name "share/rime-data" nix-librime-path)))
;;      (expand-file-name "share/rime-data" nix-librime-path))
;;     ((eq system-type 'darwin)
;;      "/Library/Input Methods/Squirrel.app/Contents/SharedSupport")
;;     (t "/usr/share/rime-data")))
;;   :config
;;   (when (bound-and-true-p nix-librime-path)
;;     (setq rime-librime-root nix-librime-path))
;;   (when (bound-and-true-p nix-rime-share-data-dir)
;;     (setq rime-share-data-dir nix-rime-share-data-dir))
;;   ;; 跨平台自动探测 emacs-module.h 头文件路径
;;   (setq rime-emacs-module-header-root
;;         (seq-find (lambda (dir)
;;                     (and dir (file-exists-p (expand-file-name "emacs-module.h" dir))))
;;                   (list (expand-file-name "../include" data-directory)
;;                         (expand-file-name "../../../include" data-directory)
;;                         (when (bound-and-true-p nix-emacs-dir)
;;                           (file-name-concat nix-emacs-dir "include"))
;;                         "/Applications/Emacs.app/Contents/Resources/include"
;;                         "/opt/homebrew/include"
;;                         "/usr/local/include")))
;;   (setq rime-disable-predicates
;;         '(rime-predicate-evil-mode-p)))

(provide 'init-input)
;;; init-input.el ends here
