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
  (rime-user-data-dir (if (eq system-type 'darwin) "~/Library/Rime" "~/.local/share/fcitx5/rime"))
  (rime-posframe-style 'horizontal)
  (rime-show-candidate 'posframe)
  (rime-share-data-dir
   (cond
    ((bound-and-true-p nix-rime-share-data-path)
     (expand-file-name "share/rime-data" nix-rime-share-data-path))
    ((eq system-type 'darwin)
     "/Library/Input Methods/Squirrel.app/Contents/SharedSupport")
    (t "/usr/share/rime-data")))
  (rime-emacs-module-header-root
   (let* ((elpa-dir (file-name-as-directory package-user-dir))
          (liberime-dirs (and (file-directory-p elpa-dir)
                              (directory-files elpa-dir t "^liberime-[0-9]")))
          (latest-liberime-dir (car (last (sort liberime-dirs 'string<)))))
     (when latest-liberime-dir
       (expand-file-name (number-to-string emacs-major-version)
                         (expand-file-name "emacs-module" latest-liberime-dir)))))
  :config
  (setq rime-disable-predicates
        '(rime-predicate-evil-mode-p)))

;; macOS 修饰键定义 (Command -> Meta, Option -> Super)
(when (eq system-type 'darwin)
  (setq mac-command-modifier 'meta
        mac-option-modifier 'super))

(provide 'init-input)
;;; init-input.el ends here
