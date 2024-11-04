;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
(defconst is-mac (eq system-type 'darwin))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(save-place-mode 1)

(setq confirm-kill-emacs nil ; 关闭 emacs 时无需额外确认
      system-time-locale "C" ; 设置系统时间显示方式
      pop-up-windows nil     ; no pop-up window
      scroll-margin 2        ; It's nice to maintain a little margin
      widget-image-enable nil)

(setq user-full-name "DengShilin"
      user-mail-address "dengsl.dev@gmail.com"
      org-directory "~/org/"
      org-agenda-files '("~/org/agenda/")
      doom-theme 'catppuccin
      display-line-numbers-type 'relative
      ;; 隐藏 title bar
      default-frame-alist '((undecorated . t))
      ;; 默认字体
      doom-font (font-spec :family "JetbrainsMono Nerd Font" :size (if is-mac 14 16)))

(setq fancy-splash-image "~/.config/doom/gnu_color.svg")
(setq +doom-dashboard-menu-sections nil)
(defun doom-dashboard-widget-shortmenu ())
(defun doom-dashboard-widget-footer ())
(defun doom-dashboard-widget-loaded ()
(when doom-init-time
  (insert
   ""
   (propertize
    (+doom-dashboard--center
     +doom-dashboard--width
     "welcome home")
    'face 'doom-dashboard-loaded)
   "\n")))

(add-to-list 'default-frame-alist '(drag-internal-border . 1))
(add-to-list 'default-frame-alist '(internal-border-width . 5))

(add-hook 'window-setup-hook #'toggle-frame-maximized) ; 最大化窗口

(use-package org-faces
  :config
  (when (display-graphic-p) (set-face-attribute 'org-table nil :family "Sarasa Term SC Nerd")))

(after! org
  ;; 完成时删除样式
  (set-face-attribute 'org-headline-done nil :strike-through t))

(use-package org
  :custom
  (org-todo-keywords '((sequence "TODO" "NEXT" "WAITING" "CANCELLED" "DONE")))
  (org-pretty-entities t)
  ;; 自动标记完成时间
  (org-log-done t)
  ;; 行间距
  (line-spacing 0.25)
  :config
  ;; 导出 html 配置
  (setq org-ellipsis " ⤵")          ; 折叠缩略图标
  (setq org-html-coding-system 'utf-8)
  (setq org-html-doctype "html5")
  (setq org-html-head "<link rel='stylesheet' type='text/css' href='https://gongzhitaao.org/orgcss/org.css'/> ")
  (setq org-hide-emphasis-markers t) ; 隐藏 ~~ ==
  (setq org-todo-keywords '((sequence "TODO" "DOING" "DONE" "WAITING" "CANCELLED" "HOLD"))))

(use-package org-superstar
  :after org
  :hook (org-mode . org-superstar-mode)
  :custom
  (org-superstar-headline-bullets-list '("⁖" "◉" "○" "✸" "✿"))
  (org-superstar-todo-bullet-alist '(("TODO" . ?☐)
                                     ("NEXT" . ?✒)
                                     ("HOLD" . ?✰)
                                     ("WAITING" . ?☕)
                                     ("CANCELLED" . ?✘)
                                     ("DONE" . ?✔)))
  (org-superstar-item-bullet-alist '((?* . ?•)
                                     (?+ . ?➤)
                                     (?- . ?•)))
  (org-superstar-special-todo-items t)
  (org-superstar-remove-leading-stars t)
  (org-hide-leading-stars t))

(when (display-graphic-p)
(setq-default prettify-symbols-alist '(("#+title:" . "📖")
                                       ("#+author:" . "👦")
                                       ("#+caption:" . "☰")
                                       ("#+results:" . "🎁")
                                       ("#+attr_latex:" . "🍄")
                                       ("#+attr_org:" . "🔔")
                                       ("#+date:" . "🗓")
                                       ("#+property:" . "☸")
                                       (":PROPERTIES:" . "⚙")
                                       (":END:" . ".")
                                       ("[ ]" . "☐")
                                       ("[X]" . "☑︎")
                                       ("#+options:" . "⌥")
                                       ("\\pagebreak" . 128204)
                                       ("#+begin_quote" . "❮")
                                       ("#+end_quote" . "❯")
                                       ("#+BEGIN_Highlight" . "📖")
                                       ("#+END_Highlight" . "📜")
                                       ("#+begin_src" . "⏩")
                                       ("#+end_src" . "⏪")))
)


(add-hook! 'org-mode-hook 'prettify-symbols-mode)

(map! :leader
      "/" #'comment-line
      "x" #'kill-current-buffer)
