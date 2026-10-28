;;; init-ui.el --- Fonts, themes and UI appearance configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 字体、主题 (catppuccin)、Doom-modeline 状态栏、Tab-bar 顶栏、缩进线 (indent-bars)、
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

;; 顶栏标签页 (Tab-bar 顶栏工作区/窗口布局管理，参考 doom-modeline 设计风格与 Catppuccin 色彩)
(use-package tab-bar
  :hook (after-init . tab-bar-mode)
  :custom
  (tab-bar-show t)                      ; 始终显示标签栏
  (tab-bar-close-button-show t)         ; 保留原生关闭按钮
  (tab-bar-new-button-show t)           ; 保留原生新建按钮
  (tab-bar-separator "")                ; 移除原生 "|" 分隔符
  (tab-bar-auto-width t)                ; 自动弹性均匀分配宽度并右对齐关闭按钮
  (tab-bar-auto-width-min '((120) 14))  ; 最小宽度，防止过窄
  (tab-bar-auto-width-max '((220) 24))  ; 最大宽度，保持紧凑美观
  (tab-bar-format '(tab-bar-format-tabs tab-bar-separator tab-bar-format-add-tab)) ; 纯粹标签列表与添加按钮
  :config
  ;; 关闭按钮定义（保留 close-tab 属性并带对称内边距，确保 auto-width 识别末尾属性以实现右对齐）
  (setq tab-bar-close-button (propertize " x " 'close-tab t :help "Click to close tab"))

  ;; 每个 Tab 最小字符宽度，确保短文件名时关闭按钮依然稳定右对齐
  (defvar slin/tab-bar-tab-min-width 18
    "Minimum character width for each tab.")

  ;; 新建按钮悬停高亮
  (setq tab-bar-new-button (propertize " + "
                                       'mouse-face 'tab-bar-tab-highlight
                                       'help-echo "New tab"))

  ;; 定义未保存指示图标专用 Face
  (defface slin/tab-bar-modified-face
    '((t :weight bold))
    "Face for modified buffer indicator in tab-bar."
    :group 'slin)

  ;; 获取 Tab 对应 Buffer 图标 (优先 nerd-icons，降级 all-the-icons)
  (defun slin/tab-bar-buffer-icon (buffer)
    "Return formatted file icon string for BUFFER."
    (let ((icon-str
           (cond
            ((and (fboundp 'nerd-icons-icon-for-buffer) (bufferp buffer) (buffer-live-p buffer))
             (with-current-buffer buffer
               (nerd-icons-icon-for-buffer)))
            ((and (fboundp 'all-the-icons-icon-for-buffer) (bufferp buffer) (buffer-live-p buffer))
             (with-current-buffer buffer
               (all-the-icons-icon-for-buffer)))
            (t nil))))
      (if (and icon-str (stringp icon-str))
          (concat icon-str " ")
        "")))

  ;; 格式化 Tab 项：内边距、文件图标、未保存指示器与关闭按钮右对齐 (doom-modeline 风格)
  (defun slin/tab-bar-tab-name-format (tab _i)
    "Format TAB in doom-modeline style with icon, modified indicator and right-aligned close button."
    (let* ((current-p (eq (car tab) 'current-tab))
           (tab-name (alist-get 'name tab))
           (buf (if current-p
                    (current-buffer)
                  (let ((candidate (get-buffer tab-name)))
                    (if (and candidate (buffer-live-p candidate))
                        candidate
                      (let ((bl (alist-get 'wc-bl tab)))
                        (when (and (listp bl) (buffer-live-p (car bl)))
                          (car bl)))))))
           (icon (slin/tab-bar-buffer-icon buf))
           (modified (and buf (buffer-file-name buf) (buffer-modified-p buf)))
           (face (if current-p 'tab-bar-tab 'tab-bar-tab-inactive))
           (label (format " %s%s" icon tab-name))
           (mod-icon (if modified
                         (propertize " \ueeb1"
                                     'face (list 'slin/tab-bar-modified-face face))
                       ""))
           (left (concat label mod-icon))
           (close-btn
            (if (and tab-bar-close-button-show
                     (not (eq tab-bar-close-button-show
                              (if current-p 'non-selected 'selected)))
                     tab-bar-close-button)
                tab-bar-close-button
              " "))
           (close-len (length close-btn))
           (curr-len (+ (string-width left) close-len))
           (pad-len (max 1 (- slin/tab-bar-tab-min-width curr-len)))
           (pad (make-string pad-len ?\s))
           (full-str (concat left pad close-btn)))
      ;; 统一为整个标签（包含空白填充与关闭按钮）应用背景与字体 Face，杜绝色块脱节
      (add-face-text-property 0 (length full-str) face t full-str)
      (add-text-properties 0 (length full-str) '(mouse-face tab-bar-tab-highlight) full-str)
      full-str))

  (setq tab-bar-tab-name-format-function #'slin/tab-bar-tab-name-format)

  ;; Catppuccin 色彩配置与 Faces 绑定 (高度与状态栏 mode-line 统一)
  (defun slin/setup-tab-bar-faces ()
    "Setup tab-bar faces matching doom-modeline style and Catppuccin palette."
    (when (featurep 'catppuccin-theme)
      (let* ((bg-base     (catppuccin-color 'base))
             (bg-mantle   (catppuccin-color 'mantle))
             (bg-surface0 (catppuccin-color 'surface0))
             (bg-surface1 (catppuccin-color 'surface1))
             (active-fg   (catppuccin-color 'mauve))
             (inactive-fg (catppuccin-color 'subtext0))
             (modified-fg (catppuccin-color 'yellow))
             (sep-color   bg-surface0)
             (box-spec    `(:line-width (1 . 1) :color ,sep-color :style flat-button))
             ;; 高度与状态栏 mode-line 统一保持 1.0 等高
             (ml-height   (let ((h (face-attribute 'mode-line :height nil t)))
                            (if (numberp h) h 1.0))))

        ;; 整个 Tab-bar 顶栏背景底色（mantle 底色 + 下划线，高度与状态栏一致）
        (set-face-attribute 'tab-bar nil
                            :background bg-mantle
                            :foreground inactive-fg
                            :height ml-height
                            :underline (list :color sep-color :style 'line :position t)
                            :box box-spec)

        ;; 当前选中 Tab：微高亮底色 (base)、mauve 强调文字，底部彩色下划线
        (set-face-attribute 'tab-bar-tab nil
                            :background bg-base
                            :foreground active-fg
                            :weight 'bold
                            :underline (list :color active-fg :style 'line :position t)
                            :box box-spec)

        ;; 非活动 Tab：沉浸于 mantle 背景，subtext0 柔和文字
        (set-face-attribute 'tab-bar-tab-inactive nil
                            :background bg-mantle
                            :foreground inactive-fg
                            :weight 'normal
                            :box box-spec)

        ;; 鼠标悬浮预览 (Hover)
        (set-face-attribute 'tab-bar-tab-highlight nil
                            :background bg-surface1
                            :foreground (catppuccin-color 'text)
                            :box nil)

        ;; 未保存状态指示图标
        (set-face-attribute 'slin/tab-bar-modified-face nil
                            :foreground modified-fg
                            :weight 'bold)

        ;; 窗口垂直分割线（与 Tab 栏风格呼应）
        (set-face-attribute 'vertical-border nil
                            :foreground sep-color
                            :background bg-base)
        (set-face-attribute 'window-divider nil
                            :foreground sep-color)
        (set-face-attribute 'window-divider-first-pixel nil
                            :foreground sep-color)
        (set-face-attribute 'window-divider-last-pixel nil
                            :foreground sep-color)

        (force-mode-line-update t))))

  ;; 主题加载及切换时自适应刷新
  (slin/setup-tab-bar-faces)
  (advice-add 'load-theme :after (lambda (&rest _) (slin/setup-tab-bar-faces))))

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
