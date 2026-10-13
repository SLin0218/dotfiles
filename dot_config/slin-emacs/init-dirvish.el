;;; init-dirvish.el --- Dirvish file manager & side tree configuration  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; 基于 Dired 现代化的文件管理器 Dirvish 与侧边栏目录树：
;; 1. 集成 `dirvish-side` 作为 Treemacs 的轻量化平替。
;; 2. 启用 `dirvish-side-follow-mode` 实现当前 Buffer 文件自动跟随与定位。
;; 3. 匹配 Nerd-icons 图标美化体系与 Git 状态指示。
;; 4. 集成 Evil 导航键位 (h/j/k/l, TAB, q, a 等)。
;;

;;; Code:

(use-package dirvish
  :commands (dirvish dirvish-side dirvish-dwim)
  :init
  ;; 全局接管原生 Dired 模式
  (dirvish-override-dired-mode)
  :custom
  (dirvish-quick-access-entries
   '(("h" "~/"                          "Home")
     ("d" "~/Downloads/"                "Downloads")
     ("p" "~/workspace/"                "Projects")))
  (dirvish-mode-line-bar-image-width 0)  ; 去掉最前面的竖条/色块
  (dirvish-mode-line-format
   '(:left (sort symlink) :right (omit yank index)))
  (dirvish-attributes
   '(nerd-icons file-time file-size subtree-state vc-state-face))
  ;; 侧边栏配置
  (dirvish-side-width 32)
  (dirvish-side-attributes
   '(nerd-icons subtree-state vc-state-face))
  (dirvish-side-header-line-format '(:left (project-name)))
  :config
  ;; 自定义 project-name widget：去掉固定的 "Project:" 前缀，仅保留纯净的项目名称并保留左边距空格
  (dirvish-define-mode-line project-name
    "Show current project root name without prefix label."
    (let ((root (dirvish--vc-root-dir)))
      (format "  %s"
              (if root
                  (propertize (file-name-base (directory-file-name root))
                              'face 'font-lock-string-face)
                (propertize "-" 'face 'dirvish-inactive)))))
  ;; 自动跟随当前激活的 buffer 文件并在项目间自动切换
  (dirvish-side-follow-mode 1)

  ;; 禁用行号显示
  (add-hook 'dirvish-mode-hook (lambda () (display-line-numbers-mode -1)))
  (add-hook 'dired-mode-hook (lambda () (display-line-numbers-mode -1)))

  ;; Evil 模式下的键位集成
  (with-eval-after-load 'evil
    (evil-define-key 'normal dirvish-mode-map
      (kbd "q")     #'dirvish-quit
      (kbd "h")     #'dired-up-directory
      (kbd "j")     #'dired-next-line
      (kbd "k")     #'dired-previous-line
      (kbd "l")     #'dired-find-file
      (kbd "RET")   #'dired-find-file
      (kbd "TAB")   #'dirvish-subtree-toggle
      (kbd "o")     #'dirvish-subtree-toggle
      (kbd "a")     #'dirvish-quick-access
      (kbd "f")     #'dirvish-file-info-menu
      (kbd "y")     #'dirvish-yank-menu
      (kbd "s")     #'dirvish-quicksort
      (kbd "?")     #'dirvish-dispatch
      (kbd "<left>")  #'dired-up-directory
      (kbd "<right>") #'dired-find-file
      (kbd "<mouse-1>") #'dirvish-subtree-toggle-or-open)))

(provide 'init-dirvish)
;;; init-dirvish.el ends here
