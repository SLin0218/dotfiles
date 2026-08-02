;;; init-dired.el --- Dired configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 目录管理 (Dired) 增强：图标展示、文件类型高亮以及快捷搜索过滤。
;;

;;; Code:

(use-package dired
  :ensure nil
  :hook
  (dired-mode . dired-omit-mode) ; 隐藏 .git、.DS_Store 等
  :config
  (setq dired-listing-switches "-alh")
  ;; 退出 dired 时，自动杀死 (kill) 缓冲区而不仅是隐藏
  (define-key dired-mode-map (kbd "q") (lambda () (interactive) (quit-window t)))
  ;; 深入新目录时，自动杀死旧目录的 Dired 缓冲区，防止堆积
  (setq dired-kill-when-opening-new-dired-buffer t))

;; Dired 图标美化
(use-package all-the-icons-dired
  :after (dired all-the-icons)
  :hook (dired-mode . all-the-icons-dired-mode))

;; 文件类型语法高亮
(use-package diredfl
  :hook
  (dired-mode . diredfl-mode))

;; 模糊检索与过滤
(use-package dired-narrow
  :bind (:map dired-mode-map
         ("/" . dired-narrow))
  :config
  (setq dired-narrow-backend 'consult-line))

(provide 'init-dired)
;;; init-dired.el ends here
