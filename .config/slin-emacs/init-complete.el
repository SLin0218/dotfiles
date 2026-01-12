(use-package corfu
  :init
  (global-corfu-mode)         ;全局启用
  :custom
  (corfu-auto t)              ;自动弹出（无需手动触发）
  (corfu-preview-current nil) ;关闭预览可能有助于防止误替换
  (corfu-preselect 'prompt)   ;默认选中提示符而非第一个候选词
  (corfu-cycle t))            ;循环选择

(use-package cape
  :init
  ;全部配置
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  ;; --------------------------
  ;; Emacs Lisp 专用
  ;; --------------------------
  (add-hook 'emacs-lisp-mode-hook
            (lambda ()
              ;; 组合 Elisp 补全 + keyword + 全局 dabbrev/file
              (setq-local completion-at-point-functions
                          (cape-capf-super
                           #'elisp-completion-at-point
                           #'cape-keyword
                           #'cape-dabbrev
                           #'cape-file))))
  ;; --------------------------
  ;; Python/Eglot 专用
  ;; --------------------------
  (add-hook 'eglot-managed-mode-hook
            (lambda ()
              ;; 组合 Eglot 补全 + 文件 + dabbrev
              (setq-local completion-at-point-functions
                          (cape-capf-super
                           #'eglot-completion-at-point
                           #'cape-file
                           #'cape-dabbrev))))
  )

(use-package blacken
  :hook (eglot-managed-mode . blacken-mode)
  :custom
  (blacken-line-length 88))

(use-package xml-format
  :demand t
  :after nxml-mode
  :hook (nxml-mode . xml-format-on-save-mode)
  :config
  (xml-format-on-save-mode t))

(use-package consult)

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+"))

(use-package eglot
  :config

  (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))

  ;; （可选）为 Pyright 传递配置，例如在 .dir-locals.el 中
  ;; (add-to-list 'eglot-workspace-configuration
  ;;              '(pyright . (("typeCheckingMode" . "basic")
  ;;                           ("venvPath" . "./.venv"))))

  (add-to-list 'eglot-server-programs
	       '(js-json-mode . ("vscode-json-language-server" "--stdio"
				 :initializationOptions
				 ;;格式化支持，默认是不开启的
				 (:provideFormatter t)
				 )))

  ;; 当启动 eglot 时自动运行
  (add-hook 'python-mode-hook #'eglot-ensure)
  (add-hook 'js-json-mode-hook #'eglot-ensure)

)


(use-package lua-mode)
(use-package yaml-mode)

(use-package tree-sitter
  :hook
  (lua-mode . tree-sitter-mode)
  (lua-mode . tree-sitter-hl-mode)
  (yaml-mode . tree-sitter-mode)
  (yaml-mode . tree-sitter-hl-mode)
  :config
  (require 'tree-sitter-langs))

(use-package tree-sitter-langs)


(provide 'init-complete)
