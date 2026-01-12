
(when (eq window-system 'pgtk)
  (tool-bar-mode -3)                      ;禁用工具栏
  (menu-bar-mode -1)                      ;禁用菜单栏
  (scroll-bar-mode -1))                   ;禁用滚动条

(global-display-line-numbers-mode 1)    ;行号


;; 全局字体设置
(defun load-font-setup ()
  (when (display-graphic-p)
    (cond
     ((eq window-system 'pgtk)
      (set-face-attribute 'default nil :height 140 :family "JetBrainsMono Nerd Font Mono"))
     (t
      (let* ((font-size 15)
             (chinese-font "Sarasa Term SC Nerd")
             (english-font "JetBrainsMono Nerd Font Mono"))
        ;; Set default font
        (set-frame-font (format "%s-%d" english-font font-size) nil t)
        ;; Set Chinese font for CJK characters
        (dolist (charset '(han kana bopomofo cjk-misc symbol))
          (set-fontset-font (frame-parameter nil 'font)
                            charset
                            (font-spec :family chinese-font))))))))
(load-font-setup)

;; org-table单独设置字体
(with-eval-after-load 'org
  (advice-add #'org-string-width :override #'org--string-width-1)
  (set-face-attribute 'org-table nil :family "Sarasa Term SC Nerd" :height 160))

;; 在图形界面下启动时最大化窗口（仅 macOS）
(when (and (eq system-type 'darwin)
           (display-graphic-p))
  (add-to-list 'default-frame-alist '(fullscreen . maximized)))

;; 图标
(use-package all-the-icons)

;; dired图标
(use-package all-the-icons-dired
  :if (display-graphic-p)
  :after (dired all-the-icons)
  :hook (dired-mode . all-the-icons-dired-mode))

;; 状态栏
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-nil))

;; 主题
(use-package dracula-theme
  :config
  (load-theme 'dracula t))

;; 启动仪表盘
(use-package dashboard
  :init
  (setq dashboard-center-content t)
  (setq dashboard-vertically-center-content t)
  :custom
  (dashboard-footer-messages '(""))
  :config
  (dashboard-setup-startup-hook)
  (setq dashboard-display-icons-p t)
  (setq dashboard-icon-type 'nerd-icons)
  (setq dashboard-set-heading-icons t)
  (setq dashboard-set-file-icons t)
  (dashboard-modify-heading-icons '((recents   . "nf-oct-file")
                                    (bookmarks . "nf-oct-bookmark")
                                    (projects  . "nf-oct-project")
                                    (agenda    . "nf-oct-tasklist")))
  (setq dashboard-items '((recents   . 15)
                          (bookmarks .  5)
                          (projects  .  5)
                          (agenda    .  5))))

;; 标签栏
(use-package awesome-tab
  :ensure nil
  :config
  (setq awesome-tab-height 180)
  (setq awesome-tab-cycle-scope 'tabs)
  (setq awesome-tab-dark-active-bar-color "#6272a4")
  (when (not (display-graphic-p))
    (setq awesome-tab-display-icon nil)
    (setq frame-background-mode 'dark))
  (defun awesome-tab-hide-tab (x)
    (let ((name (format "%s" x)))
      (or
       (string-prefix-p "*" name)
       (string-prefix-p " *" name)
       (string-prefix-p "diary" name)
       (and (string-prefix-p "magit" name)
            (not (file-name-extension name)))
       )))

  (set-face-attribute 'tab-line nil :inherit 'default)
  (set-face-attribute 'awesome-tab-unselected-face nil :foreground "#6272a4" :distant-foreground "#6272a4")
  (awesome-tab-mode t))

;; 层级对齐线
(use-package indent-bars
  :custom
  (indent-bars-no-descend-lists t) ; no extra bars in continued func arg lists
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  ;; Add other languages as needed
  (indent-bars-treesit-scope '((python function_definition class_definition for_statement
	  if_statement with_statement while_statement)))
  ;; Note: wrap may not be needed if no-descend-list is enough
  ;;(indent-bars-treesit-wrap '((python argument_list parameters ; for python, as an example
  ;;				      list list_comprehension
  ;;				      dictionary dictionary_comprehension
  ;;				      parenthesized_expression subscript)))
  :hook ((python-base-mode yaml-mode) . indent-bars-mode)
  :config
  (setq
    indent-bars-color '(highlight :face-bg t :blend 0.3)
    indent-bars-pattern " . . . . ." ; play with the number of dots for your usual font size
    ;;indent-bars-color-by-depth nil
    indent-bars-width-frac 0.25
    indent-bars-pad-frac 0.1))

;; minibuffer 增强
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

;; minbuffer 相关条目说明注解
(use-package marginalia
  :config
  (marginalia-mode))

;; minibuffer自动补全图标
(use-package nerd-icons-completion
  :after marginalia
  :config
  (nerd-icons-completion-mode)
  (add-hook 'marginalia-mode-hook #'nerd-icons-completion-marginalia-setup))

(use-package colorful-mode
  ;; :diminish
  ;; :ensure t ; Optional
  :custom
  (colorful-use-prefix t)
  (colorful-only-strings 'only-prog)
  (css-fontify-colors nil)
  :config
  (global-colorful-mode t)
  (add-to-list 'global-colorful-modes 'helpful-mode))

(provide 'init-ui)
