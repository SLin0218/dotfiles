;;; init-package.el --- Package manager configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 包管理器初始化，配置 ELPA/MELPA 镜像源，确保 use-package 宏立即可用。
;;

;;; Code:

(require 'package)
(setq package-archives
      '(("gnu"   . "https://elpa.gnu.org/packages/")
        ("melpa" . "https://melpa.org/packages/")))
(package-initialize)

(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

(provide 'init-package)
;;; init-package.el ends here
