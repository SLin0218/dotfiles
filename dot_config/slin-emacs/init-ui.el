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
(defvar slin/font-family "Maple Mono NF CN"
  "默认字体族.")

(defvar slin/font-size 15
  "默认字号.")

(defconst sys/wsl-p
  (and (eq system-type 'gnu/linux)
       (getenv "WSL_DISTRO_NAME")))

(cond
 ((eq system-type 'darwin) (setq slin/font-size 16))
 (sys/wsl-p (setq slin/font-size 15))
 ((eq system-type 'windows-nt) (setq slin/font-size 11)))

(defun load-font-setup (&optional frame)
  "根据当前 FRAME 设置统一字体与 CJK 映射，确保中英文 1:2 等宽对齐."
  (let ((target-frame (or frame (selected-frame))))
    (when (display-graphic-p target-frame)
      (with-selected-frame target-frame
        ;; 1. 基础默认面与定宽面统一使用 Maple Mono
        (set-face-attribute 'default target-frame
                            :family slin/font-family
                            :height (* slin/font-size 10))
        (set-face-attribute 'fixed-pitch target-frame
                            :family slin/font-family
                            :height (* slin/font-size 10))

        ;; 2. CJK 字符与脚本映射：置顶优先走 Maple Mono，保证全角字符宽度统一
        (dolist (script '(han kana bopomofo cjk-misc))
          (set-fontset-font t script (font-spec :family slin/font-family) nil 'prepend))

        ;; 3. Windows 环境 Emoji 回退（append 后置，不影响 Maple Mono 自带符号与制表符）
        (when (eq system-type 'windows-nt)
          (setq use-default-font-for-symbols nil)
          (when (member "Segoe UI Emoji" (font-family-list))
            (set-fontset-font t 'emoji (font-spec :family "Segoe UI Emoji") nil 'append)))))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'load-font-setup)
  (load-font-setup))

;; WSL 环境专享：GUI Org 表格像素级自动对齐
;; (use-package valign
;;   :if sys/wsl-p
;;   :hook (org-mode . valign-mode))

;; 基础图标集
(use-package all-the-icons)

;; 状态栏 (挂载至 after-init，确保首屏 Frame 渲染优先，避免阻塞)
(use-package doom-modeline
  :hook (after-init . doom-modeline-mode)
  :config
  (setq doom-modeline-bar-width 0)
  (setq doom-modeline-buffer-file-name-style 'truncate-nil)

  (defun slin/setup-modeline-separator ()
    "Add top border separator between buffer and mode-line matching theme in GUI."
    (let* ((sep-color (if (featurep 'catppuccin-theme)
                          (catppuccin-color 'surface0)
                        "#45475a"))
           (box `(:line-width (1 . 1) :color ,sep-color :style flat-button)))
      (set-face-attribute 'mode-line nil :box box)
      (set-face-attribute 'mode-line-inactive nil :box box)))

  (slin/setup-modeline-separator)
  (advice-add 'load-theme :after (lambda (&rest _) (slin/setup-modeline-separator))))

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

;; 非活动窗口淡化 (挂载至 after-init)
(use-package dimmer
  :custom
  (dimmer-fraction 0.4)
  :hook (after-init . dimmer-mode))


(provide 'init-ui)
;;; init-ui.el ends here
