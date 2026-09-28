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

;; 开启 package-quickstart，支持预编译 autoloads 极速激活
(setq package-quickstart t)

(unless package--initialized
  (package-initialize))

;; Emacs 29+ 已经原生内置 use-package，无需再通过 ELPA 动态检测与网络安装
(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

(provide 'init-package)
;;; init-package.el ends here
