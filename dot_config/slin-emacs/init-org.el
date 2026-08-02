;;; init-org.el --- Org-mode, GTD, and knowledge base configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Org-mode 核心设置、Org-agenda、Org-roam 双链笔记以及 LaTeX/PDF/Pandoc 导出配置。
;;

;;; Code:

(setq org-agenda-files (list (expand-file-name "~/org/agenda/")))
;; 禁用默认加载的第三方链接子模块，提升启动与首次加载速度
(setq org-modules nil)

(with-eval-after-load 'org
  ;; 1. 标题层级保留彩虹前景色
  (set-face-attribute 'org-level-1 nil :weight 'bold :height 1.25 :foreground (catppuccin-color 'red))
  (let ((colors (list (catppuccin-color 'peach)
                      (catppuccin-color 'yellow)
                      (catppuccin-color 'green)
                      (catppuccin-color 'blue)
                      (catppuccin-color 'mauve))))
    (dolist (i (number-sequence 2 6))
      (set-face-attribute (intern (format "org-level-%d" i)) nil
                          :weight 'bold
                          :height (- 1.15 (* 0.03 (- i 2)))
                          :foreground (nth (- i 2) colors))))

  (setq org-startup-indented t)         ; 开启标题缩进
  (setq org-src-tab-acts-natively t)    ; code按语言缩进
  (setq org-src-preserve-indentation nil)
  (setq org-blank-before-new-entry
        '((heading . auto) (plain-list-item . auto)))
  (setq org-src-fontify-natively t)     ; 代码块高亮
  (setq org-ellipsis "󱞣")

  (setq org-babel-default-header-args   ; block执行代码通用配置
        '((:session . "none")
          (:exports . "code")
          (:results . "replace")))

  (setq line-spacing 0.25)
  (setq org-use-property-inheritance t)
  (setq org-enforce-todo-dependencies t) ; 子任务阻塞父任务
  (setq org-agenda-todo-list-sublevels t)

  (setq org-indent-indentation-per-level 2)
  (setq org-fontify-quote-and-verse-blocks t)
  (setq org-indent-mode-respect-standard-blocks t)
  (setq org-todo-keywords
        '((sequence "TODO(t)" "NEXT(n)" "ACTIVITY(a)" "WAITING(w@/!)" "|" "DONE(d!)" "CANCELED(c@)")))
  (setq org-log-done 'time)
  (setq org-log-into-drawer t)          ; 日志放入 LOGBOOK drawer

  (setq org-modern-todo-faces
        `(("TODO"     . (:foreground ,(catppuccin-color 'mauve)    :background ,(catppuccin-color 'surface0) :height 1.2 :box (:line-width (0 . 1) :color ,(catppuccin-color 'base) :style nil)))
          ("NEXT"     . (:foreground ,(catppuccin-color 'peach)    :background ,(catppuccin-color 'surface0) :height 1.2 :box (:line-width (0 . 1) :color ,(catppuccin-color 'base) :style nil) :weight bold))
          ("ACTIVITY" . (:foreground ,(catppuccin-color 'red)      :background ,(catppuccin-color 'surface0) :height 1.2 :box (:line-width (0 . 1) :color ,(catppuccin-color 'base) :style nil) :weight bold))
          ("WAITING"  . (:foreground ,(catppuccin-color 'sapphire) :background ,(catppuccin-color 'surface0) :height 1.2 :box (:line-width (0 . 1) :color ,(catppuccin-color 'base) :style nil)))
          ("DONE"     . (:foreground ,(catppuccin-color 'green)    :background ,(catppuccin-color 'surface0) :height 1.2 :box (:line-width (0 . 1) :color ,(catppuccin-color 'base) :style nil)))
          ("CANCELED" . (:foreground ,(catppuccin-color 'surface2) :background ,(catppuccin-color 'surface0) :height 1.2 :box (:line-width (0 . 1) :color ,(catppuccin-color 'base) :style nil) :strike-through t ))))

  ;; ----------------- LaTeX / PDF 导出配置 -----------------
  (setq org-latex-pdf-process
        '("xelatex -interaction nonstopmode -shell-escape -output-directory %o %f"
          "xelatex -interaction nonstopmode -shell-escape -output-directory %o %f"
          "xelatex -interaction nonstopmode -shell-escape -output-directory %o %f"))

  (setq org-latex-src-block-backend 'listings)

  (unless (boundp 'org-latex-classes)
    (setq org-latex-classes nil))

  (setq org-latex-default-class "cn-article")

  ;; 1. 中文文章模板 (ctexart)
  (add-to-list 'org-latex-classes
               '("cn-article"
                 "\\documentclass[11pt,a4paper,fontset=none]{ctexart}
  \\usepackage[utf8]{inputenc}
  \\usepackage[T1]{fontenc}
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
  \\usepackage[shortlabels]{enumitem}
  \\setlist{nosep}
  \\usepackage{color}
  \\usepackage{xcolor}
  \\usepackage{geometry}
  \\geometry{a4paper,left=2.5cm,right=2.5cm,top=2.5cm,bottom=2.5cm}
  \\usepackage{listings}
  \\definecolor{codebg}{RGB}{245,246,248}
  \\definecolor{codeborder}{RGB}{220,224,232}
  \\definecolor{codekeyword}{RGB}{30,102,245}
  \\definecolor{codecomment}{RGB}{140,143,161}
  \\definecolor{codestring}{RGB}{64,160,43}
  \\definecolor{codenumber}{RGB}{156,160,176}
  \\lstdefinestyle{mystyle}{
      backgroundcolor=\\color{codebg},
      commentstyle=\\color{codecomment}\\itshape,
      keywordstyle=\\color{codekeyword}\\bfseries,
      numberstyle=\\tiny\\color{codenumber},
      stringstyle=\\color{codestring},
      basicstyle=\\ttfamily\\small\\color{black},
      breakatwhitespace=false,
      breaklines=true,
      captionpos=b,
      keepspaces=true,
      numbers=left,
      numbersep=8pt,
      showspaces=false,
      showstringspaces=false,
      showtabs=false,
      tabsize=4,
      frame=single,
      rulecolor=\\color{codeborder},
      frameround=tttt,
      framesep=6pt,
      xleftmargin=15pt,
      xrightmargin=5pt,
      extendedchars=false
  }
  \\lstset{style=mystyle}
  \\usepackage{xeCJK}
  \\setCJKmainfont{Songti SC}
  \\setCJKsansfont{Heiti SC}
  \\setCJKmonofont{Heiti SC}
  \\ctexset{section={format=\\Large\\bfseries\\raggedright}}
  \\usepackage{fontspec}
  \\setmonofont{JetBrainsMono Nerd Font}
  \\usepackage{hyperref}
  \\hypersetup{
      colorlinks=true,
      linkcolor=blue,
      filecolor=magenta,
      urlcolor=cyan,
      pdfborder=0 0 0
  }
  \\usepackage{fancyhdr}
  \\pagestyle{fancy}
  \\fancyhf{}
  \\fancyfoot[C]{\\thepage}
  \\renewcommand{\\headrulewidth}{0pt}
  \\renewcommand{\\footrulewidth}{0pt}
  \\tolerance=1000
  [NO-DEFAULT-PACKAGES]
  [PACKAGES]
  [EXTRA]"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

  ;; 保留 ethz 模板
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
  \\usepackage[shortlabels]{enumitem}
  \\setlist{nosep}
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

  ;; 保留 article 模板
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
  \\usepackage[shortlabels]{enumitem}
  \\setlist{nosep}
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

  ;; 保留 ebook 模板
  (add-to-list 'org-latex-classes '("ebook"
                                    "\\documentclass[11pt, oneside]{memoir}
  \\setstocksize{9in}{6in}
  \\settrimmedsize{\\stockheight}{\\stockwidth}{*}
  \\setlrmarginsandblock{2cm}{2cm}{*}
  \\setulmarginsandblock{2cm}{2cm}{*}
  \\checkandfixthelayout
  "
                                    ("\\chapter{%s}" . "\\chapter*{%s}")
                                    ("\\section{%s}" . "\\section*{%s}")
                                    ("\\subsection{%s}" . "\\subsection*{%s}"))))

;; Org Modern UI 美化
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
                          ,(nerd-icons-mdicon "nf-md-translate" :face 'org-block-end-line))))))

;; Org Super Agenda
(use-package org-super-agenda
  :commands org-super-agenda-mode
  :hook (org-agenda-mode . org-super-agenda-mode)
  :config
  (setq spacemacs-theme-org-agenda-height nil
        org-agenda-time-grid '((daily today require-timed) (600 1200 1800) " ···· " "---------------------")
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
        org-agenda-prefix-format '((agenda   . "  %i %-12c %s %-22t")
                                   (todo     . "  %i %-12c")
                                   (tags     . "  %i %-12c")
                                   (search   . "  %i %-12c"))
        org-agenda-start-with-log-mode t
        org-agenda-category-icon-alist `(("work" ,(list (all-the-icons-material "computer" :height 0.8)) nil nil :ascent center)
                                         ("diary" ,(list (all-the-icons-faicon "pencil" :height 0.9)) nil nil :ascent center)))
  (setq org-agenda-custom-commands
        '(("z" "Super zaen view"
           ((agenda "" ((org-agenda-span 'day)
                        (org-super-agenda-groups
                         '((:name "󰃶 Today"
                                  :time-grid t
                                  :date today
                                  :scheduled today
                                  :order 1)))))
            (alltodo "" ((org-agenda-overriding-header "")
                         (org-super-agenda-groups
                          `((:name " Next to do"
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
                                   :face (:foreground (catppuccin-color 'yellow))
                                   :order 10)
                            (:name "󰜡 Overdue"
                                   :deadline past
                                   :and(:not (:todo "DONE") :scheduled past)
                                   :face (:foreground (catppuccin-color 'red))
                                   :order 3)
                            (:discard (:anything t)))))))))))

(setq diary-file "~/org/diary")
(defun slin/close-empty-diary ()
  "Close diary buffer if it's empty."
  (let ((buf (get-buffer "diary")))
    (when (and buf (eq (buffer-size buf) 0))
      (kill-buffer buf))))

(add-hook 'org-agenda-finalize-hook #'slin/close-empty-diary)

;; 农历与节日
(use-package cal-china-x
  :after calendar
  :config
  (setq calendar-mark-holidays-flag t)
  (setq cal-china-x-important-holidays cal-china-x-chinese-holidays)
  (setq cal-china-x-general-holidays '((holiday-lunar 1 15 "元宵节")))
  (setq calendar-holidays
        (append cal-china-x-important-holidays
                cal-china-x-general-holidays)))

;; Org-roam 双链笔记
(use-package org-roam
  :custom
  (org-roam-directory (file-truename "~/org/docs"))
  (org-roam-db-location (file-truename (expand-file-name "org-roam.db" "~/org/docs")))
  :bind (("C-c n l" . org-roam-buffer-toggle)
         ("C-c n f" . org-roam-node-find)
         ("C-c n g" . org-roam-graph)
         ("C-c n i" . org-roam-node-insert)
         ("C-c n c" . org-roam-capture)
         ("C-c n j" . org-roam-dailies-capture-today))
  :config
  (setq org-roam-node-display-template (concat "${title:*} " (propertize "${tags:10}" 'face 'org-tag)))
  (org-roam-db-autosync-mode))

(use-package org-roam-ui
  :after org-roam)

(use-package org-roam-bibtex
  :after org-roam
  :config
  (org-roam-bibtex-mode +1))

;; Ox-pandoc 格式转换
(when (executable-find "pandoc")
  (use-package ox-pandoc
    :after org
    :defer t
    :config
    (setq org-pandoc-options-for-docx '((standalone . t)))))

(provide 'init-org)
;;; init-org.el ends here
