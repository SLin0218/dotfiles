;(defconst user-emacs-cache-directory (expand-file-name ".cache" user-emacs-directory))             ;缓存文件存放位置 存放临时文件
;(setq recentf-save-file (expand-file-name "recentf" user-emacs-cache-directory))                   ;最近打开文件 存放位置
;(setq savehist-file (expand-file-name "history" user-emacs-cache-directory))                       ;savehist文件位置
;(setq auto-save-list-file-prefix (expand-file-name "auto-save-list" user-emacs-cache-directory))   ;自动保存文件目录
;(setq package-user-dir (expand-file-name "elpa" user-emacs-cache-directory))                       ;ELPA目录
;(setq tutorial-directory (expand-file-name "tutorial" user-emacs-cache-directory))

(setq backup-directory-alist `((".*" . ,(expand-file-name "backups" user-emacs-directory)))) ;备份文件存放位置

;不生成custom-file文件 使用 use-package custom
(setq custom-file "/dev/null")

(setenv "PATH" (concat "/opt/homebrew/bin:/usr/local/bin:~/.local/share/nvim/mason/bin/:~/.local/bin/:" (getenv "PATH")))
(setq exec-path (append '("/opt/homebrew/bin" "/usr/local/bin" "~/.local/share/nvim/mason/bin" "~/.local/bin/") exec-path))

(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)

;M+x历史命令保留
(savehist-mode 1)

(require 'init-package)
(require 'init-ui)
(require 'init-keybinding)
(require 'init-session)
(require 'init-dired)
(require 'init-complete)
(require 'init-org)

(provide 'slin-emacs)
