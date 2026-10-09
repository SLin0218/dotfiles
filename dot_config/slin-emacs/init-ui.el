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
(defvar slin/font-family
  (cond
   ((eq system-type 'windows-nt) "JetBrainsMono NFM")
   (t "JetBrainsMono Nerd Font Mono")))

(defvar slin/font-family-cjk "Maple Mono NF CN"
  "默认中文字体族.")

(defconst sys/wsl-p
  (and (eq system-type 'gnu/linux)
       (getenv "WSL_DISTRO_NAME")))

(cond ((eq system-type 'darwin) (setq slin/font-size 16)))
(when sys/wsl-p
  (setq slin/font-size 15))
(when (eq system-type 'windows-nt) (setq slin/font-size 15))

(when (eq system-type 'windows-nt)
  ;; 1. 禁用“使用默认字体显示符号”，允许 Emacs 使用字体集回退
  (setq use-default-font-for-symbols nil)
  ;; 2. 为 emoji 和 symbol 脚本指定 Windows 自带的 Segoe UI Emoji 字体
  (when (member "Segoe UI Emoji" (font-family-list))
    ;; 为 emoji 分类指定字体 (Emacs 28+)
    (set-fontset-font t 'emoji (font-spec :family "Segoe UI Emoji") nil 'prepend)
    ;; 为 symbol 分类指定字体
    (set-fontset-font t 'symbol (font-spec :family "Segoe UI Emoji") nil 'prepend)))

(defun load-font-setup (&optional frame)
  "根据当前 FRAME 设置默认英文字体与中文字体映射."
  (let ((target-frame (or frame (selected-frame))))
    (when (display-graphic-p target-frame)
      (with-selected-frame target-frame
        (set-face-attribute 'default target-frame :family slin/font-family :height (* slin/font-size 10))
        (set-face-attribute 'fixed-pitch target-frame :family slin/font-family :height (* slin/font-size 10))
        (dolist (charset '(han kana bopomofo cjk-misc symbol))
          (set-fontset-font t charset (font-spec :family slin/font-family-cjk))
          (set-fontset-font (frame-parameter target-frame 'font) charset (font-spec :family slin/font-family-cjk)))))))

(if (daemonp)
    (add-hook 'after-make-frame-functions #'load-font-setup)
  (load-font-setup))

;; org-table 单独指定中文字体族
(with-eval-after-load 'org
  (set-face-attribute 'org-table nil :family slin/font-family-cjk :height (* slin/font-size 10)))

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

;; Buffer 标签页 (tab-line) 样式配置
(use-package tab-line
  :hook (after-init . global-tab-line-mode)
  :custom
  ;; 关闭标签页上的关闭按钮，使外观更整洁居中
  (tab-line-close-button-show nil)
  ;; 不显示前后的翻页切换按钮
  (tab-line-new-button-show nil)
  :config
  ;; 1. 禁用 tab-line 原生把未保存标签变灰 (tab-line-tab-modified) 的 face 覆盖
  (setq tab-line-tab-face-functions (delq 'tab-line-tab-face-modified tab-line-tab-face-functions))

  ;; 定义未保存图标专属 face (Catppuccin yellow)
  (defface slin/tab-line-modified-face
    '((t :weight bold))
    "Face for modified buffer indicator icon in tab-line."
    :group 'slin)

  ;; 2. Tab 名称居中
  (defun slin/tab-line-tab-name-buffer-centered (buffer &optional _buffers)
    (let ((name (buffer-name buffer)))
      (format "  %s  " name)))
  (setq tab-line-tab-name-function #'slin/tab-line-tab-name-buffer-centered)

  ;; 3. 在原生标签格式化字符串中，追加未保存图标 (\ueeb1)
  (defun slin/tab-line-tab-name-format (tab tabs)
    (let* ((orig (tab-line-tab-name-format-default tab tabs))
           (buffer-p (bufferp tab))
           (buffer (if buffer-p tab (cdr (assq 'buffer tab))))
           (modified (and buffer (buffer-file-name buffer) (buffer-modified-p buffer))))
      (if (and modified (stringp orig) (string-suffix-p "  " orig))
          (concat (substring orig 0 -2)
                  (propertize " \ueeb1"
                              'face 'slin/tab-line-modified-face
                              'tab tab
                              'keymap tab-line-tab-map
                              'mouse-face 'tab-line-highlight)
                  "  ")
        orig)))
  (setq tab-line-tab-name-format-function #'slin/tab-line-tab-name-format)
  ;; 4. 颜色与分割线样式调整 (保持原有背景色)
  (defun slin/setup-tab-line-faces ()
    (when (featurep 'catppuccin-theme)
      (let ((sep-color    (catppuccin-color 'surface0))     ; 分隔线颜色 (Catppuccin surface0)
            (active-fg    (catppuccin-color 'mauve))        ; 选中文字高亮 (Catppuccin mauve)
            (inactive-fg  (catppuccin-color 'subtext0))     ; 未选中文字颜色
            (yellow-color (catppuccin-color 'yellow)))      ; 未保存图标颜色 (Catppuccin yellow)
        ;; 1. Tab 栏与下方 Buffer 区域的分割线（使用 bottom-line 下划线）
        (set-face-attribute 'tab-line nil
                            :underline (list :color sep-color :style 'line :position t))
        ;; 2. 选中的 tab：取消背景高亮（与 tab-line 背景一致），仅文字高亮加粗
        (let ((base-bg (face-attribute 'tab-line :background nil t)))
          (set-face-attribute 'tab-line-tab-current nil
                              :foreground active-fg
                              :background base-bg
                              :weight 'bold
                              :box nil))
        ;; 3. 未选中的 tab
        (set-face-attribute 'tab-line-tab-inactive nil
                            :foreground inactive-fg
                            :box nil)
        ;; 普通 tab
        (set-face-attribute 'tab-line-tab nil
                            :box nil)
        ;; 4. 未保存图标颜色：Catppuccin yellow
        (set-face-attribute 'slin/tab-line-modified-face nil
                            :foreground yellow-color
                            :weight 'bold)
        ;; 5. 窗口垂直分割线（与 Tab 栏分割线一致，使用 surface0 细线）
        (set-face-attribute 'vertical-border nil
                            :foreground sep-color
                            :background (catppuccin-color 'base))
        (set-face-attribute 'window-divider nil
                            :foreground sep-color)
        (set-face-attribute 'window-divider-first-pixel nil
                            :foreground sep-color)
        (set-face-attribute 'window-divider-last-pixel nil
                            :foreground sep-color)
        ;; 强制刷新全局 tab-line 缓存
        (when (fboundp 'tab-line-force-update)
          (tab-line-force-update t)))))

  ;; 主题加载后立即应用 face 定制
  (slin/setup-tab-line-faces)
  (advice-add 'load-theme :after (lambda (&rest _) (slin/setup-tab-line-faces))))

;; 开启单像素窗口分割线，确保树窗口侧边栏与主编辑区分割线风格与 Tab 分割线一致
(setq window-divider-default-places 'right-only
      window-divider-default-right-width 1)
(add-hook 'after-init-hook #'window-divider-mode)
(unless (daemonp)
  (window-divider-mode 1))

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

(defun my-eww-clean-v2ex-format ()
  "优化 EWW 中 V2EX 首页的排版：删除下方重复用户名，合并多余换行，并保留链接"
  (let ((url (plist-get eww-data :url)))
    ;; 确保只对 V2EX 首页生效
    (when (and url (string-match-p "^https?://\\(www\\.\\)?v2ex\\.com/?$" url))
      (let ((inhibit-read-only t)) ; 允许修改 EWW 缓冲区

        ;; 模块 1：精准删除重复的用户名
        (save-excursion
          (goto-char (point-min))
          ;; 匹配模式：开头有空格的用户名 -> 标题 -> 换行 -> 重复的用户名
          (while (re-search-forward "^ +\\([^ \n\t]+\\)[ \t]+.+\n+\\1$" nil t)
            (let ((match-end (point)))
              (save-excursion
                ;; 回溯到重复用户名行的开头，向前删除到标题末尾，彻底抹掉中间的换行和重复名字
                (forward-word -1)
                (beginning-of-line)
                (delete-region (1- (point)) match-end)))))

        ;; 模块 2：把主题之间残留下来的连续 3 个及以上的换行全部压缩
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward "^$" nil t)
            (delete-region (match-beginning 0) (min (point-max) (1+ (match-end 0))))))
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward "\\s-\\*\\s-" nil t)
            (replace-match "")))
        ))))
;; (add-hook 'eww-after-render-hook #'my-eww-clean-v2ex-format))


(with-eval-after-load 'shr
  (defun my-shr-div-filter (dom)
    "终极修正版：精准拦截目标 div，放行并渲染普通 div"
    (let ((class (dom-attr dom 'class))
          (id (dom-attr dom 'id)))
      (cond
       ;; ========================================================
       ;; 1. 命中删除条件：直接返回 t，阻止该 div 及其子代渲染
       ;; ========================================================
       ((and id (member id '("sidebar" "ad-container" "footer")))
        t)

       ((and class (or (string-match-p "link-bottom-line" class)
                       (string-match-p "posters" class)
                       ))

        t)

       ;; ========================================================
       ;; 2. 安全放行条件：必须手动调用 shr-generic 渲染，然后返回 t
       ;; ========================================================
       (t
        (shr-generic dom) ; 👈 关键：手动命令引擎正常渲染这个普通的 div
        t))))             ; 👈 返回 t，告诉 shr 别再重复处理它了

  ;; 刷新绑定
  (setq shr-external-rendering-functions
        (assq-delete-all 'div shr-external-rendering-functions))
  (add-to-list 'shr-external-rendering-functions '(div . my-shr-div-filter)))

(provide 'init-ui)
;;; init-ui.el ends here
