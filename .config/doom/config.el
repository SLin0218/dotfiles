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
  (set-face-attribute 'org-headline-done nil :strike-through t)
  ;; 代码块缩进
  (setq org-src-tab-acts-natively t)
  (setq org-src-preserve-indentation nil)
  (setq org-fontify-quote-and-verse-blocks t)
  (custom-set-faces!
    '(org-document-title :height 1.2)))

(use-package org
  :custom
  (org-pretty-entities t)
  ;; 自动标记完成时间
  (org-log-done t)
  ;; 行间距
  (line-spacing 0.25)
  :config
  ;; org缩进
  (setq org-startup-indented t)
  (setq org-src-tab-acts-natively t)
  ;; 导出 html 配置
  (setq org-ellipsis " ⤵")          ; 折叠缩略图标
  (setq org-html-coding-system 'utf-8)
  (setq org-html-doctype "html5")
  (setq org-html-head "<link rel='stylesheet' type='text/css' href='https://gongzhitaao.org/orgcss/org.css'/> ")
  (setq org-appear-autoemphasis t)
  (setq  org-appear-autolinks nil)
  (setq org-hide-emphasis-markers t) ; 隐藏 ~~ ==
  (setq org-time-stamp-formats '("<%Y-%m-%d %a %H:%M:%S>" . "<%Y-%m-%d %a %H:%M:%S>"))
  (setq org-todo-keywords '((sequence "TODO" "NEXT" "DOING" "WAITING" "CANCELLED" "DONE")))
  (setq org-todo-keyword-faces
    '(("TODO" :foreground "#94e2d5")
      ("NEXT" :foreground "#94e2d5")
      ("DOING" :foreground "#94e2d5")
      ("WAITING" :foreground "#bac2de")
      ("DONE" :foreground "#a6e3a1")
      ("CANCELLED" :foreground "#6c7086")))
  )

(after! org-superstar
  (setq org-superstar-headline-bullets-list '("◉" "◈" "○" "▷"))
  (setq org-superstar-todo-bullet-alist '(("TODO" . ?)
                                     ("NEXT" . ?)
                                     ("HOLD" . ?󰙧)
                                     ("WAITING" . ?󰖺)
                                     ("CANCELLED" . ?✘)
                                     ("DONE" . ?)))
  (setq org-superstar-item-bullet-alist '((?* . ?•)
                                     (?+ . ?➤)
                                     (?- . ?•)))
  (setq org-superstar-special-todo-items t)
  (setq org-superstar-remove-leading-stars t))


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
                                       ("[X]" . "☑")
                                       ("#+options:" . "⌥")
                                       ("\\pagebreak" . 128204)
                                       ("#+begin_quote" . "❮")
                                       ("#+end_quote" . "❯")
                                       ("#+BEGIN_Highlight" . "📖")
                                       ("#+END_Highlight" . "📜")
                                       ("#+begin_src" . "󰅬")
                                       ("#+end_src" . "󰅮")
                                       ("#+begin_example" . "")
                                       ("#+end_example" . "")
                                       )))


(add-hook! 'org-mode-hook 'prettify-symbols-mode)

(map! :leader
      "/" #'comment-line
      "x" #'kill-current-buffer)

(require 'org-super-agenda)
(setq spacemacs-theme-org-agenda-height nil
      org-agenda-skip-scheduled-if-done t
      org-agenda-skip-deadline-if-done t
      org-agenda-include-deadlines t
      ;; org-agenda-include-diary t
      org-agenda-block-separator nil
      org-agenda-compact-blocks t
      org-agenda-start-with-log-mode t)


(setq org-agenda-custom-commands
      '(("z" "Super zaen view"
         ((agenda "" ((org-agenda-span 'day)
                      (org-super-agenda-groups
                       '((:name "Today"
                                :time-grid t
                                :date today
                                :todo "TODAY"
                                :scheduled today
                                :order 1)))))
          (alltodo "" ((org-agenda-overriding-header "")
                       (org-super-agenda-groups
                        '((:name "Next to do"
                                 :todo "NEXT"
                                 :order 1)
                          (:name "Important"
                                 :tag "Important"
                                 :priority "A"
                                 :order 6)
                          (:name "Due Today"
                                 :deadline today
                                 :order 2)
                          (:name "Due Soon"
                                 :deadline future
                                 :order 8)
                          (:name "Overdue"
                                 :deadline past
                                 :order 7)
                          (:name "Assignments"
                                 :tag "Assignment"
                                 :order 10)
                          (:name "Issues"
                                 :tag "Issue"
                                 :order 12)
                          (:name "Projects"
                                 :tag "Project"
                                 :order 14)
                          (:name "Emacs"
                                 :tag "Emacs"
                                 :order 13)
                          (:name "Research"
                                 :tag "Research"
                                 :order 15)
                          (:name "To read"
                                 :tag "Read"
                                 :order 30)
                          (:name "Waiting"
                                 :todo "WAITING"
                                 :order 20)
                          (:name "trivial"
                                 :priority<= "C"
                                 :tag ("Trivial" "Unimportant")
                                 :todo ("SOMEDAY" )
                                 :order 90)
                          (:discard (:tag ("Chore" "Routine" "Daily")))))))))))

(with-eval-after-load 'org-agenda
  (setq org-agenda-time-grid
        '((daily today remove-match)  ; 每日时间网格
          (800 1000 1200 1400 1600 1800)  ; 每小时细分
          "------"  ; 时间网格的分隔线
          "   "))  ; 填充字符
)

(setq catppuccin-flavor 'latte) ;; or 'latte, 'macchiato, or 'mocha
;; (catppuccin-reload)

(org-super-agenda-mode t)
