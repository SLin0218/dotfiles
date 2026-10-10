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
  (vertico-count-format nil)  ; 设为 nil 即可彻底关闭 1/xxx 计数显示
  (vertico-resize t)
  (vertico-cycle nil)
  :config
  (vertico-mode))

;; Minibuffer 条目详细说明注解
(use-package marginalia
  :config
  (marginalia-mode))

;; Minibuffer NANO 风格美化 (命令标题头、药丸计数、极简分割线)
(use-package nano-vertico
  :ensure nil
  :after vertico
  :custom
  (nano-vertico-symbols '((pill-left  . "")
                          (pill-right . "")
                          (selection  . "")
                          (line       . ?╴)))
  :config
  ;; 消除 Minibuffer 左右 Fringe 边缘栏，使背景条完全顶满最左与最右边缘
  (add-hook 'minibuffer-setup-hook
            (lambda ()
              (set-window-fringes (minibuffer-window) 0 0)))

  ;; 定制符合 Catppuccin 主题调性的色彩
  (defun slin/setup-nano-vertico-faces ()
    (when (featurep 'catppuccin-theme)
      (let ((mauve    (catppuccin-color 'mauve))
            (surface0 (catppuccin-color 'surface0))
            (surface1 (catppuccin-color 'surface1))
            (mantle   (catppuccin-color 'mantle))
            (crust    (catppuccin-color 'crust))
            (text     (catppuccin-color 'text))
            (subtext0 (catppuccin-color 'subtext0)))
        ;; 1. 药丸深度指示器：Catppuccin mauve (紫红色) 胶囊
        (set-face-attribute 'nano-vertico-pill nil
                            :foreground crust
                            :background mauve
                            :weight 'bold)
        (set-face-attribute 'nano-vertico-pill-right nil
                            :foreground mauve
                            :background surface0)
        (set-face-attribute 'nano-vertico-pill-left nil
                            :foreground surface0
                            :background mauve)
        ;; 2. 标题头背景与文本 (surface0 弱底色)
        (set-face-attribute 'nano-vertico-header nil
                            :foreground text
                            :background surface0
                            :weight 'normal)
        (set-face-attribute 'nano-vertico-header-bold nil
                            :foreground text
                            :background surface0
                            :weight 'bold)
        (set-face-attribute 'nano-vertico-header-shadow nil
                            :foreground subtext0
                            :background surface0)
        ;; 3. 边框分割线 (与 tab-line/window-divider 一致的 surface0 色)
        (set-face-attribute 'nano-vertico-line nil
                            :foreground surface0)
        ;; 4. 左侧指示器留白槽
        (set-face-attribute 'nano-vertico-gutter nil
                            :foreground subtext0)
        (set-face-attribute 'nano-vertico-gutter-current nil
                            :foreground mauve
                            :weight 'bold))))

  (slin/setup-nano-vertico-faces)
  (nano-vertico-mode 1))

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
  :custom
  (consult-async-min-input 2)          ; 输入至少 2 个字符后再触发搜索进程，降低无谓开销
  (consult-async-input-debounce 0.3)   ; 异步进程输入防抖延迟 (0.3 秒)
  :config
  (consult-customize
   consult-ripgrep consult-git-grep consult-grep
   consult-find consult-locate
   consult-line consult-outline
   consult-recent-file consult-buffer
   :preview-key '(:debounce 0.4 any)))

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

;; Yasnippet 代码模板 (延迟挂载至主模式，避免启动时耗时扫描全量模版目录)
(use-package yasnippet
  :commands (yas-minor-mode yas-global-mode yas-expand yas-insert-snippet)
  :hook ((prog-mode . yas-minor-mode)
         (text-mode . yas-minor-mode))
  :config
  (yas-reload-all))

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
  (corfu-min-width 30)
  (corfu-right-margin-width 0.8)
  (corfu-bar-width 0.2)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter)
  (plist-put kind-icon-default-style :height 0.8)
  (plist-put kind-icon-default-style :scale 0.8))

(use-package git-modes)


(provide 'init-completion)
;;; init-completion.el ends here
