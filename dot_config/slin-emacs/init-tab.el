;;; init-tab.el --- Tab and buffer tab-line configurations -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 针对 Emacs 的 Tab-line 标签栏进行深度美化与模块化配置。
;; 风格参考 doom-modeline 设计哲学：
;; - 极简利落，去除原生冗余翻页与关闭按钮
;; - 居中对称内边距，呈现现代胶囊/卡片式质感
;; - 支持文件类型图标（nerd-icons / all-the-icons 智能降级）
;; - 优雅的未保存指示器（与 doom-modeline 一致的 Catppuccin yellow 提示）
;; - 深度适配 Catppuccin 主题（动态拾取 palette，支持主题热重载）
;;

;;; Code:

(use-package tab-line
  :hook (after-init . global-tab-line-mode)
  :custom
  ;; 关闭标签页上的关闭按钮与翻页箭头，保持界面干净
  (tab-line-close-button-show nil)
  (tab-line-new-button-show nil)
  :config
  ;; 1. 禁用原生覆盖未保存标签的置灰行为
  (setq tab-line-tab-face-functions (delq 'tab-line-tab-face-modified tab-line-tab-face-functions))

  ;; 2. 定义专属 Face
  (defface slin/tab-line-active-face
    '((t :weight bold))
    "Face for the active tab in tab-line."
    :group 'slin)

  (defface slin/tab-line-inactive-face
    '((t :weight normal))
    "Face for inactive tabs in tab-line."
    :group 'slin)

  (defface slin/tab-line-modified-face
    '((t :weight bold))
    "Face for modified buffer indicator icon in tab-line."
    :group 'slin)

  ;; 3. 获取 Buffer 对应图标 (优先 nerd-icons，降级 all-the-icons)
  (defun slin/tab-line-buffer-icon (buffer)
    "Return formatted file icon string for BUFFER."
    (let ((icon-str
           (cond
            ((and (fboundp 'nerd-icons-icon-for-buffer) buffer)
             (with-current-buffer buffer
               (nerd-icons-icon-for-buffer)))
            ((and (fboundp 'all-the-icons-icon-for-buffer) buffer)
             (with-current-buffer buffer
               (all-the-icons-icon-for-buffer)))
            (t nil))))
      (if (and icon-str (stringp icon-str))
          (concat icon-str " ")
        "")))

  ;; 4. 格式化单项 Tab 文本与内容
  (defun slin/tab-line-tab-name-doom-style (buffer &optional _buffers)
    "Format BUFFER name with doom-modeline style padding and icon."
    (let* ((buf (if (bufferp buffer) buffer (get-buffer buffer)))
           (icon (if buf (slin/tab-line-buffer-icon buf) ""))
           (name (if buf (buffer-name buf) (format "%s" buffer))))
      (format " %s%s " icon name)))

  (setq tab-line-tab-name-function #'slin/tab-line-tab-name-doom-style)

  ;; 5. 在标签中动态加入未保存指示器 (\ueeb1 或圆点)
  (defun slin/tab-line-tab-name-format (tab tabs)
    "Append doom-modeline style modified dot to TAB."
    (let* ((orig (tab-line-tab-name-format-default tab tabs))
           (buffer-p (bufferp tab))
           (buffer (if buffer-p tab (cdr (assq 'buffer tab))))
           (modified (and buffer (buffer-file-name buffer) (buffer-modified-p buffer))))
      (if (and modified (stringp orig) (string-suffix-p " " orig))
          (let ((tab-face (or (get-text-property 0 'face orig) 'tab-line-tab)))
            (concat (substring orig 0 -1)
                    (propertize " \ueeb1 "
                                'face (list 'slin/tab-line-modified-face tab-face)
                                'tab tab
                                'keymap tab-line-tab-map
                                'mouse-face 'tab-line-highlight)))
        orig)))

  (setq tab-line-tab-name-format-function #'slin/tab-line-tab-name-format)

  ;; 6. Catppuccin 色彩配置与 Doom-modeline 风格 Faces 绑定
  (defun slin/setup-tab-line-faces ()
    "Setup tab-line faces matching doom-modeline style and Catppuccin palette."
    (when (featurep 'catppuccin-theme)
      (let* ((bg-base     (catppuccin-color 'base))
             (bg-mantle   (catppuccin-color 'mantle))
             (bg-surface0 (catppuccin-color 'surface0))
             (bg-surface1 (catppuccin-color 'surface1))
             (active-fg   (catppuccin-color 'mauve))
             (inactive-fg (catppuccin-color 'subtext0))
             (modified-fg (catppuccin-color 'yellow))
             (sep-color   bg-surface0))

        (let ((box-spec `(:line-width (1 . 1) :color ,sep-color :style flat-button)))
          ;; 整个 Tab-line 栏背景底色（mantle 底色 + surface0 顶部分割线与下划分割线）
          (set-face-attribute 'tab-line nil
                              :background bg-mantle
                              :foreground inactive-fg
                              :height 0.95
                              :underline (list :color sep-color :style 'line :position t)
                              :box box-spec)

          ;; 当前选中 Tab：微高亮底色 (base)、mauve 强调文字，底部彩色边框/下划线，顶部统一分割线
          (set-face-attribute 'tab-line-tab-current nil
                              :background bg-base
                              :foreground active-fg
                              :weight 'bold
                              :underline (list :color active-fg :style 'line :position t)
                              :box box-spec)

          ;; 非活动 Tab：沉浸于 mantle 背景，subtext0 柔和文字，顶部统一分割线
          (set-face-attribute 'tab-line-tab-inactive nil
                              :background bg-mantle
                              :foreground inactive-fg
                              :weight 'normal
                              :box box-spec)

          ;; 普通 Tab 兜底 face
          (set-face-attribute 'tab-line-tab nil
                              :background bg-mantle
                              :foreground inactive-fg
                              :box box-spec))

        ;; 鼠标悬浮预览 (Hover)
        (set-face-attribute 'tab-line-highlight nil
                            :background bg-surface1
                            :foreground (catppuccin-color 'text)
                            :box nil)

        ;; 未保存状态指示图标
        (set-face-attribute 'slin/tab-line-modified-face nil
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

        ;; 强制刷新 tab-line 缓存
        (when (fboundp 'tab-line-force-update)
          (tab-line-force-update t)))))

  ;; 主题加载及切换时自适应刷新
  (slin/setup-tab-line-faces)
  (advice-add 'load-theme :after (lambda (&rest _) (slin/setup-tab-line-faces))))

(provide 'init-tab)
;;; init-tab.el ends here
