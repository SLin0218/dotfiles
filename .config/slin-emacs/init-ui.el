(tool-bar-mode -3)                      ;禁用工具栏
(menu-bar-mode -1)                      ;禁用菜单栏
(scroll-bar-mode -1)                    ;禁用滚动条
(global-display-line-numbers-mode 1)    ;行号


(defun slin/inhibit-line-number-in-special-buffers ()
  "Return non-nil if current buffer should not show line numbers."
  (or (eq major-mode 'dashboard-mode)
      (string-prefix-p "*" (buffer-name))))


(defun load-font-setup ()
  (when (display-graphic-p)
    (cond
     ((eq window-system 'pgtk)
      (set-face-attribute 'default nil :height 140 :family "JetBrainsMono Nerd Font Mono"))
     (t
      (let* ((font-size (if (> (frame-pixel-width) 2000) 18 16))
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

(with-eval-after-load 'org
  (advice-add #'org-string-width :override #'org--string-width-1)
  (set-face-attribute 'org-table nil :family "Sarasa Term SC Nerd" :height 160))

;; 在图形界面下启动时最大化窗口（仅 macOS）
(when (and (eq system-type 'darwin)
           (display-graphic-p))
  (add-to-list 'default-frame-alist '(fullscreen . maximized)))


(use-package all-the-icons
  :if (display-graphic-p)
  :ensure t)

(use-package all-the-icons-dired
  :if (display-graphic-p)
  :after (dired all-the-icons)
  :hook (dired-mode . all-the-icons-dired-mode)
  :ensure t)

(use-package doom-modeline
  :ensure t
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-nil))

(use-package dracula-theme
  :ensure t)
(load-theme 'dracula t)

(use-package dashboard
  :ensure t
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

(use-package awesome-tab
  :load-path "/Users/lin/.config/emacs/lisp/awesome-tab"
  :config
  (setq awesome-tab-height 180)
  (setq awesome-tab-cycle-scope 'tabs)
  (setq awesome-tab-dark-active-bar-color "#50fa7b")
  (set-face-attribute 'tab-line nil :inherit 'default)
  (when (not (display-graphic-p))
    (setq frame-background-mode 'dark))
  (defun awesome-tab-hide-tab (x)
    (let ((name (format "%s" x)))
      (or
       (string-prefix-p "*" name)
       (string-prefix-p " *" name)
       (and (string-prefix-p "magit" name)
            (not (file-name-extension name)))
       )))
  (awesome-tab-mode t))

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


(provide 'init-ui)
