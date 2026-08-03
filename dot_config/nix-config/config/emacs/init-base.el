;;; init-base.el --- General edit sessions and editor base settings  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 基础编辑设置：撤销历史树 (undo-tree)、备份策略、Magit Git 版本控制、
;; 最近文件 (recentf)、光标记忆 (save-place) 及环境变量同步。
;;

;;; Code:

;; 撤销历史树：重新打开文件时记住之前改动
(use-package undo-tree
  :init
  (global-undo-tree-mode)
  :config
  (let ((hist-dir (expand-file-name "undo-tree-hist" user-emacs-directory)))
    (make-directory hist-dir t)
    (setq undo-tree-history-directory-alist `(("." . ,hist-dir))
          undo-tree-auto-save-history t)))

;; 同步 Shell 环境变量 (GUI 模式)
(use-package exec-path-from-shell
  :if (and (memq system-type '(darwin gnu/linux)) (display-graphic-p))
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-envs '("SSH_AUTH_SOCK" "GPG_TTY"))
  (when (boundp 'my-paths-join)
    (setenv "PATH" (concat my-paths-join ":" (getenv "PATH")))
    (setq exec-path (append (mapcar #'expand-file-name my-paths) exec-path))))

;; GPG / EPA 设置：在 Emacs Minibuffer 中直接输入 GPG 密码 (Loopback 模式)
(setq epa-pinentry-mode 'loopback)

;; 备份与自动保存策略
(setq auto-save-default nil)    ; 关闭自动保存
(setq create-lockfiles nil)     ; 关闭锁文件
(setq delete-old-versions t)    ; 自动删除旧版本
(setq kept-new-versions 10)     ; 保留最新的 10 个版本
(setq kept-old-versions 2)      ; 保留最早的 2 个版本
(setq version-control t)        ; 开启编号备份
(setq backup-by-copying t)      ; 复制备份，保护硬链接
;; 仅启用 Git 版本控制后端，避免在非 Git 目录探测老旧 VCS 卡顿
(setq vc-handled-backends '(Git))

;; 保存前清理尾部空白 (排除当前光标行)
(defun auto-save-delete-trailing-whitespace-except-current-line ()
  "在自动保存前，删除除当前活动行以外的所有行尾空格."
  (interactive)
  (let ((begin (line-beginning-position))
        (end (point)))
    (save-excursion
      (when (< (point-min) begin)
        (save-restriction
          (narrow-to-region (point-min) (1- begin))
          (delete-trailing-whitespace)))
      (when (> (point-max) end)
        (save-restriction
          (narrow-to-region end (point-max))
          (delete-trailing-whitespace))))))

(add-hook 'before-save-hook #'auto-save-delete-trailing-whitespace-except-current-line)

;; Git 版本控制 (Magit & Diff-hl)
;; 定义按 Commit Hash 循环着色的 Face 调色板 (Catppuccin Mocha 背景色风格)
(defface my/magit-blame-c1 '((t (:background "#89b4fa" :foreground "#11111b" :extend t))) "Catppuccin Mocha Blue BG")
(defface my/magit-blame-c2 '((t (:background "#a6e3a1" :foreground "#11111b" :extend t))) "Catppuccin Mocha Green BG")
(defface my/magit-blame-c3 '((t (:background "#f9e2af" :foreground "#11111b" :extend t))) "Catppuccin Mocha Yellow BG")
(defface my/magit-blame-c4 '((t (:background "#cba6f7" :foreground "#11111b" :extend t))) "Catppuccin Mocha Mauve BG")
(defface my/magit-blame-c5 '((t (:background "#fab387" :foreground "#11111b" :extend t))) "Catppuccin Mocha Peach BG")
(defface my/magit-blame-c6 '((t (:background "#f38ba8" :foreground "#11111b" :extend t))) "Catppuccin Mocha Pink BG")
(defface my/magit-blame-c7 '((t (:background "#94e2d5" :foreground "#11111b" :extend t))) "Catppuccin Mocha Teal BG")

(defvar my/magit-blame-faces
  '(my/magit-blame-c1
    my/magit-blame-c2
    my/magit-blame-c3
    my/magit-blame-c4
    my/magit-blame-c5
    my/magit-blame-c6
    my/magit-blame-c7))

(defun my/magit-blame-commit-face (rev)
  "根据 Commit REV 哈希值动态分配 Catppuccin 调色板 Face."
  (if (and rev (stringp rev) (>= (length rev) 6))
      (let ((idx (mod (string-to-number (substring rev 0 6) 16) (length my/magit-blame-faces))))
        (nth idx my/magit-blame-faces))
    'magit-blame-margin))

(defun my/magit-blame-format-string-1 (orig-fn rev revinfo format face)
  "在 Magit 格式化边栏字段后，将 Commit 专属 Face 插入至 face 列表的最前端（顶级优先级）."
  (let* ((cface (my/magit-blame-commit-face rev))
         (str (funcall orig-fn rev revinfo format face))
         (len (length str)))
    (when (and str (stringp str))
      (dotimes (i len)
        (let ((f (get-text-property i 'font-lock-face str)))
          (put-text-property
           i (1+ i) 'font-lock-face
           (cons cface (if (listp f) f (and f (list f))))
           str))))
    str))

(use-package magit
  :defer t
  :init
  (setq magit-auto-revert-mode nil)
  :config
  ;; 设置 Blame 时间格式为 yy-MM-dd HH:mm:ss
  (setq magit-blame-time-format "%y-%m-%d %H:%M:%S")

  ;; 设置 magit-blame 使用 margin 边栏样式 (格式：作者 -> 时间 -> Commit ID 放最后)
  (setq magit-blame-styles
        '((margin
           (margin-format . " %-10a %A %h ")
           (margin-width . 38)
           (margin-face . magit-blame-margin)
           (margin-body-face . nil))))

  ;; 挂载底层格式化 Advice，动态注入最优先级的 Commit Face
  (advice-remove 'magit-blame-propertize-margin #'my/magit-blame-color-margin-string)
  (advice-add 'magit-blame--format-string-1 :around #'my/magit-blame-format-string-1))

(global-auto-revert-mode 1)

(use-package diff-hl
  :hook ((prog-mode text-mode dired-mode) . diff-hl-mode)
  :config
  (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)
  (diff-hl-margin-mode))

;; 光标处同名符号高亮
(use-package symbol-overlay
  :bind
  ("M-i" . symbol-overlay-put)
  ("M-n" . symbol-overlay-jump-next)
  ("M-p" . symbol-overlay-jump-prev))

;; 最近打开的文件记录
(use-package recentf
  :init
  (recentf-mode 1)
  :config
  (setq recentf-max-saved-items 100
        recentf-exclude '("/tmp/" "/ssh:" "\\.git/" "/elpa/" "eglot-jdtls-sources")))

;; 记住上次打开文件时的光标位置
(save-place-mode 1)

(provide 'init-base)
;;; init-base.el ends here
