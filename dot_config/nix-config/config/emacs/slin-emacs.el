;;; slin-emacs.el --- Main Emacs configuration entry  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 个人 Emacs 配置主入口：设置系统 PATH 环境变量，按逻辑清晰加载各大分步模块。
;;

;;; Code:

;; 1. 提升进程输出读取上限，优化 LSP (eglot)
(setq read-process-output-max (* 1024 1024))

;; 2. 备份文件统一存放位置
(setq backup-directory-alist `((".*" . ,(expand-file-name "backups" user-emacs-directory))))

;; 3. 全局 PATH 与 exec-path 设置
(defconst my-paths '("~/.nix-profile/bin"
                     "/etc/profiles/per-user/lin/bin"
                     "/run/current-system/sw/bin"
                     "/opt/homebrew/bin"
                     "/usr/local/bin"
                     "~/.local/share/nvim/mason/bin/"
                     "~/.local/bin/"
                     "/Library/TeX/texbin/"))
(defconst my-paths-join (string-join (mapcar #'expand-file-name my-paths) ":"))

(setenv "PATH" (concat my-paths-join ":" (getenv "PATH")))
(setq exec-path (append (mapcar #'expand-file-name my-paths) exec-path))

;; 注入 Nix 安装的 librime 路径供编译使用
(when (bound-and-true-p nix-librime-path)
  (setenv "LIBRARY_PATH" (concat nix-librime-path "/lib:" (getenv "LIBRARY_PATH")))
  (setenv "CPATH" (concat nix-librime-path "/include" (if (getenv "CPATH") (concat ":" (getenv "CPATH")) ""))))

;; 基础缩进风格
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;; M-x 命令历史保留
(savehist-mode 1)

;; 4. 按逻辑模块划分依次加载子配置
(require 'init-package)      ; 包管理器初始化 (use-package / ELPA)
(require 'init-base)         ; 基础编辑策略 (Session, Undo-tree, Magit, Recentf)
(require 'init-ui)           ; 外观界面美化 (Theme, Font, Modeline, Dimmer)
(require 'init-input)        ; 中文输入法 (emacs-rime/Rime) 与按键修饰符
(require 'init-completion)   ; Minibuffer & In-buffer 补全检索 (Vertico, Consult, Corfu, Xref)
(require 'init-keybinding)   ; Evil 框架与全局 Leader 快捷键映射
(require 'init-prog)         ; 编程语言服务 (Eglot, Treesit, Apheleia, Project)
(require 'init-dap)          ; 代码调试器 (Dape, Java HCR, Attach)
(require 'init-database)     ; 数据库支持 (SQL, Clutch, myclirc 自动解析)
(require 'init-dired)        ; 文件管理器 (Dired)
(require 'init-org)          ; Org-mode 知识库 & GTD & Roam

;; 5. 加载本地自定义变量文件
(when (and custom-file (file-exists-p custom-file))
  (load custom-file nil :nomessage))

(provide 'slin-emacs)
;;; slin-emacs.el ends here
