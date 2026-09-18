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
      '(("pg-dev-rx-plm" . (:backend pg    :profile-entry "pg/dev/rx-plm"))
        ("tw-dev-yg"     . (:backend mysql :profile-entry "mysql/dev/tw-yg"))
        ("fawa-dev-ssh"  . (:backend mysql :profile-entry "mysql/dev/fwh"))
        ("redis-dev"     . (:backend redis :profile-entry "redis/dev"))))

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

(use-package apheleia
  :ensure t
  :defer t
  :hook (sql-mode . apheleia-mode)  ;; 进入 sql-mode 时激活
  :init
  ;; 如果你想全局所有编程语言保存时都自动格式化，可直接开启：
  ;; (apheleia-global-mode +1)
  :config
  ;; 1. 确保 apheleia 针对 sql-mode 默认使用 sqlfluff
  (setf (alist-get 'sql-mode apheleia-mode-alist) 'sqlfluff)

  ;; 2. 如果项目里没有 .sqlfluff 配置文件，默认回退方言（比如 mysql 或 ansi）
  ;; 格式化命令相当于: sqlfluff format --dialect mysql -
  (setf (alist-get 'sqlfluff apheleia-formatters)
        '("sqlfluff" "format" "--dialect" "mysql" "-"))

  ;; 3. 绑定 Evil normal 模式下的快捷键
  (with-eval-after-load 'evil
    (evil-define-key 'normal sql-mode-map
      (kbd "<leader>fm") #'apheleia-format-buffer)))

;; Clutch 现代化交互式数据库客户端
(use-package mysql :ensure t)
(use-package pgsql :ensure t)
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
