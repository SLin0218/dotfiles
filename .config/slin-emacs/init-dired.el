(use-package dired
  :ensure nil
  :hook
  (dired-mode . dired-omit-mode) ;隐藏 .git、.DS_Store 等
  :config
  (setq dired-listing-switches "-alh"))

;文件类型高亮
(use-package diredfl
  :hook
  (dired-mode . diredfl-mode))

(use-package dired-narrow
  :bind (:map dired-mode-map
         ("/" . dired-narrow))
  :config
  ;; 使用 consult 作为后端（支持 orderless 模糊匹配）
  (setq dired-narrow-backend 'consult-line))


(provide 'init-dired)
