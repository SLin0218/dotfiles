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

(provide 'init-keybinding)
