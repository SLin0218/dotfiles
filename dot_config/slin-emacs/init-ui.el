;;; init-ui.el --- Fonts, themes and UI appearance configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 字体、主题 (catppuccin)、Doom-modeline 状态栏、缩进线 (indent-bars)、
;; 窗口淡化 (dimmer) 以及界面色彩配置。
;;

;;; Code:

(global-display-line-numbers-mode 1)     ; 行号显示
(global-hl-line-mode 1)                  ; 高亮当前光标行

;; 字体设置
(defvar slin/font-size 12
  "默认英文字体大小.")
(defvar slin/font-family "JetBrainsMono Nerd Font Mono"
  "默认英文字体族.")
(defvar slin/font-family-cjk "Maple Mono NF CN"
  "默认中文字体族.")

(defconst sys/wsl-p
  (and (eq system-type 'gnu/linux)
       (getenv "WSL_DISTRO_NAME")))

(cond ((eq system-type 'darwin) (setq slin/font-size 16)))
(when sys/wsl-p
  (setq slin/font-size 12))

(defun load-font-setup (&optional frame)
  "根据当前 FRAME 设置默认英文字体与中文字体映射."
  (when (display-graphic-p frame)
    (with-selected-frame (or frame (selected-frame))
      (cond
       ((eq window-system 'pgtk)
        (set-face-attribute 'default nil :height (* slin/font-size 10) :family slin/font-family)
        (set-face-attribute 'fixed-pitch nil :height (* slin/font-size 10) :family slin/font-family))
       (t
        (let* ((font-size slin/font-size)
               (chinese-font slin/font-family-cjk)
               (english-font slin/font-family))
          (set-frame-font (format "%s-%d" english-font font-size) nil t)
          (set-face-attribute 'fixed-pitch nil :family english-font :height (* font-size 10))
          (dolist (charset '(han kana bopomofo cjk-misc symbol))
            (set-fontset-font (frame-parameter nil 'font)
                              charset
                              (font-spec :family chinese-font)))))))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'load-font-setup)
  (load-font-setup))

;; org-table 单独指定中文字体族
(with-eval-after-load 'org
  (set-face-attribute 'org-table nil :family slin/font-family-cjk :height (* slin/font-size 10)))

;; 基础图标集
(use-package all-the-icons)

;; 状态栏
(use-package doom-modeline
  :init (doom-modeline-mode 1)
  :config
  (setq doom-modeline-buffer-file-name-style 'truncate-nil))

;; Catppuccin 主题
(use-package catppuccin-theme
  :config
  (defvar slin/theme-loaded nil)
  (defun slin/load-theme-once (frame)
    (with-selected-frame frame
      (when (and (display-graphic-p frame)
                 (not slin/theme-loaded))
        (load-theme 'catppuccin :no-confirm)
        (setq slin/theme-loaded t))))
  (if (daemonp)
      (add-hook 'after-make-frame-functions #'slin/load-theme-once)
    (load-theme 'catppuccin :no-confirm)))

;; 层级缩进线
(use-package indent-bars
  :custom
  (indent-bars-no-descend-lists t)
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (indent-bars-treesit-scope '((python function_definition class_definition for_statement
	                                   if_statement with_statement while_statement)))
  :hook ((python-base-mode yaml-mode) . indent-bars-mode)
  :config
  (setq indent-bars-color '(highlight :face-bg t :blend 0.3)
        indent-bars-pattern " . . . . ."
        indent-bars-width-frac 0.25
        indent-bars-pad-frac 0.1))

;; 颜色高亮模式
(use-package colorful-mode
  :custom
  (colorful-use-prefix t)
  (colorful-only-strings 'only-prog)
  (css-fontify-colors nil)
  :hook ((css-mode html-mode emacs-lisp-mode) . colorful-mode)
  :config
  (add-to-list 'global-colorful-modes 'helpful-mode))

;; 非活动窗口淡化
(use-package dimmer
  :custom
  (dimmer-fraction 0.4)
  :config
  (dimmer-mode 1))

(provide 'init-ui)
;;; init-ui.el ends here
