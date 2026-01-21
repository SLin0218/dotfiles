;; (use-package corfu
;;  :init
;;  (global-corfu-mode)         ;全局启用
;;  :custom
;;  (corfu-auto t)              ;自动弹出（无需手动触发）
;;  (corfu-preview-current nil) ;关闭预览可能有助于防止误替换
;;  (corfu-preselect 'prompt)   ;默认选中提示符而非第一个候选词
;;  (corfu-cycle t))            ;循环选择

;; (use-package cape
;;  :init
;;  ;全部配置
;;  (add-hook 'completion-at-point-functions #'cape-dabbrev)
;;  (add-hook 'completion-at-point-functions #'cape-file)
;;  ;; --------------------------
;;  ;; Emacs Lisp 专用
;;  ;; --------------------------
;;  (add-hook 'emacs-lisp-mode-hook
;;            (lambda ()
;;              ;; 组合 Elisp 补全 + keyword + 全局 dabbrev/file
;;              (setq-local completion-at-point-functions
;;                          (cape-capf-super
;;                           #'elisp-completion-at-point
;;                           #'cape-keyword
;;                           #'cape-dabbrev
;;                           #'cape-file))))
;;  ;; --------------------------
;;  ;; Python/Eglot 专用
;;  ;; --------------------------
;;  (add-hook 'eglot-managed-mode-hook
;;            (lambda ()
;;              ;; 组合 Eglot 补全 + 文件 + dabbrev
;;              (setq-local completion-at-point-functions
;;                          (cape-capf-super
;;                           #'eglot-completion-at-point
;;                           #'cape-file
;;                           #'cape-dabbrev))))
;; )

;; (use-package blacken
;;   :hook (eglot-managed-mode . blacken-mode)
;;   :custom
;;   (blacken-line-length 44))

;; (use-package xml-format
;;   :demand t
;;   :after nxml-mode
;;   :hook (nxml-mode . xml-format-on-save-mode)
;;   :config
;;   (xml-format-on-save-mode t))

(use-package consult)

(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+"))

;; (use-package eglot
;;   :hook
;;   (java-mode . eglot-ensure)
;;   (python-mode eglot-ensure)
;;   (js-json-mode eglot-ensure)
;;   :config

;;   (add-to-list 'eglot-server-programs '(python-mode . ("pyright-langserver" "--stdio")))

;;   ;; （可选）为 Pyright 传递配置，例如在 .dir-locals.el 中
;;   ;; (add-to-list 'eglot-workspace-configuration
;;   ;;              '(pyright . (("typeCheckingMode" . "basic")
;;   ;;                           ("venvPath" . "./.venv"))))

;;   (add-to-list 'eglot-server-programs
;; 	       '(js-json-mode . ("vscode-json-language-server" "--stdio"
;; 				 :initializationOptions
;; 				 ;;格式化支持，默认是不开启的
;; 				 (:provideFormatter t))))

;;   ;; (defun slin/jdtls-workspace ()
;;   ;;   (expand-file-name
;;   ;;    (concat "~/.cache/eglot-jdtls/"
;;   ;;            (project-name (project-current)))))
;;   ;; (setq lsp-java-import-maven-enabled t)
;;   ;; (add-to-list 'eglot-server-programs
;;   ;;          (cons 'java-mode (list "jdtls" "-javaagent:/Users/lin/.local/share/nvim/mason/packages/jdtls/lombok.jar" "-data" (slin/jdtls-workspace))))

;;   (defun jdtls-command-contact (&optional interactive)
;;     (let* ((jdtls-cache-dir (file-name-concat user-emacs-directory "cache" "lsp-cache"))
;;            (project-dir (file-name-nondirectory (directory-file-name (project-root (project-current)))))
;;            (data-dir (expand-file-name (file-name-concat jdtls-cache-dir (md5 project-dir))))
;;            (jvm-args `(,(concat "-javaagent:" (expand-file-name "~/.local/share/nvim/mason/packages/jdtls/lombok.jar"))
;;                        "-Xmx8G"
;;                        ;; "-XX:+UseG1GC"
;;                        "-XX:+UseZGC"
;;                        "-XX:+UseStringDeduplication"
;;                        ;; "-XX:FreqInlineSize=325"
;;                        ;; "-XX:MaxInlineLevel=9"
;;                        "-XX:+UseCompressedOops"))
;;            (jvm-args (mapcar (lambda (arg) (concat "--jvm-arg=" arg)) jvm-args))
;;            ;; tell jdtls the data directory and jvm args
;;            (contact (append '("jdtls") jvm-args `("-data" ,data-dir))))
;;       contact))

;;   (push '((java-mode java-ts-mode) . jdtls-command-contact) eglot-server-programs)
;; )



(use-package lua-mode)
(use-package yaml-mode)

(use-package tree-sitter
  :hook
  (lua-mode . tree-sitter-mode)
  (lua-mode . tree-sitter-hl-mode)
  (yaml-mode . tree-sitter-mode)
  (yaml-mode . tree-sitter-hl-mode)
  (java-mode . tree-sitter-mode)
  (java-mode . tree-sitter-hl-mode)
  :config
  (require 'tree-sitter-langs))

(use-package tree-sitter-langs)

(use-package yasnippet
  :config
  (yas-global-mode 1))


(use-package lsp-bridge
  :ensure nil
  :init
  (setq lsp-bridge-jdtls-workspace-exclude
        '("target" "build" "node_modules" ".gradle"))
  (setq lsp-bridge-jdtls-auto-build nil)
  :custom
  (lsp-bridge-jdtls-jvm-args '("-javaagent:/Users/lin/.local/share/nvim/mason/packages/jdtls/lombok.jar"
                               "-Djava.import.generatesMetadataFilesAtProjectRoot=false"
                               "-DDetectVMInstallationsJob.disabled=true"
                               "-Dfile.encoding=utf8"
                               "-XX:+UseParallelGC"
                               "-XX:GCTimeRatio=4"
                               "-XX:AdaptiveSizePolicyWeight=90"
                               "-Dsun.zip.disableMemoryMapping=true"
                               "-Xmx2G"
                               "-Xms100m"
                               "-Xlog:disable"
                               "-Daether.dependencyCollector.impl=bf"))
  (lsp-bridge-python-lsp-server "pyright")
  :config
  (global-lsp-bridge-mode))

;; (setq lsp-bridge-log-level 'debug)
;; (defun local/lsp-bridge-get-single-lang-server-by-project (project-path filepath)
;;   (let* ((json-object-type 'plist)
;;          (custom-dir (expand-file-name ".cache/lsp-bridge/pyright" user-emacs-directory))
;;          (custom-config (expand-file-name "pyright.json" custom-dir))
;;          (default-config (json-read-file (expand-file-name "lisp/lsp-bridge/langserver/pyright.json" user-emacs-directory)))
;;          (settings (plist-get default-config :settings)))

;;     (plist-put settings :pythonPath "/Users/lin/tmp/db/.venv/bin/python")

;;     (make-directory (file-name-directory custom-config) t)

(use-package markdown-mode)

(provide 'init-complete)
