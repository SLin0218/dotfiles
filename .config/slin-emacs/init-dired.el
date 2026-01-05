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

(use-package neotree
  :bind
  (("C-x C-n" . 'neotree-toggle))
  :hook
  (neotree-mode . (lambda () (display-line-numbers-mode -1))) ;隐藏行号
  (neotree-mode . (lambda ()
                    (define-key evil-normal-state-local-map (kbd "TAB") 'neotree-enter)
                    (define-key evil-normal-state-local-map (kbd "SPC") 'neotree-enter)
                    (define-key evil-normal-state-local-map (kbd "q") 'neotree-hide)
                    (define-key evil-normal-state-local-map (kbd "RET") 'neotree-enter)))
  :custom
  (neo-window-width 40)
  :config
  (setq neo-theme (if (display-graphic-p) 'icons 'nerd-icons)))


(provide 'init-dired)
