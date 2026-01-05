;;vim键位
(use-package evil
  :custom
  ;;使用undo-tree作为撤回系统
  (evil-undo-system 'undo-tree)
  (evil-want-C-u-scroll t)
  :init
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (dolist (mode '(dashboard-mode
  	  help-mode
  	  buffer-menu-mode
  	  package-menu-mode))
   (add-to-list 'evil-emacs-state-modes mode))
  (evil-set-leader '(normal visual) (kbd "SPC") nil)
  ;;file操作
  (evil-define-key 'normal 'global (kbd "<leader>fr") 'recentf-open)
  (evil-define-key 'normal 'global (kbd "<leader>ff") 'find-file)
  (evil-define-key 'normal 'global (kbd "<leader>fd") 'dired)
  ;;buffer操作
  (evil-define-key 'normal 'global (kbd "<leader>bb") 'switch-to-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bk") 'kill-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bx") 'kill-current-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bs") 'save-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bl") 'awesome-tab-forward-tab)
  (evil-define-key 'normal 'global (kbd "<leader>bh") 'awesome-tab-backward-tab)
  ;;jump
  (evil-define-key 'normal 'global (kbd "<leader>kk") 'evil-avy-goto-line-above)
  (evil-define-key 'normal 'global (kbd "<leader>jj") 'evil-avy-goto-line-below)
  (evil-define-key 'normal 'global (kbd "<leader>gg") 'evil-avy-goto-char-2)
  (evil-define-key 'normal 'global (kbd "<leader>gg") 'evil-avy-goto-char-2)
  ;;comment
  (evil-define-key '(normal visual) 'global (kbd "<leader>/") 'evilnc-comment-or-uncomment-lines)
  ;;window
  (evil-define-key 'normal 'global (kbd "<leader>ws") 'evil-window-split)
  (evil-define-key 'normal 'global (kbd "<leader>wv") 'evil-window-vsplit)
  (evil-define-key 'normal 'global (kbd "<leader>wl") 'evil-window-right)
  (evil-define-key 'normal 'global (kbd "<leader>wk") 'evil-window-up)
  (evil-define-key 'normal 'global (kbd "<leader>wj") 'evil-window-down)
  (evil-define-key 'normal 'global (kbd "<leader>wo") 'evil-window-down)

  (evil-define-key 'normal 'global (kbd "<leader>wh") 'evil-window-left)
  (evil-define-key 'normal 'global (kbd "<leader>wq") 'delete-window)
  (evil-define-key 'normal 'global (kbd "<leader>ww") 'delete-other-windows)

  (evil-mode 1))

;; evil相关扩展
(use-package evil-collection
   :after evil
   :config
   (evil-collection-init))

;;输入法配置
(use-package rime
  :custom
  (default-input-method "rime")
  (rime-user-data-dir "~/Library/Rime")
  (rime-show-candidate 'posframe)
  :config
  (setq rime-librime-root "/opt/homebrew"))

;;快捷键提示
(use-package which-key
  :init (which-key-mode))

;;快速跳转
(use-package avy)

;;快速切换窗口
(use-package ace-window
  :bind (("C-x o" . ace-window)))

;; 注释
(use-package evil-nerd-commenter)

;; 终端
(use-package vterm
  :hook (vterm-mode . (lambda () (display-line-numbers-mode -1)))
  :config
  ;; 设置 vterm 使用 Solarized Dark 风格
  (custom-set-faces
   ;;'(vterm-default-face ((t (:foreground "#839496" :background "#002b36"))))
   ;; '(vterm-color-black ((t (:foreground "#073642" :background "#073642"))))
   ;;'(vterm-color-red ((t (:foreground "#dc322f" :background "#dc322f"))))
   ;;'(vterm-color-green ((t (:foreground "#859900" :background "#859900"))))
   ;;'(vterm-color-yellow ((t (:foreground "#b58900" :background "#b58900"))))
   ;;'(vterm-color-blue ((t (:foreground "#268bd2" :background "#268bd2"))))
   ;;'(vterm-color-magenta ((t (:foreground "#d33682" :background "#d33682"))))
   ;;'(vterm-color-cyan ((t (:foreground "#2aa198" :background "#2aa198"))))
   ;;'(vterm-color-white ((t (:foreground "#eee8d5" :background "#eee8d5"))))
   ;; bright colors (8-15)
   '(vterm-color-bright-black  ((t (:foreground "#839496" :background "#002b36"))))
   ;;'(vterm-color-bright-red ((t (:foreground "#cb4b16" :background "#cb4b16"))))
   ;;'(vterm-color-bright-green ((t (:foreground "#586e75" :background "#586e75"))))
   ;;'(vterm-color-bright-yellow ((t (:foreground "#657b83" :background "#657b83"))))
   ;;'(vterm-color-bright-blue ((t (:foreground "#839496" :background "#839496"))))
   ;;'(vterm-color-bright-magenta ((t (:foreground "#6c71c4" :background "#6c71c4"))))
   ;;'(vterm-color-bright-cyan ((t (:foreground "#93a1a1" :background "#93a1a1"))))
   ;;'(vterm-color-bright-white ((t (:foreground "#fdf6e3" :background "#fdf6e3"))))
   ))

(provide 'init-keybinding)
