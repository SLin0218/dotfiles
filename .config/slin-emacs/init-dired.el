(use-package dired
  :hook
  (dired-mode . dired-omit-mode) ;隐藏 .git、.DS_Store 等
  :config
  (setq dired-listing-switches "-alh"))

;文件类型高亮
(use-package diredfl
  :ensure t
  :hook
  (dired-mode . diredfl-mode)
  :config
  ;; 可选：自定义颜色（Doom 风格偏暗色系）
  ;; (diredfl-set-colors) ; 使用默认即可
  )

(use-package dired-narrow
  :ensure t
  :bind (:map dired-mode-map
         ("/" . dired-narrow))
  :config
  ;; 使用 consult 作为后端（支持 orderless 模糊匹配）
  (setq dired-narrow-backend 'consult-line))

(use-package neotree
  :ensure t
  :bind
  (("C-x C-n" . 'neotree-toggle))
  :hook
  (neotree-mode . (lambda ()
		    (display-line-numbers-mode -1))) ;隐藏行号
  :custom
  (neo-window-width 40)
  :config
  (setq neo-theme (if (display-graphic-p) 'icons 'arrow))
  (add-hook 'neotree-mode-hook
	    (lambda ()
	      (define-key evil-normal-state-local-map (kbd "TAB") 'neotree-enter)
	      (define-key evil-normal-state-local-map (kbd "SPC") 'neotree-enter)
	      (define-key evil-normal-state-local-map (kbd "q") 'neotree-hide)
              (define-key evil-normal-state-local-map (kbd "RET") 'neotree-enter))))


(provide 'init-dired)
