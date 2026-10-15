;;; init-base.el --- General edit sessions and editor base settings  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 基础编辑设置：撤销历史树 (undo-tree)、备份策略、Magit Git 版本控制、
;; 最近文件 (recentf)、光标记忆 (save-place) 及环境变量同步。
;;

;;; Code:

;; 撤销历史树：重新打开文件时记住之前改动
(use-package undo-tree
  :init
  (global-undo-tree-mode)
  :config
  (let ((hist-dir (expand-file-name "undo-tree-hist" user-emacs-directory)))
    (make-directory hist-dir t)
    (setq undo-tree-history-directory-alist `(("." . ,hist-dir))
          undo-tree-auto-save-history t)))

;; 同步 Shell 环境变量 (GUI 模式)
(use-package exec-path-from-shell
  :if (and (memq system-type '(darwin gnu/linux)) (display-graphic-p))
  :config
  (exec-path-from-shell-initialize)
  (exec-path-from-shell-copy-envs '("SSH_AUTH_SOCK" "GPG_TTY"))
  (when (bound-and-true-p my-paths)
    (let ((expanded-paths (mapcar #'expand-file-name my-paths)))
      (setenv "PATH" (concat (string-join expanded-paths path-separator)
                             path-separator
                             (getenv "PATH")))
      (setq exec-path (append expanded-paths exec-path)))))

;; GPG / EPA 设置：在 Emacs Minibuffer 中直接输入 GPG 密码 (Loopback 模式)
(setq epa-pinentry-mode 'loopback)

;; 备份与自动保存策略
(setq auto-save-default nil)    ; 关闭自动保存
(setq create-lockfiles nil)     ; 关闭锁文件
(setq delete-old-versions t)    ; 自动删除旧版本
(setq kept-new-versions 10)     ; 保留最新的 10 个版本
(setq kept-old-versions 2)      ; 保留最早的 2 个版本
(setq version-control t)        ; 开启编号备份
(setq backup-by-copying t)      ; 复制备份，保护硬链接
;; 仅启用 Git 版本控制后端，避免在非 Git 目录探测老旧 VCS 卡顿
(setq vc-handled-backends '(Git))

;; 保存前清理尾部空白 (排除当前光标行)
(defun auto-save-delete-trailing-whitespace-except-current-line ()
  "在自动保存前，删除除当前活动行以外的所有行尾空格."
  (interactive)
  (let ((begin (line-beginning-position))
        (end (point)))
    (save-excursion
      (when (< (point-min) begin)
        (save-restriction
          (narrow-to-region (point-min) (1- begin))
          (delete-trailing-whitespace)))
      (when (> (point-max) end)
        (save-restriction
          (narrow-to-region end (point-max))
          (delete-trailing-whitespace))))))

(add-hook 'before-save-hook #'auto-save-delete-trailing-whitespace-except-current-line)

;; Git 版本控制 (Magit & Diff-hl)
;; 定义按 Commit Hash 循环着色的 Face 调色板 (Catppuccin Mocha 背景色风格)
(defface my/magit-blame-c1 '((t (:background "#89b4fa" :foreground "#11111b" :extend t))) "Catppuccin Mocha Blue BG.")
(defface my/magit-blame-c2 '((t (:background "#a6e3a1" :foreground "#11111b" :extend t))) "Catppuccin Mocha Green BG.")
(defface my/magit-blame-c3 '((t (:background "#f9e2af" :foreground "#11111b" :extend t))) "Catppuccin Mocha Yellow BG.")
(defface my/magit-blame-c4 '((t (:background "#cba6f7" :foreground "#11111b" :extend t))) "Catppuccin Mocha Mauve BG.")
(defface my/magit-blame-c5 '((t (:background "#fab387" :foreground "#11111b" :extend t))) "Catppuccin Mocha Peach BG.")
(defface my/magit-blame-c6 '((t (:background "#f38ba8" :foreground "#11111b" :extend t))) "Catppuccin Mocha Pink BG.")
(defface my/magit-blame-c7 '((t (:background "#94e2d5" :foreground "#11111b" :extend t))) "Catppuccin Mocha Teal BG.")

(defvar my/magit-blame-faces
  '(my/magit-blame-c1
    my/magit-blame-c2
    my/magit-blame-c3
    my/magit-blame-c4
    my/magit-blame-c5
    my/magit-blame-c6
    my/magit-blame-c7))

(defun my/magit-blame-commit-face (rev)
  "根据 Commit REV 哈希值动态分配 Catppuccin 调色板 Face."
  (if (and rev (stringp rev) (>= (length rev) 6))
      (let ((idx (mod (string-to-number (substring rev 0 6) 16) (length my/magit-blame-faces))))
        (nth idx my/magit-blame-faces))
    'magit-blame-margin))

(defun my/magit-blame-format-string-1 (orig-fn rev revinfo format face)
  "在 Magit 格式化边栏字段后，将 Commit 专属 FACE 插入至 face 列表的最前端（顶级优先级）."
  (let* ((cface (my/magit-blame-commit-face rev))
         (str (funcall orig-fn rev revinfo format face))
         (len (length str)))
    (when (and str (stringp str))
      (dotimes (i len)
        (let ((f (get-text-property i 'font-lock-face str)))
          (put-text-property
           i (1+ i) 'font-lock-face
           (cons cface (if (listp f) f (and f (list f))))
           str))))
    str))

;; 提高 Emacs 与外部子进程通信的吞吐量 (Windows 默认 4KB 太低，提升到 1MB 大幅提升 Magit 读 git 管道性能)
(setq read-process-output-max (* 1024 1024))
;; 限制版本控制后端只检测 Git，避免扫描 RCS/CVS/SVN/Bazaar 产生额外开销
(setq vc-handled-backends '(Git))

(use-package magit
  :defer t
  :init
  ;; 禁用 magit 自动更新模式与全局 revert，由用户手动控制或按需触发
  (setq magit-auto-revert-mode nil)
  :config
  ;; 1. 精简 status sections 钩子：移除非必需的 tags/unpushed 遍历，极大降低一次性 spawn 进程数
  (setq magit-status-sections-hook
        '(magit-insert-status-headers
          magit-insert-merge-log
          magit-insert-rebase-sequence
          magit-insert-am-sequence
          magit-insert-sequencer-sequence
          magit-insert-bisect-output
          magit-insert-bisect-rest
          magit-insert-bisect-log
          magit-insert-untracked-files
          magit-insert-unstaged-changes
          magit-insert-staged-changes
          magit-insert-stashes
          magit-insert-unpushed-to-pushremote
          magit-insert-unpushed-to-upstream-or-recent
          magit-insert-unpulled-from-pushremote
          magit-insert-unpulled-from-upstream))

  ;; 2. 禁用昂贵的 word-diff (字符级差异高亮，极耗 CPU)
  (setq magit-diff-refine-hunk nil)

  ;; 3. 避免刷新关联附属 buffer，只刷新当前 status 页面
  (setq magit-refresh-status-buffer nil)

  ;; 设置 Blame 时间格式为 yy-MM-dd HH:mm:ss
  (setq magit-blame-time-format "%y-%m-%d %H:%M:%S")

  ;; 设置 magit-blame 使用 margin 边栏样式 (格式：作者 -> 时间 -> Commit ID 放最后)
  (setq magit-blame-styles
        '((margin
           (margin-format . " %-10a %A %h ")
           (margin-width . 38)
           (margin-face . magit-blame-margin)
           (margin-body-face . nil))))

  ;; 挂载底层格式化 Advice，动态注入最优先级的 Commit Face
  (advice-add 'magit-blame--format-string-1 :around #'my/magit-blame-format-string-1))

;; =============================================================================
;; AI 辅助 Commit 注释生成 (基于 gptel)
;; =============================================================================

(use-package gptel
  :defer t
  :config
  ;; 配置网络代理（适配 Clash / v2ray 默认 7890 端口，确保 Google Gemini API 顺畅连通）
  (setenv "http_proxy" "http://127.0.0.1:7890")
  (setenv "https_proxy" "http://127.0.0.1:7890")
  (setq gptel-proxy "http://127.0.0.1:7890")

  ;; 配置 Google Gemini 模型后端
  ;; 支持从环境变量 GEMINI_API_KEY 读取，或通过 my/gemini-api-key 变量提供
  (setq gptel-model 'gemini-2.5-flash
        gptel-backend
        (gptel-make-gemini "Gemini"
          :key (lambda () (or (getenv "GEMINI_API_KEY")
                              (bound-and-true-p my/gemini-api-key)
                              "YOUR_GEMINI_API_KEY"))
          :stream t)))

(defun my/magit-generate-commit-message ()
  "直接调用 curl 通过代理异步请求 Gemini API，将生成的 Commit 注释插入当前 Buffer。"
  (interactive)
  (let* ((target-buffer (current-buffer))
         (api-key (or (getenv "GEMINI_API_KEY")
                      (bound-and-true-p my/gemini-api-key)))
         (raw-diff (with-temp-buffer
                     (call-process "git" nil t nil "diff" "--cached")
                     (buffer-string)))
         ;; 过滤掉 git 的 warning/提示信息
         (clean-diff (with-temp-buffer
                       (insert raw-diff)
                       (goto-char (point-min))
                       (flush-lines "^warning: ")
                       (buffer-string)))
         (diff (if (> (length clean-diff) 4000)
                   (concat (substring clean-diff 0 4000) "\n\n... (diff truncated)")
                 clean-diff)))
    (cond
     ((not api-key)
      (message "未找到 Gemini API Key！请检查 init-secret.el 或 GEMINI_API_KEY 环境变量。"))
     ((string-blank-p (string-trim diff))
      (message "没有检测到已暂存的更改 (staged changes)！请先在 Magit 中暂存 (s) 文件。"))
     (t
      (message "正在调用 Gemini 流式生成 Commit Message...")
      (let* ((prompt (format "请根据以下 `git diff --cached` 内容生成一条规范的 Git Commit 提交说明。\n要求：\n1. 严格遵循 Conventional Commits 规范 (例如 feat, fix, docs, style, refactor, perf, test, chore)。\n2. 第一行：简洁明确的主题行（不超过 70 字符），使用中文（或与项目风格一致）。\n3. 如果变动内容较多，空一行后列出具体变更要点（要点式短句）。\n4. 只输出 Commit Message 正文，严禁包含任何 Markdown 格式代码块标记（如 ```），不要添加任何额外寒暄与解释。\n\nDiff 内容:\n%s" diff))
             (json-payload (json-encode
                            `((contents . [((parts . [((text . ,prompt))]))]))))
             ;; Gemini SSE 流式端点: streamGenerateContent?alt=sse
             (url (format "https://generativelanguage.googleapis.com/v1beta/models/gemini-3.6-flash:streamGenerateContent?alt=sse&key=%s" api-key))
             (insert-marker (with-current-buffer target-buffer
                              (goto-char (point-min))
                              (copy-marker (point) t)))
             (sse-buffer "")
             (accumulated-text "")
             (proc (let ((process-connection-type nil)
                         (default-process-coding-system '(utf-8-unix . utf-8-unix)))
                     (start-process "gemini-curl" nil
                                    "curl.exe"
                                    "-N"                  ; 禁用 curl 缓冲区，即时流式输出
                                    "-s"
                                    "-x" "http://127.0.0.1:7890"
                                    "-X" "POST"
                                    "-H" "Content-Type: application/json; charset=utf-8"
                                    "-d" json-payload
                                    url))))
        (set-process-coding-system proc 'utf-8-unix 'utf-8-unix)
        ;; 进程输出过滤器：实时拦截 SSE 数据帧，解析并打字流式写入 Commit Buffer
        (set-process-filter
         proc
         (lambda (_proc string)
           (setq sse-buffer (concat sse-buffer string))
           ;; 循环解析出完整的行
           (while (string-match "\\(.*\\)[\r\n]+" sse-buffer)
             (let ((line (string-trim (match-string 1 sse-buffer))))
               (setq sse-buffer (substring sse-buffer (match-end 0)))
               (when (string-prefix-p "data: " line)
                 (let* ((json-str (string-trim (substring line 6)))
                        (json-data (ignore-errors (json-read-from-string json-str)))
                        (chunk-text (ignore-errors
                                      (let* ((candidates (alist-get 'candidates json-data))
                                             (first-cand (if (vectorp candidates) (aref candidates 0) (car candidates)))
                                             (content (alist-get 'content first-cand))
                                             (parts (alist-get 'parts content))
                                             (first-part (if (vectorp parts) (aref parts 0) (car parts))))
                                        (alist-get 'text first-part)))))
                   (when (and chunk-text (> (length chunk-text) 0))
                     (setq accumulated-text (concat accumulated-text chunk-text))
                     (when (buffer-live-p target-buffer)
                       (with-current-buffer target-buffer
                         (save-excursion
                           (goto-char insert-marker)
                           (insert chunk-text)))))))))))
        (set-process-sentinel
         proc
         (lambda (proc event)
           (when (string-match-p "finished" event)
             (when (buffer-live-p target-buffer)
               (with-current-buffer target-buffer
                 (save-excursion
                   (goto-char insert-marker)
                   (insert "\n\n"))))
             (message "--- [Gemini 流式返回日志] ---\n%s\n--------------------------------"
                      (if (> (length accumulated-text) 0) accumulated-text "空返回"))
             (if (> (length accumulated-text) 0)
                 (message "Commit Message 流式生成完毕！")
               (message "生成失败: %s" sse-buffer))))))))))

;; 在提交说明编辑窗口 (git-commit-mode) 绑定快捷键
(with-eval-after-load 'git-commit
  (define-key git-commit-mode-map (kbd "C-c C-a") #'my/magit-generate-commit-message)
  (with-eval-after-load 'evil
    (evil-define-key 'normal git-commit-mode-map (kbd "<leader>a") #'my/magit-generate-commit-message)))

(global-auto-revert-mode 1)

(use-package diff-hl
  :hook ((prog-mode text-mode dired-mode) . diff-hl-mode)
  :config
  (add-hook 'magit-pre-refresh-hook #'diff-hl-magit-pre-refresh)
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh)
  (diff-hl-margin-mode))

;; 光标处同名符号高亮
(use-package symbol-overlay
  :bind
  ("M-i" . symbol-overlay-put)
  ("M-n" . symbol-overlay-jump-next)
  ("M-p" . symbol-overlay-jump-prev))

;; 最近打开的文件记录 (禁用启动同步全盘 stat 检查，移至空闲定时器载入)
(use-package recentf
  :defer 0.5
  :custom
  (recentf-auto-cleanup 'never)
  :init
  (run-with-idle-timer 1 nil #'recentf-mode)
  :config
  (setq recentf-max-saved-items 100
        recentf-exclude '("/tmp/" "/ssh:" "\\.git/" "/elpa/" "eglot-jdtls-sources")))

;; 记住上次打开文件时的光标位置 (延迟加载)
(run-with-idle-timer 1 nil #'save-place-mode)

;; 网页内置浏览器与 HTML 渲染优化 (EWW / SHR)
(with-eval-after-load 'shr
  (setq shr-inhibit-images t)                   ; 默认不显示网页图片，大幅提升页面加载速度
  (setq shr-use-colors nil)                     ; 强制使用 Emacs 当前主题配色
  (setq shr-bullet "• "))                       ; 优化无序列表符号

(with-eval-after-load 'eww
  (define-key eww-mode-map (kbd "i") #'eww-toggle-images)
  (with-eval-after-load 'evil
    (evil-define-key 'normal eww-mode-map (kbd "i") #'eww-toggle-images)))

(add-hook 'eww-mode-hook
          (lambda ()
            (setq-local line-spacing 0.25)))   ; EWW 视图专属舒适行间距

(when (and (eq system-type 'gnu/linux)
           (getenv "WSL_DISTRO_NAME"))
  ;; WSL / WSLg 环境解决剪切板共享及中文乱码问题
  (set-clipboard-coding-system 'gbk-dos))

(defun copy-current-buffer-file-path ()
  "当前 Buffer 的全路径复制到剪贴板."
  (interactive)
  (if-let* ((file-path (buffer-file-name)))
      (progn
        (kill-new file-path)
        (message "已复制路径: %s" file-path))
    (message "当前 Buffer 未关联任何文件！")))

;; 绑定快捷键 C-c f
(global-set-key (kbd "C-c f") #'copy-current-buffer-file-path)

(provide 'init-base)
;;; init-base.el ends here
