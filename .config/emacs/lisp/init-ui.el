;;; init-ui.el --- Emacs lisp settings, and common config for other lisps -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

; theme
(use-package dracula-theme
  :ensure t
  :config (load-theme 'dracula t))

; status-line
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(global-display-line-numbers-mode 1)              ; 在 Window 显示行号
(tool-bar-mode -1)                                ; 关闭 Tool bar
(when (display-graphic-p) (toggle-scroll-bar -1)) ; 图形界面时关闭滚动条
(add-to-list 'default-frame-alist '(width . 90))  ; 设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 55)) ; 设定启动图形界面时的初始 Frame 高度（字符数）
(setq display-line-numbers-type 'relative)        ; 显示相对行号
(setq inhibit-startup-message t)                  ; 关闭启动 Emacs 时的欢迎界面
(column-number-mode t)                            ; 在 Mode line 上显示列号

(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font Mono-18"))
(set-face-attribute 'default t :font "JetBrainsMono Nerd Font Mono-18")

(provide 'init-ui)
;;; init-ui.el ends here
