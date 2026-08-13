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
  (setq slin/font-size 15))

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
