;;vim键位
(use-package evil
  :ensure t
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
  (evil-define-key 'normal 'global (kbd "<leader>wh") 'evil-window-left)
  (evil-define-key 'normal 'global (kbd "<leader>wq") 'delete-window)
  (evil-define-key 'normal 'global (kbd "<leader>ww") 'delete-other-windows)

  (evil-mode 1))


(use-package evil-collection
   :after evil
   :ensure t
   :config
   (evil-collection-init))


;;输入法配置
(use-package rime
  :ensure t
  :custom
  (default-input-method "rime")
  (rime-user-data-dir "~/Library/Rime")
  (rime-show-candidate 'posframe)
  :config
  (setq rime-librime-root "/opt/homebrew"))


(use-package which-key
  :ensure t
  :init (which-key-mode))

(use-package avy
  :ensure t)

(use-package ace-window
  :ensure t
  :bind (("C-x o" . ace-window)))

(use-package evil-nerd-commenter
  :ensure t)

(use-package magit
  :ensure t)


(provide 'init-keybinding)
