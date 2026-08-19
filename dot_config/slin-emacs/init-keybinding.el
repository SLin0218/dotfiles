;;; init-keybinding.el --- Evil and custom keybindings configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 自定义 Evil 键位、Leader 前缀快捷键、Avy 快速跳转、Ace-window 等按键控制配置。
;;

;;; Code:

(setq evil-want-integration t)
(setq evil-want-keybinding nil)

;; Vim 模式与 Leader 键设置
(use-package evil
  :custom
  (evil-undo-system 'undo-tree)
  (evil-want-C-u-scroll t)
  :config
  (dolist (mode '(dashboard-mode
                  help-mode
                  buffer-menu-mode
                  package-menu-mode))
    (add-to-list 'evil-emacs-state-modes mode))
  (evil-set-leader '(normal visual) (kbd "SPC") nil)

  ;; File 操作
  (evil-define-key 'normal 'global (kbd "<leader>fr") 'consult-recent-file)
  (evil-define-key 'normal 'global (kbd "<leader>ff") 'find-file)
  (evil-define-key 'normal 'global (kbd "<leader>fd") 'dired)
  (evil-define-key 'normal 'global (kbd "<leader>fj") 'dired-jump)

  ;; Buffer 操作
  (evil-define-key 'normal 'global (kbd "<leader>bb") 'consult-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bB") 'my/switch-to-star-buffers)
  (evil-define-key 'normal 'global (kbd "<leader>bk") 'my/consult-kill-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bx") 'kill-current-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>bs") 'save-buffer)

  ;; 搜索操作 (Fuzzy Search)
  (evil-define-key 'normal 'global (kbd "<leader>sp") 'consult-ripgrep)
  (evil-define-key 'normal 'global (kbd "<leader>ss") 'consult-line)

  ;; Avy 快速跳转
  (evil-define-key 'normal 'global (kbd "<leader>kk") 'evil-avy-goto-line-above)
  (evil-define-key 'normal 'global (kbd "<leader>jj") 'evil-avy-goto-line-below)
  (evil-define-key 'normal 'global (kbd "<leader>gg") 'evil-avy-goto-char-2)

  ;; 代码跳转 (Go to definition/implementation/typeDefinition/usages)
  (evil-define-key 'normal 'global (kbd "<leader>gd") 'xref-find-definitions)
  (evil-define-key 'normal 'global (kbd "<leader>gm") 'eglot-find-implementation)
  (evil-define-key 'normal 'global (kbd "<leader>gp") 'eglot-find-declaration)
  (evil-define-key 'normal 'global (kbd "<leader>gu") 'xref-find-references)

  ;; 重构 修改名称
  (evil-define-key 'normal 'global (kbd "<leader>rn") 'eglot-rename)
  ;; 代码格式化
  (evil-define-key 'normal 'global (kbd "<leader>fm") 'my/format-buffer)
  (evil-define-key 'normal 'global (kbd "<leader>da") 'eglot-code-actions)

  ;; 注释
  (evil-define-key '(normal visual) 'global (kbd "<leader>/") 'evilnc-comment-or-uncomment-lines)

  ;; 窗口 Window 操作
  (evil-define-key 'normal 'global (kbd "<leader>ws") 'evil-window-split)
  (evil-define-key 'normal 'global (kbd "<leader>wv") 'evil-window-vsplit)
  (evil-define-key 'normal 'global (kbd "<leader>wl") 'evil-window-right)
  (evil-define-key 'normal 'global (kbd "<leader>wk") 'evil-window-up)
  (evil-define-key 'normal 'global (kbd "<leader>wj") 'evil-window-down)
  (evil-define-key 'normal 'global (kbd "<leader>wo") 'evil-window-down)
  (evil-define-key 'normal 'global (kbd "<leader>wh") 'evil-window-left)
  (evil-define-key 'normal 'global (kbd "<leader>wq") 'delete-window)
  (evil-define-key 'normal 'global (kbd "<leader>ww") 'delete-other-windows)

  ;; Git diff-hl 跳转
  (evil-define-key 'normal 'global (kbd "<leader>vn") 'diff-hl-next-hunk)
  (evil-define-key 'normal 'global (kbd "<leader>vp") 'diff-hl-previous-hunk)

  ;; Flymake 错误跳转
  (evil-define-key 'normal 'global (kbd "<leader>en") 'flymake-goto-next-error)
  (evil-define-key 'normal 'global (kbd "<leader>ep") 'flymake-goto-prev-error)

  ;; 快捷打开 Dired & Magit
  (evil-define-key 'normal 'global (kbd "<leader>dj") 'dired-jump)
  (evil-define-key 'normal 'global (kbd "<leader>mg") 'magit)
  ;; 快速查看 blame 类似 idea Git Annotate
  (evil-define-key 'normal 'global (kbd "<leader>mb") 'magit-blame-addition)

  ;; V2EX 客户端与主页 Dashboard
  (evil-define-key 'normal 'global (kbd "<leader>xv") 'v2ex)
  (evil-define-key 'normal 'global (kbd "<leader>vv") 'v2ex)
  (evil-define-key 'normal 'global (kbd "<leader>xs") 'v2ex-set-token)

  (evil-mode 1))

;; 全局按键重映射 (例如 M-v 粘贴)
(global-set-key (kbd "M-v") 'yank)

;; Evil 集合增强
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; 快捷键提示
(use-package which-key
  :init (which-key-mode))

;; Avy 快速跳转
(use-package avy)

;; Ace-window 快速切换窗口
(use-package ace-window
  :bind (("C-x o" . ace-window)))

;; Evil 快捷注释
(use-package evil-nerd-commenter)

;; 多光标同步编辑 (Evil)
(use-package evil-multiedit
  :after evil
  :config
  (evil-multiedit-default-keybinds))

(provide 'init-keybinding)
;;; init-keybinding.el ends here
