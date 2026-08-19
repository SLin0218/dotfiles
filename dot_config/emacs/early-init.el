;;; early-init.el --- 初始化配置  -*- lexical-binding: t; -*-
;;; Commentary:

;;; Code:
;;; 1. 垃圾回收 (GC) 优化：启动时设为最大值，加速加载
(setq gc-cons-threshold most-positive-fixnum)

;; 2. 临时禁用文件名处理器，加速文件加载
(defvar default-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)

;; 3. 恢复 GC 和 file-name-handler-alist 的 Hook
;; 当 Emacs 完全启动后，将它们还原为日常使用的合理值，并再次强制禁用无用 UI 栏
(add-hook 'emacs-startup-hook
          (lambda ()
            (setq gc-cons-threshold (* 16 1024 1024) ; 恢复到日常 16MB
                  file-name-handler-alist default-file-name-handler-alist)
            (when (fboundp 'menu-bar-mode) (menu-bar-mode -1))
            (when (fboundp 'tool-bar-mode) (tool-bar-mode -1))
            (when (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))))

;; 4. 压制异步编译警告并禁用内置函数蹦床编译（防止缺少 C 编译器驱动或 macOS SDK 时崩溃）
(setq native-comp-async-report-warnings-errors nil
      native-comp-enable-subr-trampolines nil)

;; 5. 禁用 package.el 自动激活（已经在 init-package.el 中手动激活）
(setq package-enable-at-startup nil)

;; 6. 屏蔽启动闪屏
(setq inhibit-startup-screen t
      inhibit-startup-message t
      inhibit-startup-echo-area-message "lin"
      initial-scratch-message nil)

;; 7. 早期 UI 优化（避免 GUI 创建后闪烁，并彻底全局禁用工具栏/菜单栏/滚动条）
(setq menu-bar-mode nil
      tool-bar-mode nil
      scroll-bar-mode nil)

(setq default-frame-alist
      '((menu-bar-lines . 0)
        (tool-bar-lines . 0)
        (vertical-scroll-bars . nil)
        (fullscreen . maximized)))

;; 解决终端（TTY）客户端连接时由于初始化机制自动重新开启菜单栏/工具栏的问题
(add-hook 'after-make-frame-functions
          (lambda (frame)
            (unless (display-graphic-p frame)
              (set-frame-parameter frame 'menu-bar-lines 0)
              (set-frame-parameter frame 'tool-bar-lines 0))))

;; 8. 将 custom-file 指向可写的本地文件，避免污染 init.el 且避免新版 Emacs 因 /dev/null 报错
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))

(provide 'early-init.el)
;;; early-init.el ends here
