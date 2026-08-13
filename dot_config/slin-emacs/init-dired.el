;;; init-dired.el --- Dired configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 目录管理 (Dired) 增强：图标展示、文件类型高亮以及快捷搜索过滤。
;;

;;; Code:

(use-package dired
  :ensure nil
  :hook
  (dired-mode . dired-omit-mode) ; 隐藏 .git、.DS_Store 等
  :config
  (setq dired-listing-switches "-alh")
  ;; 退出 dired 时，自动杀死 (kill) 缓冲区而不仅是隐藏
  (define-key dired-mode-map (kbd "q") (lambda () (interactive) (quit-window t)))
  ;; 深入新目录时，自动杀死旧目录的 Dired 缓冲区，防止堆积
  (setq dired-kill-when-opening-new-dired-buffer t))

;; Dired 图标美化
(use-package all-the-icons-dired
  :after (dired all-the-icons)
  :hook (dired-mode . all-the-icons-dired-mode))

;; 文件类型语法高亮
(use-package diredfl
  :hook
  (dired-mode . diredfl-mode))

;; 模糊检索与过滤
(use-package dired-narrow
  :bind (:map dired-mode-map
         ("/" . dired-narrow))
  :config
  (setq dired-narrow-backend 'consult-line))

;; ---------------------------------------------------------------------------
;; 快速新建 Java 文件 (类似 IDEA 体验：自动计算包名、选类型、自动生成类骨架)
;; ---------------------------------------------------------------------------
(defun my/java-create-class (name type)
  "像 IDEA 一样在 Dired 或当前 Java 项目中快速新建类/接口/枚举/Record。
NAME 支持直接输入类名 (如 UserService) 或包含包前缀 (如 dto.UserReqDto)。
TYPE 可选 class, interface, enum, record, @interface。"
  (interactive
   (let* ((types '("class" "interface" "enum" "record" "@interface"))
          (type (completing-read "Java 结构类型 (默认 class): " types nil t nil nil "class"))
          (name (read-string (format "新建 Java %s 名称: " type))))
     (list name type)))
  (when (string-empty-p name)
    (user-error "类名不能为空！"))
  (let* ((base-dir (if (eq major-mode 'dired-mode)
                       (dired-current-directory)
                     (file-name-directory (or (buffer-file-name) default-directory))))
         ;; 支持输入 com.example.dto.UserDto 这种带有包路径的输入
         (parts (split-string name "\\."))
         (class-name (car (last parts)))
         (pkg-subdirs (butlast parts))
         (target-dir (if pkg-subdirs
                         (expand-file-name (mapconcat #'identity pkg-subdirs "/") base-dir)
                       base-dir))
         (file-path (expand-file-name (concat class-name ".java") target-dir))
         ;; 自动根据所在路径 (src/main/java/...) 计算 Java 包名
         (clean-dir (directory-file-name (file-truename target-dir)))
         (package-name
          (cond
           ((string-match "/src/\\(?:main\\|test\\)/java/\\(.*\\)$" clean-dir)
            (replace-regexp-in-string "/" "." (match-string 1 clean-dir)))
           ((string-match "/src/\\(.*\\)$" clean-dir)
            (replace-regexp-in-string "/" "." (match-string 1 clean-dir)))
           (t nil))))
    
    ;; 1. 若输入了深层包路径（如 dto.UserDto），自动创建缺失的子目录
    (unless (file-exists-p target-dir)
      (make-directory target-dir t))
    
    ;; 2. 打开/新建 Java 文件
    (find-file file-path)
    
    ;; 3. 如果是新文件，写入包名与类定义模板
    (when (= (buffer-size) 0)
      (when (and package-name (not (string-empty-p package-name)))
        (insert (format "package %s;\n\n" package-name)))
      (insert (format "public %s %s {\n    " type class-name))
      (save-excursion
        (insert "\n}\n")))))

;; 在 Dired 中绑定快捷键 (支持 C-c j c 或 Evil Normal 模式按 + )
(with-eval-after-load 'dired
  (define-key dired-mode-map (kbd "C-c j c") #'my/java-create-class))

(with-eval-after-load 'evil
  (evil-define-key 'normal dired-mode-map (kbd "+") #'my/java-create-class))

(provide 'init-dired)
;;; init-dired.el ends here

