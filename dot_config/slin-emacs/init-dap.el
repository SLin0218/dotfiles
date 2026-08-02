;;; init-dap.el --- Debug Adapter Protocol (DAP) configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 代码调试 (Dape)：支持 Java/Spring Boot 热重载调试与全局/Evil调试快捷键。
;;

;;; Code:

(use-package dape
  :defer t
  :init
  ;; 定义 Java 热重载 (Hot Code Replace) 触发函数
  (defun my/dape-java-hot-code-replace ()
    "Trigger Hot Code Replace (redefineClasses) for all active Java debugging sessions in Dape."
    (interactive)
    (if-let* ((connections (and (fboundp 'dape--live-connections) (dape--live-connections))))
        (dolist (conn connections)
          (message "Triggering Java Hot Code Replace for connection: %s" conn)
          (dape-request conn "redefineClasses" nil
                        (lambda (_conn error)
                          (if error
                              (message "Hot Code Replace failed: %s" (plist-get error :message))
                            (message "Hot Code Replace succeeded!")))))
      (message "No active Dape debug session.")))

  ;; 保存 Java 文件时自动触发热代码替换
  (defun my/dape-java-hot-code-replace-on-save ()
    "Automatically trigger hot code replace after save for Java buffers when debugging."
    (when (and (derived-mode-p 'java-mode 'java-ts-mode)
               (fboundp 'dape--live-connections)
               (dape--live-connections))
      (run-with-idle-timer 1.2 nil
                           (lambda ()
                             (when (dape--live-connections)
                               (dolist (conn (dape--live-connections))
                                 (dape-request conn "redefineClasses" nil
                                               (lambda (_conn error)
                                                 (if error
                                                     (message "Java HCR auto-reload failed: %s" (plist-get error :message))
                                                   (message "Java HCR auto-reload success!"))))))))))

  (add-hook 'after-save-hook #'my/dape-java-hot-code-replace-on-save)

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
    (evil-define-key 'normal 'global (kbd "<leader>dh") 'my/dape-java-hot-code-replace))

  :config
  ;; 注册本地 Spring Boot 的远程附加调试配置 (Attach)
  (add-to-list 'dape-configs
               `(attach-springboot
                 modes (java-mode java-ts-mode)
                 ensure (lambda (config)
                          (unless (and (featurep 'eglot) (eglot-current-server))
                            (user-error "No eglot instance active in buffer %s" (current-buffer))))
                 fn (lambda (config)
                      (if-let* ((server (eglot-current-server))
                                (port (eglot-execute-command server "vscode.java.startDebugSession" nil)))
                          (thread-first
                            config
                            (plist-put 'port port))
                        (user-error "Failed to start debug session via JDTLS")))
                 :type "java"
                 :request "attach"
                 :hostName "localhost"
                 :port 5005)))

;; 全局功能键调试绑定 (VS Code 风格)
(global-set-key (kbd "<f5>") 'dape-continue)
(global-set-key (kbd "<f9>") 'dape-breakpoint-toggle)
(global-set-key (kbd "<f10>") 'dape-next)
(global-set-key (kbd "<f11>") 'dape-step-in)
(global-set-key (kbd "<f12>") 'dape-step-out)

(provide 'init-dap)
;;; init-dap.el ends here
