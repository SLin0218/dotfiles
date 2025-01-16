;;; init-ui.el --- Emacs lisp settings, and common config for other lisps -*- lexical-binding: t -*-
;;; Commentary:
;;; Code:

(tool-bar-mode -1)                                              ; 关闭 Tool bar
(menu-bar-mode -1)                                              ; 关闭 Menu bar
(global-display-line-numbers-mode 1)                            ; 在 Window 显示行号
(when (display-graphic-p) (toggle-scroll-bar -1))               ; 图形界面时关闭滚动条
(add-to-list 'default-frame-alist '(width . 90))                ; 设定启动图形界面时的初始 Frame 宽度（字符数）
(add-to-list 'default-frame-alist '(height . 55))               ; 设定启动图形界面时的初始 Frame 高度（字符数）
(add-to-list 'default-frame-alist '(drag-internal-border . 1))  ; 内部边框允许鼠标拖动
(add-to-list 'default-frame-alist '(internal-border-width . 5)) ; 内部边框像素
(add-hook 'window-setup-hook #'toggle-frame-maximized)          ; 最大化窗口
(setq display-line-numbers-type 'relative)                      ; 显示相对行号
(setq inhibit-startup-message t)                                ; 关闭启动 Emacs 时的欢迎界面
(column-number-mode t)                                          ; 在 Mode line 上显示列号

; theme
(use-package dracula-theme
  :ensure t
  :config (load-theme 'dracula t))

; status-line
(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1))

(use-package dashboard
 :ensure t
 :config
 (setq dashboard-banner-logo-title "Welcome to Emacs!") ;; 个性签名，随读者喜好设置
 ;; (setq dashboard-projects-backend 'projectile) ;; 读者可以暂时注释掉这一行，等安装了 projectile 后再使用
 (setq dashboard-startup-banner 'official)              ;; 也可以自定义图片
 (setq dashboard-items '((recents . 5)                  ;; 显示多少个最近文件
  (bookmarks . 5)                                       ;; 显示多少个最近书签
  (projects . 10)))                                     ;; 显示多少个最近项目
 (dashboard-setup-startup-hook))

(cond
 ;; macOS
 ((eq system-type 'darwin)
  (add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font Mono-16"))
  (set-face-attribute 'default t :font "JetBrainsMono Nerd Font Mono-16"))
 ;; Linux
 ((eq system-type 'gnu/linux)
  (add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font Mono-10"))
  (set-face-attribute 'default t :font "JetBrainsMono Nerd Font Mono-10")))

(provide 'init-ui)
;;; init-ui.el ends here
