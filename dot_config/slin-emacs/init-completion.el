;;; init-completion.el --- Completion framework for Minibuffer and In-buffer  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 补全与检索体系：
;; 1. Minibuffer: Vertico, Marginalia, Orderless, Consult 及 Consult-Xref 实时预览。
;; 2. In-buffer: Corfu, Cape, Kind-icon, Yasnippet 代码补全前端。
;;

;;; Code:

;; ---------------------------------------------------------------------------
;; 1. Minibuffer 搜索与补全框架 (Vertico + Marginalia + Orderless + Consult)
;; ---------------------------------------------------------------------------

;; Minibuffer 垂直界面
(use-package vertico
  :custom
  (vertico-count 13)
  (vertico-resize t)
  (vertico-cycle nil)
  :config
  (vertico-mode)
  (defvar +vertico-current-arrow t)
  (cl-defmethod vertico--format-candidate :around
    (cand prefix suffix index start &context ((and +vertico-current-arrow
                                                   (not (bound-and-true-p vertico-flat-mode)))
                                              (eql t)))
    (setq cand (cl-call-next-method cand prefix suffix index start))
    (if (bound-and-true-p vertico-grid-mode)
        (if (= vertico--index index)
            (concat #("▶" 0 1 (face vertico-current)) cand)
          (concat #("_" 0 1 (display " ")) cand))
      (if (= vertico--index index)
          (concat
           #(" " 0 1 (display (left-fringe right-triangle vertico-current)))
           cand)
        cand))))

;; Minibuffer 条目详细说明注解
(use-package marginalia
  :config
  (marginalia-mode))

;; Minibuffer 图标拓展
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

;; 模糊/多词匹配引擎 Orderless
(use-package orderless
  :config
  (setq completion-styles '(orderless basic)
        orderless-component-separator "\\s-+")
  ;; 优化 eglot 模糊匹配的性能，防止大项目下卡顿
  (setq completion-category-defaults nil
        completion-category-overrides '((eglot (styles orderless basic))
                                        (file (styles partial-completion)))))

;; Consult 全方位搜索与 Buffer 增强
(use-package consult
  :config
  (require 'consult)
  ;; 自定义 consult-buffer 数据源，区分用户打开的文件 Buffer 与系统只读/临时 Buffer
  (defvar consult-source-file-buffer
    `(:name "User Buffers"
            :narrow ?b
            :category buffer
            :face consult-buffer
            :history buffer-name-history
            :state ,#'consult--buffer-state
            :default t
            :items ,(lambda ()
                      (consult--buffer-query
                       :sort 'visibility
                       :as #'consult--buffer-pair
                       :predicate (lambda (buf)
                                    (let ((name (buffer-name buf)))
                                      (and (not (string-prefix-p " " name))
                                           (or (buffer-file-name buf)
                                               (and (not (string-prefix-p "*" name))
                                                    (not (string-prefix-p "magit" name)))))))))))

  (defvar consult-source-temp-buffer
    `(:name "System/Temp Buffers"
            :narrow ?s
            :category buffer
            :face consult-buffer
            :history buffer-name-history
            :state ,#'consult--buffer-state
            :items ,(lambda ()
                      (consult--buffer-query
                       :sort 'visibility
                       :as #'consult--buffer-pair
                       :predicate (lambda (buf)
                                    (let ((name (buffer-name buf)))
                                      (and (not (string-prefix-p " " name))
                                           (not (buffer-file-name buf))
                                           (or (string-prefix-p "*" name)
                                               (string-prefix-p "magit" name)))))))))

  (setq consult-buffer-sources
        (append
         '(consult-source-file-buffer
           consult-source-temp-buffer)
         (delq 'consult-source-recent-file
               (delq 'consult-source-buffer consult-buffer-sources))))

  (defun my/consult-kill-buffer ()
    "Kill a buffer, with grouping like `consult-buffer`."
    (interactive)
    (let ((sources (mapcar (lambda (src)
                             (let ((copy (copy-sequence (eval src))))
                               (plist-put copy :state nil)
                               (plist-put copy :action #'kill-buffer)
                               copy))
                           '(consult-source-file-buffer
                             consult-source-temp-buffer))))
      (consult--multi sources
                      :prompt "Kill buffer: "
                      :require-match t
                      :sort nil)))

  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-find consult-locate))

;; 优化代码跳转 (xref) 体验：Minibuffer (Vertico) 结合 Consult 实时预览目标代码
(use-package xref
  :ensure nil
  :config
  (with-eval-after-load 'consult
    (require 'consult-xref)
    (setq xref-show-definitions-function #'consult-xref)
    (setq xref-show-xrefs-function #'consult-xref)))


;; ---------------------------------------------------------------------------
;; 2. In-Buffer 代码编辑自动补全 (Corfu + Cape + Kind-Icon + Yasnippet)
;; ---------------------------------------------------------------------------

;; Yasnippet 代码模板
(use-package yasnippet
  :config
  (yas-global-mode 1))

(use-package yasnippet-snippets
  :after yasnippet)

(use-package yasnippet-capf
  :after yasnippet)

;; Corfu 补全界面
(use-package corfu
  :custom
  (corfu-auto t)                  ; 自动激活补全
  (corfu-auto-delay 0.0)          ; 零延迟
  (corfu-auto-prefix 1)           ; 1 个字符即触发
  (corfu-cycle t)                 ; 循环候选词
  (corfu-quit-no-match 'separator)
  :init
  (global-corfu-mode)
  :config
  (corfu-popupinfo-mode 1)
  (setq corfu-popupinfo-delay 0.3)
  ;; 不在字符串或注释中自动弹出补全（除非看起来像路径）
  (setq corfu-auto-skip-predicates
        (list (lambda ()
                (let ((state (syntax-ppss)))
                  (and (nth 8 state)
                       (not (string-match-p
                             "\\(?:/\\|\\./\\|\\.\\./\\|~/\\)[^/[:space:]\"']*$"
                             (buffer-substring-no-properties (nth 8 state) (point))))))))))

;; 补全源融合工具 Cape
(use-package cape
  :demand t
  :init
  (add-to-list 'completion-at-point-functions #'cape-file)
  (add-to-list 'completion-at-point-functions #'cape-dabbrev)
  :config
  (setq cape-dabbrev-min-length 1)
  (setq cape-dabbrev-check-other-buffers nil)
  ;; 当 Eglot 启动后，融合 LSP + Yasnippet + Buffer 单词
  (defun my-eglot-capf ()
    (require 'cape)
    (require 'yasnippet-capf)
    (setq-local completion-at-point-functions
                (list #'cape-file
                      (cape-capf-super
                       #'eglot-completion-at-point
                       #'yasnippet-capf
                       #'cape-dabbrev))))
  (add-hook 'eglot-managed-mode-hook #'my-eglot-capf))

;; 图标美化 Kind Icon
(use-package kind-icon
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))

(provide 'init-completion)
;;; init-completion.el ends here
