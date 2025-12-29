;vim键位
(use-package evil
  :ensure t
  :custom
  ;使用undo-tree作为撤回系统
  (evil-undo-system 'undo-tree)
  (evil-want-C-u-scroll t)
  :init
  (evil-mode 1)
  :config
  (dolist (mode '(dashboard-mode
		  help-mode
		  buffer-menu-mode
		  package-menu-mode))
    (add-to-list 'evil-emacs-state-modes mode)))


;输入法配置
(use-package rime
  :ensure t
  :custom
  (default-input-method "rime")
  (rime-user-data-dir "~/Library/Rime")
  (rime-show-candidate 'posframe)
  :config
  (setq rime-librime-root "/opt/homebrew"))


;; esc quits
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))
(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

(use-package which-key
  :ensure t
  :init (which-key-mode))

(use-package avy
  :ensure t)

(use-package ace-window
  :bind (("C-x o" . ace-window)))

(evil-set-leader 'normal (kbd "SPC") nil)
;file操作
(evil-define-key 'normal 'global (kbd "<leader>fr") 'recentf-open)
(evil-define-key 'normal 'global (kbd "<leader>ff") 'find-file)
(evil-define-key 'normal 'global (kbd "<leader>fd") 'dired)
;buffer操作
(evil-define-key 'normal 'global (kbd "<leader>bb") 'switch-to-buffer)
(evil-define-key 'normal 'global (kbd "<leader>bk") 'kill-buffer)
(evil-define-key 'normal 'global (kbd "<leader>bs") 'save-buffer)
(evil-define-key 'normal 'global (kbd "<leader>bl") 'centaur-tabs-backward)
(evil-define-key 'normal 'global (kbd "<leader>bh") 'centaur-tabs-forward)

(evil-define-key 'normal 'global (kbd "<leader>kk") 'evil-avy-goto-line-above)
(evil-define-key 'normal 'global (kbd "<leader>jj") 'evil-avy-goto-line-below)
(evil-define-key 'normal 'global (kbd "<leader>gg") 'evil-avy-goto-char-2)




(provide 'init-keybinding)
