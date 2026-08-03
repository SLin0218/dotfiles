;;; init-database.el --- Database clients and SQL editing  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 数据库开发支持：
;; 1. 动态解析 ~/.myclirc 和 ~/.dbconns 数据库连接配置。
;; 2. SQL 模式与自动格式化。
;; 3. Clutch 现代化交互式数据库客户端。
;;

;;; Code:

(require 'url-util)

;; 解决 macOS/Nix 环境下缺少 C 编译器导致动态编译 subr 蹦床（如 read-char）时崩溃的问题
(setq native-comp-enable-subr-trampolines nil)

(defun my-parse-dsn (dsn-str)
  "Parse a DSN string (mysql/postgres/postgresql) and return a plist of components.
Supported format: [proto]://[user[:pass]@]host[:port][/db][?query]"
  (when (string-match "^\\(mysql\\|postgres\\|postgresql\\)://\\(.*\\)$" dsn-str)
    (let* ((proto-str (match-string 1 dsn-str))
           (proto (if (string-equal proto-str "mysql") 'mysql 'postgres))
           (rest (match-string 2 dsn-str))
           (user nil)
           (pass nil)
           (host nil)
           (port nil)
           (db nil))
      (let* ((at-idx (string-match "@\\([^@]*\\)$" rest))
             (user-pass-str (if at-idx (substring rest 0 at-idx) nil))
             (host-port-db-str (if at-idx (substring rest (1+ at-idx)) rest)))
        ;; 解析 host-port-db-str，格式为 host[:port][/db][?query]
        (when (string-match "^\\([^:/ \t\n]+\\)\\(?::\\([0-9]+\\)\\)?\\(?:/\\([^? \t\n]*\\)\\)?\\(?:\\?\\(.*\\)\\)?$" host-port-db-str)
          (setq host (match-string 1 host-port-db-str))
          (let ((port-str (match-string 2 host-port-db-str)))
            (setq port (if port-str
                           (string-to-number port-str)
                         (if (eq proto 'mysql) 3306 5432))))
          (let ((db-raw (match-string 3 host-port-db-str)))
            (setq db (when (and db-raw (not (string-empty-p db-raw))) db-raw))))
        (when user-pass-str
          (cond
           ((string-match "^\\([^:]+\\):\\(.*\\)$" user-pass-str)
            (setq user (match-string 1 user-pass-str))
            (setq pass (url-unhex-string (match-string 2 user-pass-str))))
           ((string-match "^\\([^@]+\\)@\\(.*\\)$" user-pass-str)
            (setq user (match-string 1 user-pass-str))
            (setq pass (url-unhex-string (match-string 2 user-pass-str))))
           (t
            (setq user user-pass-str)))))
      (list :backend proto
            :user (or user (if (eq proto 'mysql) "root" "postgres"))
            :password pass
            :host host
            :port port
            :database (or db (if (eq proto 'mysql) nil "postgres"))))))

(defun my-parse-db-connections-file (file &optional require-section)
  "Parse database connection configurations from FILE.
If REQUIRE-SECTION is non-nil, only parse lines under that [section]."
  (let ((conns nil))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (let ((start-parsing t))
          (when require-section
            (setq start-parsing nil)
            (when (re-search-forward (format "^\\[%s\\]" require-section) nil t)
              (setq start-parsing t)
              (forward-line 1)))
          (when start-parsing
            (let ((continue t))
              (while (and continue (not (eobp)))
                (let ((line (string-trim (buffer-substring-no-properties (line-beginning-position) (line-end-position)))))
                  (cond
                   ((string-match-p "^\\[" line)
                     (setq continue nil))
                   ((or (string-empty-p line)
                        (string-match-p "^[#;]" line))
                    nil)
                   ((string-match "^\\([^#=; \t\n]+\\)[ \t]*=[ \t]*\\(mysql://.*\\)$" line)
                    (let* ((name (match-string 1 line))
                           (dsn-str (match-string 2 line))
                           (parsed (my-parse-dsn dsn-str)))
                      (when parsed
                        (push (cons name parsed) conns))))))
                (forward-line 1)))))))
    (nreverse conns)))

(defun my-parse-dbconns-sexp-file (file)
  "Parse database connections from a Lisp sexp file."
  (let ((raw-list nil)
        (conns nil))
    (when (file-readable-p file)
      (with-temp-buffer
        (insert-file-contents file)
        (goto-char (point-min))
        (condition-case nil
            (setq raw-list (read (current-buffer)))
          (error nil))
        (dolist (item raw-list)
          (when (and (listp item) (car item))
            (push (cons (car item) (cdr item)) conns)))))
    (nreverse conns)))

;; 动态从 ~/.myclirc 和 ~/.dbconns 自动解析并加载所有数据库连接配置
(defun my-load-all-db-connections ()
  "Load database connections from both ~/.myclirc and ~/.dbconns."
  (interactive)
  (let ((all-raw-conns nil)
        (merged-conns nil)
        (sql-conns nil)
        (clutch-conns nil))
    ;; 1. 从 ~/.myclirc 读取 (需要 "alias_dsn" section)
    (setq all-raw-conns (append all-raw-conns (my-parse-db-connections-file (expand-file-name "~/.myclirc") "alias_dsn")))
    ;; 2. 从 ~/.dbconns 读取 (使用 sexp 格式)
    (setq all-raw-conns (append all-raw-conns (my-parse-dbconns-sexp-file (expand-file-name "~/.dbconns"))))
    
    ;; 3. 合并并去重，保留最新值并维持声明顺序，且强转为 String 解决类型冲突
    (dolist (item all-raw-conns)
      (let* ((name-raw (car item))
             (name (if (symbolp name-raw) (symbol-name name-raw) name-raw))
             (existing (assoc name merged-conns)))
        (if existing
            (setcdr existing (cdr item))
          (push (cons name (cdr item)) merged-conns))))
    (setq merged-conns (nreverse merged-conns))
    
    ;; 4. 转换并生成 Emacs database 配置 alist
    (dolist (item merged-conns)
      (let* ((name (car item)) ; 此时已是字符串
             (plist (cdr item))
             (backend-raw (plist-get plist :backend))
             ;; 对 sql-product 而言，必须是 'postgres (对于 pg 类) 或 'mysql
             (sql-product (cond
                           ((member backend-raw '(pg postgres postgresql)) 'postgres)
                           (t backend-raw)))
             ;; 对 clutch 而言，必须是 'pg 或 'mysql
             (clutch-backend (cond
                              ((member backend-raw '(pg postgres postgresql)) 'pg)
                              (t backend-raw)))
             (user (plist-get plist :user))
             (pass (plist-get plist :password))
             (host (plist-get plist :host))
             (port (plist-get plist :port))
             (db (plist-get plist :database)))
        (push `(,name (sql-product ',sql-product)
                      (sql-user ,user)
                      ,@(when pass `((sql-password ,pass)))
                      ,@(when db `((sql-database ,db)))
                      (sql-server ,host)
                      (sql-port ,port))
              sql-conns)
        (push `(,name . (:backend ,clutch-backend
                                  :host ,host
                                  :port ,port
                                  :user ,user
                                  ,@(when pass `(:password ,pass))
                                  ,@(when db `(:database ,db))))
              clutch-conns)))
    (setq sql-connection-alist (nreverse sql-conns))
    (setq clutch-connection-alist (nreverse clutch-conns))
    (message "Successfully loaded database connections: %s"
             (mapconcat #'identity (mapcar #'car clutch-connection-alist) ", "))))

(my-load-all-db-connections)

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
  :bind (:map sql-mode-map
              ("C-c C-f" . sqlformat-buffer))
  :init
  (setq sqlformat-command 'pgformatter))

;; Clutch 现代化交互式数据库客户端
(use-package mysql :ensure t)
(use-package pg :ensure t)
(use-package clutch
  :ensure t
  :config
  (add-hook 'clutch-result-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-record-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'clutch-describe-mode-hook (lambda () (display-line-numbers-mode -1))))

(provide 'init-database)
;;; init-database.el ends here
