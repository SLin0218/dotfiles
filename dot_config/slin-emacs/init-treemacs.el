;;; init-treemacs.el --- Treemacs sidebar file tree configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 项目侧边栏文件树 (Treemacs) 配置：
;; 1. 集成 Evil 键位 (treemacs-evil)。
;; 2. 匹配 Nerd-icons 图标体系 (treemacs-nerd-icons)。
;; 3. 项目自动跟随 (follow-mode) 与 Git 状态集成。
;;

;;; Code:

(use-package treemacs
  :commands (treemacs treemacs-select-window)
  :custom
  (treemacs-collapse-dirs                 3)
  (treemacs-deferred-git-apply-delay      0.5)
  (treemacs-display-in-side-window        t)
  (treemacs-eldoc-display                 'simple)
  (treemacs-file-event-delay              2000)
  (treemacs-file-follow-delay             0.2)
  (treemacs-follow-after-init             t)
  (treemacs-git-mode                      'deferred)
  (treemacs-indent-guide-style            'line)
  (treemacs-is-never-other-window         t)
  (treemacs-no-png-images                 nil)
  (treemacs-project-follow-cleanup        nil)
  (treemacs-show-cursor                   nil)
  (treemacs-show-hidden-files             nil)
  (treemacs-silent-filewatch              nil)
  (treemacs-sorting                       'alphabetic-asc)
  (treemacs-width                         32)
  :config
  ;; 禁用侧边栏行号显示
  (add-hook 'treemacs-mode-hook (lambda () (display-line-numbers-mode -1)))
  ;; 自动跟随当前激活的 buffer 文件
  (treemacs-follow-mode t)
  (treemacs-filewatch-mode t)
  (treemacs-git-mode 'deferred))

;; Evil 键位支持 (集成 j/k 移动、o 打开、TAB 折叠等 Vim 习惯)
(use-package treemacs-evil
  :after (treemacs evil))

;; Nerd-icons 美化图标支持
(use-package treemacs-nerd-icons
  :after (treemacs nerd-icons)
  :config
  (treemacs-load-theme "nerd-icons"))

(provide 'init-treemacs)
;;; init-treemacs.el ends here
