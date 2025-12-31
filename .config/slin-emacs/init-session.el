(use-package undo-tree
  :ensure t
  :init
  (global-undo-tree-mode)
  :config
  (let ((hist-dir (expand-file-name "undo-tree-hist" user-emacs-directory)))
    (make-directory hist-dir t)
    (setq undo-tree-history-directory-alist `(("." . ,hist-dir))
          undo-tree-auto-save-history t)))


(setq auto-save-default nil)    ;关闭自动保存
(setq create-lockfiles nil)     ;关闭锁文件
(setq delete-old-versions t)    ;自动删除旧版本
(setq kept-new-versions 10)     ;保留最新的 10 个版本
(setq kept-old-versions 2)      ;保留最早的 2 个版本
(setq version-control t)        ;开启编号备份（即 filename.~1~, filename.~2~）
(setq backup-by-copying t)      ;复制备份，保护硬链接

(defun auto-save-delete-trailing-whitespace-except-current-line ()
  (interactive)
  (let ((begin (line-beginning-position))
        (end (point)))
    (save-excursion
      ;; 删除当前行以上的尾部空白
      (when (< (point-min) begin)
        (save-restriction
          (narrow-to-region (point-min) (1- begin))
          (delete-trailing-whitespace)))
      ;; 删除当前行以下的尾部空白
      (when (> (point-max) end)
        (save-restriction
          (narrow-to-region end (point-max))
          (delete-trailing-whitespace))))))

;保存前删除末尾空格
(add-hook 'before-save-hook 'auto-save-delete-trailing-whitespace-except-current-line)


(use-package projectile
  :ensure t
  :init
  (projectile-mode +1))

(provide 'init-session)
