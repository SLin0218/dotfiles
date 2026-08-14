;;; init-dap.el --- Debug Adapter Protocol (DAP) configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 代码调试 (Dape)：支持 Java/Spring Boot 热重载调试与全局/Evil调试快捷键。
;;

;;; Code:

(use-package dape
  :defer t
  :init
  ;; Evil Leader 调试快捷键映射 (SPC d 开头) 放在 :init 中，确保无延时激活且能按需延迟加载 dape
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global (kbd "<leader>dd") 'dape)
    (evil-define-key 'normal 'global (kbd "<leader>dq") 'dape-quit)
    (evil-define-key 'normal 'global (kbd "<leader>db") 'dape-breakpoint-toggle)
    (evil-define-key 'normal 'global (kbd "<leader>dc") 'dape-continue)
    (evil-define-key 'normal 'global (kbd "<leader>dn") 'dape-next)
    (evil-define-key 'normal 'global (kbd "<leader>di") 'dape-step-in)
    (evil-define-key 'normal 'global (kbd "<leader>do") 'dape-step-out)
    (evil-define-key 'normal 'global (kbd "<leader>dr") 'dape-restart)
    (evil-define-key 'normal 'global (kbd "<leader>df") 'dape-info)
    (evil-define-key 'normal 'global (kbd "<leader>dg") 'dape-repl)
    (evil-define-key 'normal 'global (kbd "<leader>dh") 'my/dape-java-hot-code-replace))

  ;; 全局功能键调试绑定 (VS Code 风格)
  (global-set-key (kbd "<f5>") 'dape-continue)
  (global-set-key (kbd "<f9>") 'dape-breakpoint-toggle)
  (global-set-key (kbd "<f10>") 'dape-next)
  (global-set-key (kbd "<f11>") 'dape-step-in)
  (global-set-key (kbd "<f12>") 'dape-step-out)

  :config
  ;; 1. 定义 Java 热重载 (Hot Code Replace) 触发函数
  (defun my/dape-java-hot-code-replace ()
    "Trigger Hot Code Replace (redefineClasses) for active Java debugging sessions in Dape."
    (interactive)
    (if-let* ((connections (and (fboundp 'dape--live-connections) (dape--live-connections))))
        (dolist (conn connections)
          (message "Triggering Java Hot Code Replace for connection: %s" conn)
          (dape-request conn "redefineClasses" (make-hash-table)
                        (lambda (_conn error)
                          (if error
                              (message "Hot Code Replace failed: %s" (plist-get error :message))
                            (message "Hot Code Replace succeeded!")))))
      (message "No active Dape debug session.")))

  ;; 保存 Java 文件时自动触发热代码替换
  (defun my/dape-java-hot-code-replace-on-save ()
    "Automatically trigger hot code replace after save for Java buffers when debugging."
    (when (and (fboundp 'dape--live-connections)
               (dape--live-connections))
      (run-with-idle-timer 1.5 nil
                           (lambda ()
                             (when (dape--live-connections)
                               (dolist (conn (dape--live-connections))
                                 (dape-request conn "redefineClasses" (make-hash-table)
                                               (lambda (_conn error)
                                                 (if error
                                                     (message "Java HCR auto-reload failed: %s" (plist-get error :message))
                                                   (message "Java HCR auto-reload success!"))))))))))

  ;; 仅在 Java Mode Buffer 开启时局部挂载 after-save-hook，避免污染全局保存钩子
  (defun my/dape-setup-java-hcr-hook ()
    (add-hook 'after-save-hook #'my/dape-java-hot-code-replace-on-save nil t))

  (add-hook 'java-mode-hook #'my/dape-setup-java-hcr-hook)
  (add-hook 'java-ts-mode-hook #'my/dape-setup-java-hcr-hook)

  ;; 2. 将所有 dape 调试窗口合并放到底部 100% 宽度显示
  (setq dape-buffer-window-arrangement nil)
  (add-to-list 'display-buffer-alist
               '("^\\*dape-"
                 (display-buffer-in-side-window)
                 (side . bottom)
                 (slot . 0)
                 (window-height . 0.3)
                 (window-parameters . ((no-other-window . nil)))))

  ;; 3. 将 Scope, Watch, Stack, Breakpoints, REPL 统一显示在一个底部 Tab 分组中
  (setq dape-info-buffer-window-groups
        '((dape-info-scope-mode dape-info-watch-mode dape-info-stack-mode dape-info-breakpoints-mode)))

  ;; 4. 变量初始自动展开层级配置 (设为 2 层)
  (setq dape-variable-auto-expand-alist
        '((0 . 2)       ; 局部变量自动展开 2 层
          (watch . 3)
          (hover . 2)
          (repl . 0)))

  ;; 5. 变量列表排版对齐与单行行高保护
  (setq dape-info-variable-table-aligned t)
  (setq dape-info-variable-table-row-config
        '((name . 25) (value . 0) (type . 15)))

  ;; 强制 Scope 面板开启行截断模式 (truncate-lines)，保证每一行变量固定为 1 行高度
  (add-hook 'dape-info-parent-mode-hook
            (lambda ()
              (setq-local truncate-lines t)))

  ;; 6. 查看变量完整数值功能
  (defun my/dape-view-full-value ()
    "在新 Buffer 中独立查看光标处变量的无截断完整数值。"
    (interactive)
    (if-let* ((var (get-text-property (point) 'dape--variable))
              (val (or (plist-get var :value) (plist-get var :result))))
        (with-current-buffer (get-buffer-create "*dape-full-value*")
          (read-only-mode -1)
          (erase-buffer)
          (insert val)
          (when (or (string-prefix-p "{" (string-trim val))
                    (string-prefix-p "[" (string-trim val)))
            (ignore-errors (json-pretty-print-buffer)))
          (special-mode)
          (display-buffer (current-buffer) '((display-buffer-pop-up-window))))
      (message "当前位置未找到变量数值")))

  (define-key dape-info-scope-mode-map (kbd "K") #'my/dape-view-full-value)
  (define-key dape-info-scope-mode-map (kbd "C-c v") #'my/dape-view-full-value)
  (define-key dape-info-variable-name-map (kbd "K") #'my/dape-view-full-value)
  (define-key dape-info-variable-value-map (kbd "K") #'my/dape-view-full-value)

  (with-eval-after-load 'evil
    (evil-define-key 'normal dape-info-scope-mode-map
      (kbd "K")   #'my/dape-view-full-value
      (kbd "g v") #'my/dape-view-full-value)
    (evil-define-key 'normal dape-info-variable-name-map
      (kbd "K")   #'my/dape-view-full-value
      (kbd "g v") #'my/dape-view-full-value)
    (evil-define-key 'normal dape-info-variable-value-map
      (kbd "K")   #'my/dape-view-full-value
      (kbd "g v") #'my/dape-view-full-value))

  ;; 7. 行内变量实时数值提示 (Inlay Hints) 关闭
  (setq dape-inlay-hints nil)

  ;; 8. 注册本地 Spring Boot 的远程附加调试配置 (Attach)
  (add-to-list 'dape-configs
               `(attach-springboot
                 modes (java-mode java-ts-mode)
                 ensure (lambda (config)
                          (unless (and (featurep 'eglot) (eglot-current-server))
                            (user-error "No eglot instance active in buffer %s" (current-buffer))))
                 fn (lambda (config)
                      (if-let* ((server (eglot-current-server))
                                (proj-name (or (plist-get config :projectName)
                                               (and (project-current)
                                                    (project-name (project-current)))
                                               (file-name-nondirectory
                                                (directory-file-name default-directory))))
                                (cp-info (ignore-errors
                                           (eglot-execute-command server
                                                                  "vscode.java.resolveClasspath"
                                                                  (vector (or (plist-get config :mainClass) "")
                                                                          proj-name))))
                                (port (eglot-execute-command server "vscode.java.startDebugSession" nil)))
                          (let ((module-paths (and cp-info (aref cp-info 0)))
                                (class-paths (and cp-info (aref cp-info 1))))
                            (thread-first
                              config
                              (plist-put 'port port)
                              (plist-put :projectName proj-name)
                              (plist-put :modulePaths module-paths)
                              (plist-put :classPaths class-paths)))
                        (user-error "Failed to start debug session via JDTLS")))
                 :type "java"
                 :request "attach"
                 :hostName "localhost"
                 :port 5005))

  ;; 9. JDTLS 依赖库源码与反编译文件 (jdt://) 断点路径双向映射支持
  (advice-add 'dape--file-name-remote :around
              (lambda (orig-fn conn filename)
                (or (and (stringp filename)
                         (fboundp '+eglot/jdtls-path-to-uri)
                         (+eglot/jdtls-path-to-uri filename))
                    (funcall orig-fn conn filename))))

  (advice-add 'dape--file-name-local :around
              (lambda (orig-fn conn filename)
                (or (and (stringp filename)
                         (fboundp '+eglot/jdtls-uri-to-path)
                         (+eglot/jdtls-uri-to-path filename))
                    (funcall orig-fn conn filename)))))

(provide 'init-dap)
;;; init-dap.el ends here
