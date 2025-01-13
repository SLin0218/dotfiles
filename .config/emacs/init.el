;;; init.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Commentary:

;; This file bootstraps the configuration, which is divided into
;; a number of other files.

;;;code:

;; Produce backtraces when errors occur: can be helpful to diagnose startup issues
;;(setq debug-on-error t)
(let ((minver "27.1"))
  (when (version< emacs-version minver)
    (error "Your Emacs is too old -- this config requires v%s or higher" minver)))
(when (version< emacs-version "28.1")
  (message "Your Emacs is old, and some functionality in this config will be disabled. Please upgrade if possible."))

(add-to-list 'load-path (expand-file-name "lisp" user-emacs-directory))
;(require 'init-benchmarking) ;; Measure startup time

(defconst *spell-check-support-enabled* nil) ;; Enable with t if you prefer
(defconst *is-a-mac* (eq system-type 'darwin))

;; Adjust garbage collection threshold for early startup (see use of gcmh below)
(setq gc-cons-threshold (* 128 1024 1024))

;; Process performance tuning
(setq read-process-output-max (* 4 1024 1024))
(setq process-adaptive-read-buffering nil)

(setq confirm-kill-emacs #'yes-or-no-p)      ; 在关闭 Emacs 前询问是否确认关闭，防止误触
(electric-pair-mode t)                       ; 自动补全括号
(add-hook 'prog-mode-hook #'show-paren-mode) ; 编程模式下，光标在括号上时高亮另一个括号
(global-auto-revert-mode t)                  ; 当另一程序修改了文件时，让 Emacs 及时刷新 Buffer
(delete-selection-mode t)                    ; 选中文本后输入文本会替换文本（更符合我们习惯了的其它编辑器的逻辑）
(setq make-backup-files nil)                 ; 关闭文件自动备份
(add-hook 'prog-mode-hook #'hs-minor-mode)   ; 编程模式下，可以折叠代码块
(savehist-mode 1)                            ; 打开 Buffer 历史记录保存

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3") ; 不加这一句可能有问题，建议读者尝试一下
(setq url-proxy-services '(("no_proxy" . "^\\(192\\.168\\..*\\)")
              ("http" . "127.0.0.1:7890")
   ("https" . "127.0.0.1:7890")))

(eval-when-compile
 (require 'use-package))

(require 'init-ui)
(require 'init-org)

(use-package evil
 :ensure t
 :init
 (setq evil-want-C-u-scroll t)               ; C-u 向上翻页
 (setq evil-complete-all-buffers nil)
 (evil-mode 1))

(use-package which-key
 :ensure t
 :init (which-key-mode))

; C-x C-f 补全
(use-package counsel
 :ensure)
(use-package ivy
 :ensure t
 :init
 (ivy-mode 1)
 (counsel-mode 1)
 :config
 (setq ivy-use-virtual-buffers t)
 (setq search-default-mode #'char-fold-to-regexp)
 (setq ivy-count-format "(%d/%d) "))

; 最近使用命令
(use-package amx
 :ensure t
 :init (amx-mode))

; 平滑滚动
(use-package good-scroll
 :ensure t
 :if window-system     ; 在图形化界面时才使用这个插件
 :init (good-scroll-mode))

; 彩虹括号
(use-package rainbow-delimiters
 :ensure t
 :hook (prog-mode . rainbow-delimiters-mode))

(setq custom-file "~/.config/emacs/custom.el")
(load custom-file)

(provide 'init)
;;; init.el ends here
