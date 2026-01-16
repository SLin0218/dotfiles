(setq org-agenda-files (list (expand-file-name "~/org/agenda/")))

(with-eval-after-load 'org
  (set-face-attribute 'org-level-1 nil :weight 'bold :height 1.25 :foreground "#ff6b6b")
  (let ((colors '("#ffb86c" "#4ecdc4" "#a0c4ff" "#8be9fd" "#ffd6a5" "#ffadad")))
    (dolist (i (number-sequence 2 6))
      (set-face-attribute (intern (format "org-level-%d" i)) nil
			  :weight 'bold
			  :height (- 1.15 (* 0.03 (- i 2)))
			  :foreground (nth (1- i) colors))))

  ;开启标题缩进
  (setq org-startup-indented t)
  (global-org-modern-mode)

  ;code按语言缩进
  (setq org-src-tab-acts-natively t)
  (setq org-src-preserve-indentation nil)
  (setq org-blank-before-new-entry
	'((heading . auto) (plain-list-item . auto)))

  ;代码块高亮
  (setq org-src-fontify-natively t)

  (setq org-ellipsis "󱞣")

  ;block执行代码 通用配置
  (setq org-babel-default-header-args
        '((:session . "none")         ;是否启用持久会话
          (:exports . "code")         ;只导出代码
          (:results . "replace")))    ;替换结果
  ;; (setq org-modern-hide-stars nil
      ;; org-modern-todo nil)

  ;行间距
  (setq line-spacing 0.25)

  (setq org-use-property-inheritance t)
  ;; 子任务阻塞父任务
  (setq org-enforce-todo-dependencies t)

  ;; agenda 里只看叶子任务
  (setq org-agenda-todo-list-sublevels t)


  ;quote高亮
  (setq org-indent-indentation-per-level 2)
  (setq org-fontify-quote-and-verse-blocks t)
  (setq org-indent-mode-respect-standard-blocks t)
  ;; (setq org-agenda-todo-keyword-format "%-8s")
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "ACTIVITY(a)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELED(c@)")))
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)     ; 日志放入 LOGBOOK drawer，保持整洁
  (setq org-modern-todo-faces '(("TODO"     . (:foreground "#bd93f9" :background "#44475a" :height 1.3))
                                ("NEXT"     . (:foreground "#ffb86c" :background "#44475a" :height 1.3 :weight bold))
                                ("ACTIVITY" . (:foreground "#ff79c6" :background "#44475a" :height 1.3 :weight bold))
                                ("WAITING"  . (:foreground "#8be9fd" :background "#44475a" :height 1.3))
                                ("DONE"     . (:foreground "#50fa7b" :background "#44475a" :height 1.3))
                                ("CANCELED" . (:foreground "#6272a4" :background "#44475a" :height 1.3 :strike-through t))))
  (setq org-todo-keyword-faces '(("TODO"     . (:foreground "#bd93f9" :background "#44475a"))
                                 ("NEXT"     . (:foreground "#ffb86c" :background "#44475a" :weight bold))
                                 ("ACTIVITY" . (:foreground "#ff79c6" :background "#44475a" :weight bold))
                                 ("WAITING"  . (:foreground "#8be9fd" :background "#44475a"))
                                 ("DONE"     . (:foreground "#50fa7b" :background "#44475a"))
                                 ("CANCELED" . (:foreground "#6272a4" :background "#44475a" :strike-through t))))

  ;;latex 相关配置
  (setq org-latex-pdf-process
        '("latexmk -pdflatex='pdflatex -interaction nonstopmode' -pdf -bibtex -f %f"))

  (unless (boundp 'org-latex-classes)
    (setq org-latex-classes nil))

  (add-to-list 'org-latex-classes
               '("ethz"
                 "\\documentclass[a4paper,11pt,titlepage]{memoir}
 \\usepackage[utf8]{inputenc}
 \\usepackage[T1]{fontenc}
 \\usepackage{fixltx2e}
 \\usepackage{graphicx}
 \\usepackage{longtable}
 \\usepackage{float}
 \\usepackage{wrapfig}
 \\usepackage{rotating}
 \\usepackage[normalem]{ulem}
 \\usepackage{amsmath}
 \\usepackage{textcomp}
 \\usepackage{marvosym}
 \\usepackage{wasysym}
 \\usepackage{amssymb}
 \\usepackage{hyperref}
 \\usepackage{mathpazo}
 \\usepackage{color}
 \\usepackage{enumerate}
 \\definecolor{bg}{rgb}{0.95,0.95,0.95}
 \\tolerance=1000
 [NO-DEFAULT-PACKAGES]
 [PACKAGES]
 [EXTRA]
 \\linespread{1.1}
 \\hypersetup{pdfborder=0 0 0}"
                 ("\\chapter{%s}" . "\\chapter*{%s}")
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))


  (add-to-list 'org-latex-classes
               '("article"
                 "\\documentclass[11pt,a4paper]{article}
 \\usepackage[utf8]{inputenc}
 \\usepackage[T1]{fontenc}
 \\usepackage{fixltx2e}
 \\usepackage{graphicx}
 \\usepackage{longtable}
 \\usepackage{float}
 \\usepackage{wrapfig}
 \\usepackage{rotating}
 \\usepackage[normalem]{ulem}
 \\usepackage{amsmath}
 \\usepackage{textcomp}
 \\usepackage{marvosym}
 \\usepackage{wasysym}
 \\usepackage{amssymb}
 \\usepackage{hyperref}
 \\usepackage{mathpazo}
 \\usepackage{color}
 \\usepackage{enumerate}
 \\definecolor{bg}{rgb}{0.95,0.95,0.95}
 \\tolerance=1000
 [NO-DEFAULT-PACKAGES]
 [PACKAGES]
 [EXTRA]
 \\linespread{1.1}
 \\hypersetup{pdfborder=0 0 0}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")))


  (add-to-list 'org-latex-classes '("ebook"
                                    "\\documentclass[11pt, oneside]{memoir}
 \\setstocksize{9in}{6in}
 \\settrimmedsize{\\stockheight}{\\stockwidth}{*}
 \\setlrmarginsandblock{2cm}{2cm}{*} % Left and right margin
 \\setulmarginsandblock{2cm}{2cm}{*} % Upper and lower margin
 \\checkandfixthelayout
 % Much more laTeX code omitted
 "
                                    ("\\chapter{%s}" . "\\chapter*{%s}")
                                    ("\\section{%s}" . "\\section*{%s}")
                                    ("\\subsection{%s}" . "\\subsection*{%s}")))

  )


(use-package org-modern
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star '("●" "○" "◆" "◇" "▶" "▷"))
  (setq org-hide-emphasis-markers t)
  (setq org-pretty-entities t)
  (setq org-modern-block-name
	`(("src" . (,(nerd-icons-devicon "nf-dev-codeac" :face 'nerd-icons-blue-alt)
		    ,(nerd-icons-devicon "nf-dev-codeac" :face 'org-block-end-line)))
          ("example" . (,(nerd-icons-mdicon "nf-md-information_outline" :face 'nerd-icons-blue)
                        ,(nerd-icons-mdicon "nf-md-information_outline" :face 'org-block-end-line)))
          ("quote" . (,(nerd-icons-mdicon "nf-md-comment_quote_outline" :face 'nerd-icons-orange)
                      ,(nerd-icons-mdicon "nf-md-comment_quote_outline" :face 'org-block-end-line)))
          ("comment" . (,(nerd-icons-mdicon "nf-md-comment_text_outline" :face 'nerd-icons-orange)
                        ,(nerd-icons-mdicon "nf-md-comment_text_outline" :face 'org-block-end-line)))
          ("verse" . (,(nerd-icons-mdicon "nf-md-label_outline" :face 'nerd-icons-blue)
                      ,(nerd-icons-mdicon "nf-md-label_outline" :face 'org-block-end-line)))
          ("center" . (,(nerd-icons-mdicon "nf-md-format_align_center" :face 'nerd-icons-blue)
                       ,(nerd-icons-mdicon "nf-md-format_align_center" :face 'org-block-end-line)))
          ("export" . (,(nerd-icons-mdicon "nf-md-file_export_outline" :face 'nerd-icons-blue)
                       ,(nerd-icons-mdicon "nf-md-file_export_outline" :face 'org-block-end-line)))
          ("translate" . (,(nerd-icons-mdicon "nf-md-translate" :face 'nerd-icons-blue)
                          ,(nerd-icons-mdicon "nf-md-translate" :face 'org-block-end-line)))
          )))


(use-package org-super-agenda
  :config
  (org-super-agenda-mode)
  (setq spacemacs-theme-org-agenda-height nil
        org-agenda-time-grid '((daily today require-timed) (600 1200 1800) " ···· " "---------------------")
        ;; org-agenda-time-grid '((daily) () "" "")
        ;; org-agenda-current-time-string ""
        org-agenda-time-leading-zero t
        org-agenda-skip-scheduled-if-done t
        org-agenda-skip-deadline-if-done t
        org-agenda-include-deadlines t
        calendar-view-holidays-initially t
        org-agenda-include-diary t
        org-agenda-align-tags t
        org-agenda-tags-column 100
        org-agenda-window-setup 'current-window
        org-agenda-skip-scheduled-if-deadline-is-shown t
        org-agenda-skip-scheduled-if-done t

        ;; org-agenda-block-separator nil
        ;; org-agenda-compact-blocks t
        org-agenda-prefix-format '((agenda   . "  %i %-12c %s %-22t")
                                   (todo     . "  %i %-12c")
                                   (tags     . "  %i %-12c")
                                   (search   . "  %i %-12c"))

;; (setq org-agenda-deadline-leaders (quote ("!D!: " "D%2d: " "")))
;; (setq org-agenda-scheduled-leaders (quote ("" "S%3d: ")))
        org-agenda-start-with-log-mode t
        org-agenda-category-icon-alist `(("work" ,(list (all-the-icons-material "computer" :height 0.8)) nil nil :ascent center)
                                         ("diary" ,(list (all-the-icons-faicon "pencil" :height 0.9)) nil nil :ascent center))
        )
  (setq org-agenda-custom-commands
        '(("z" "Super zaen view"
           ((agenda "" ((org-agenda-span 'day)
                        (org-super-agenda-groups
                         '((:name "󰃶 Today"
                                  :time-grid t
                                  :date today
                                  :scheduled today
                                  :order 1)
                           ))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          '((:name " Next to do"
                                   :todo "NEXT"
                                   :order 2)
                            (:name " Important"
                                   :tag "Important"
                                   :priority "A"
                                   :order 4)
                            (:name " Due Today"
                                   :deadline today
                                   :order 1)
                            (:name " Due Soon"
                                   :deadline future
                                   :face (:foreground "#f1fa8c")
                                   :order 10)
                            (:name "󰜡 Overdue"
                                   :deadline past
                                   :and(:not (:todo "DONE") :scheduled past)
                                   :face (:foreground "#ff5555")
                                   :order 3)
                            (:discard (:anything t))
                            ))))))))
  )

(setq diary-file "~/org/diary")
(defun slin/close-empty-diary ()
  "Close diary buffer if it's empty."
  (let ((buf (get-buffer "diary")))
    (when (and buf (eq (buffer-size buf) 0))
      (kill-buffer buf))))

(add-hook 'org-agenda-finalize-hook #'slin/close-empty-diary)

(use-package cal-china-x
  :config
  (setq calendar-mark-holidays-flag t)
  (setq cal-china-x-important-holidays cal-china-x-chinese-holidays)
  (setq cal-china-x-general-holidays '((holiday-lunar 1 15 "元宵节")))
  (setq calendar-holidays
        (append cal-china-x-important-holidays
                cal-china-x-general-holidays)))


(use-package org-roam
  :after org
  :config
  (setq org-roam-directory (file-truename "~/org/docs"))
  (setq org-roam-db-location (file-truename (expand-file-name "org-roam.db" org-roam-directory))))

(use-package org-roam
  :ensure t
  :custom
  (org-roam-directory (file-truename "~/org/docs"))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ;; Dailies
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  ;; If you're using a vertical completion framework, you might want a more informative completion interface
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode))

(use-package org-roam-ui)

(use-package org-roam-bibtex)

(provide 'init-org)
