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

;; 因为 early-init.el 中设置了 (setq package-enable-at-startup nil) 来优化启动，
;; 所以必须在此处手动调用 (package-initialize) 加载已安装包的 autoloads。
;; 当 package-enable-at-startup 为 nil 时，调用 package-initialize 不会触发 Unnecessary 警告。
(package-initialize)

;; Emacs 29+ 已经原生内置 use-package，无需再通过 ELPA 动态检测与网络安装
(eval-when-compile
  (require 'use-package))

(setq use-package-always-ensure t)

(provide 'init-package)
;;; init-package.el ends here
