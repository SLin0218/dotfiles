;;; init-database.el --- Database clients and SQL editing  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 数据库开发支持：
;; 1. 动态解析 ~/.myclirc 数据库连接配置。
;; 2. SQL 模式与自动格式化。
;; 3. Clutch 现代化交互式数据库客户端。
;;

;;; Code:

;; 解决 macOS/Nix 环境下缺少 C 编译器导致动态编译 subr 蹦床（如 read-char）时崩溃的问题
(setq native-comp-enable-subr-trampolines nil)

(setq clutch-connection-alist
      '(("pg-dev-rx-plm" . (:backend pg :profile-entry "pg/dev/rx-plm"))
        ("redis-dev" .     (:backend redis :host "127.0.0.1" :port 6379 :database "5" :profile-entry "redis/dev"))))

;; SQL 编辑模式
(use-package sql
  :defer t
  :bind (:map sql-mode-map
              ("C-c C-c" . sql-send-paragraph)
              ("C-c C-r" . sql-send-region)
              ("C-c C-s" . sql-show-sqli-buffer))
  :config
  (add-hook 'sql-interactive-mode-hook
            (lambda ()
              (toggle-truncate-lines t)
              (setq-local show-trailing-whitespace nil)))
  (setq sql-mysql-options '("--skip-ssl")))

(use-package sql-indent
  :hook (sql-mode . sql-indent-enable))

(use-package sqlformat
  :defer t
  :init
  (setq sqlformat-command 'pgformatter)
  :config
  (evil-define-key 'normal sql-mode-map
    (kbd "<leader>fm") #'sqlformat-buffer))

;; Clutch 现代化交互式数据库客户端
(use-package mysql :ensure t)
(use-package pg :ensure t)
(use-package redis :vc (:url "https://github.com/LuciusChen/redis.el"))
(use-package clutch
  :ensure t
  :config
  (evil-define-key 'normal clutch-result-mode-map
    (kbd "f")         #'clutch-result-fullscreen-toggle
    (kbd "c")         #'clutch-result-view-value
    (kbd "N")         #'clutch-result-next-page
    (kbd "P")         #'clutch-result-prev-page
    (kbd "C")         #'clutch-result-goto-column
    (kbd "===")       #'clutch-result-widen-column
    (kbd "-")         #'clutch-result-narrow-column
    (kbd "<left>")    #'clutch-result-scroll-left
    (kbd "<right>")   #'clutch-result-scroll-right
    (kbd "<tab>")     #'clutch-result-next-cell
    (kbd "<backtab>") #'clutch-result-prev-cell)
  (add-hook 'clutch-result-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-record-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-describe-mode-hook (lambda () (display-line-numbers-mode -1))))

(provide 'init-database)
;;; init-database.el ends here
