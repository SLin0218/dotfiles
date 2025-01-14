;;; init-org.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Commentary:
;;;code:
(use-package org-roam
  :ensure t
  :after org
  :init
  (setq org-roam-v2-ack t) ;; Acknowledge V2 upgrade
  :config
  (org-roam-setup)
  :custom
  (org-roam-directory (concat org-directory "roam/")) ; 设置 org-roam 目录
  :bind
  (("C-c n f" . org-roam-node-find)
  (:map org-mode-map
     (("C-c n i" . org-roam-node-insert)
      ("C-c n o" . org-id-get-create)
      ("C-c n t" . org-roam-tag-add)
      ("C-c n a" . org-roam-alias-add)
      ("C-c n l" . org-roam-buffer-toggle)))))

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

(add-hook 'org-mode-hook (lambda () (org-superstar-mode 1)))
(use-package org-superstar
  :ensure t
  :config
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


(provide 'init-org)
;;; init-org.el ends here
