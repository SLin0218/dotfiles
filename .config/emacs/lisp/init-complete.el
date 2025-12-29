
(use-package corfu
  :ensure t
  :init
  (global-corfu-mode)         ;全局启用
  :custom
  (corfu-auto t)              ;自动弹出（无需手动触发）
  (corfu-preview-current nil) ;关闭预览可能有助于防止误替换
  (corfu-preselect 'prompt)   ;默认选中提示符而非第一个候选词
  (corfu-cycle t))            ;循环选择

(use-package cape
  :ensure t
  :init
  ;全部配置
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  ;elisp配置
  (add-hook 'emacs-lisp-mode-hook
	    (lambda ()
	      (setq-local completion-at-point-functions
			  (list (cape-capf-super
				 #'elisp-completion-at-point  ;原生 Elisp 补全
				 #'cape-dabbrev               ;文本词汇
				 #'cape-keyword               ;关键字
				 #'cape-file))))))            ;文件路径


(use-package vertico
  :ensure t
  :init
  (vertico-mode))

(use-package consult
  :ensure t)

(use-package orderless
  :ensure t
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+"))


(provide 'init-complete)

