;;; init-org.el --- Org-mode, GTD, and knowledge base configurations  -*- lexical-binding: t; -*-

;;; Commentary:
;;
;; Org-mode 核心设置、Org-agenda、Org-roam 双链笔记以及 LaTeX/PDF/Pandoc 导出配置。
;;

;;; Code:

(setq org-agenda-files (list (expand-file-name "~/org/agenda/")))
;; 禁用默认加载的第三方链接子模块，提升启动与首次加载速度
(setq org-modules nil)

;; ----------------- Org 智能链接与图标辅助函数 -----------------

;; 切换当前行/光标处图片的内联预览
(defun my/org-toggle-inline-image-at-point ()
  "Toggle inline image display for the image link on the current line."
  (let ((beg (line-beginning-position))
        (end (line-end-position)))
    (if (or (get-char-property (point) 'org-image-overlay)
            (get-char-property beg 'org-image-overlay))
        (org-remove-inline-images beg end)
      (org-display-inline-images t t beg end))))

;; 为不同类型的 Org 链接自动加带有颜色的图标前缀 (空格无下划线)
(defun my/org-link-icon-matcher (limit)
  "Font-lock matcher for Org links to append colored Nerd Icon prefix."
  (while (re-search-forward org-link-any-re limit t)
    (let* ((start (match-beginning 0))
           (context (save-excursion (goto-char start) (org-element-context))))
      (when (eq (org-element-type context) 'link)
        (remove-overlays start (1+ start) 'my-org-link-icon t)
        (let* ((link-type (org-element-property :type context))
               (path (or (org-element-property :path context) ""))
               (raw-link (or (org-element-property :raw-link context) ""))
               (space (propertize " " 'face '(:underline nil :inherit nil)))
               (icon (cond
                      ;; 🌐 网页 URL -> 蓝色 Web 图标
                      ((member link-type '("http" "https" "ftp" "mailto"))
                       (nerd-icons-mdicon "nf-md-web" :face 'nerd-icons-blue))
                      ;; 🖼️ 图片链接 -> 紫色 Image 图标
                      ((or (and (stringp path) (not (string-empty-p path)) (image-type-from-file-name path))
                           (string-match-p "\\.\\(png\\|jpg\\|jpeg\\|gif\\|svg\\|webp\\|bmp\\)$" (downcase raw-link)))
                       (nerd-icons-mdicon "nf-md-image_outline" :face 'nerd-icons-purple))
                      ;; 📄 Org 笔记 / 双链 -> 绿色 Org-mode 专属图标
                      ((or (and (equal link-type "file") (string-match-p "\\.org$" (downcase path)))
                           (member link-type '("id" "denote" "custom-id")))
                       (nerd-icons-sucicon "nf-custom-orgmode" :face 'nerd-icons-green))
                      ;; 🔗 其他文件/常规链接 -> 橙色 Link 图标
                      (t
                       (nerd-icons-mdicon "nf-md-link_variant" :face 'nerd-icons-orange)))))
          (when icon
            (let ((ov (make-overlay start start)))
              (overlay-put ov 'before-string (concat icon space))
              (overlay-put ov 'my-org-link-icon t))))))))

;; 智能回车 (RET)：按链接类型分别处理 (跳转 Org / 图片预览 / 浏览器打开 URL)
(defun my/org-dwim-at-point ()
  "Smart RET in Org-mode:
- On an Org file link: jump to the corresponding Org file in current window.
- On an image link: toggle inline image preview.
- On a URL link: open in web browser.
- Otherwise: execute default RET behavior."
  (interactive)
  (let* ((context (org-element-context))
         (type (org-element-type context))
         (link (cond
                ((eq type 'link) context)
                (t (org-element-lineage context '(link) t)))))
    (if link
        (let* ((link-type (org-element-property :type link))
               (path (or (org-element-property :path link) ""))
               (raw-link (or (org-element-property :raw-link link) ""))
               (clean-path (car (split-string path "::"))))
          (cond
           ;; 1. 图片链接 -> 开启/关闭内联预览
           ((or (and (stringp clean-path)
                     (not (string-empty-p clean-path))
                     (fboundp 'image-type-from-file-name)
                     (image-type-from-file-name clean-path))
                (string-match-p "\\.\\(png\\|jpg\\|jpeg\\|gif\\|svg\\|webp\\|bmp\\)$" (downcase raw-link)))
            (my/org-toggle-inline-image-at-point))

           ;; 2. URL 链接 -> 使用默认浏览器打开
           ((or (member link-type '("http" "https" "ftp" "mailto"))
                (string-match-p "^https?://" raw-link))
            (browse-url raw-link))

           ;; 3. Org 文件链接 / 双链 -> 跳转至 Org 文件 (当前窗口打开)
           ((or (and (equal link-type "file")
                     (string-match-p "\\.org$" (downcase clean-path)))
                (member link-type '("id" "denote" "custom-id")))
            (org-open-at-point))

           ;; 4. 其他普通文件/链接 -> 默认调用 org-open-at-point
           (t (org-open-at-point))))
      ;; 非链接位置 -> 命令模式 (Normal State) 下不换行仅向下移动光标；编辑模式下正常换行
      (cond
       ((and (bound-and-true-p evil-state)
             (eq evil-state 'normal))
        (if (fboundp 'evil-next-line)
            (evil-next-line)
          (forward-line 1)))
       (t
        (call-interactively (or (command-remapping 'org-return)
                                #'org-return)))))))

;; 在顶层挂载 org-mode-hook 钩子 (确保在打开 Org 文件前已被注册)
(add-hook 'org-mode-hook
          (lambda ()
            (font-lock-add-keywords nil '((my/org-link-icon-matcher)) 'append)
            (local-set-key (kbd "RET") #'my/org-dwim-at-point)
            (local-set-key (kbd "<return>") #'my/org-dwim-at-point)
            (when (bound-and-true-p evil-mode)
              (evil-local-set-key 'normal (kbd "RET") #'my/org-dwim-at-point)
              (evil-local-set-key 'normal (kbd "<return>") #'my/org-dwim-at-point)
              ;; 在 Evil Normal 模式下将 TAB 绑定至 org-cycle (折叠/展开标题)
              (evil-local-set-key 'normal (kbd "<tab>") #'org-cycle)
              (evil-local-set-key 'normal (kbd "TAB") #'org-cycle)
              (evil-local-set-key 'normal (kbd "<backtab>") #'org-shifttab)
              (evil-local-set-key 'normal (kbd "S-TAB") #'org-shifttab))))

;; ----------------- Org 延时加载配置项 -----------------
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

  ;; 让 org-link 继承所在的文本前景色 (如标题的彩虹色)，断开与基础 link 蓝色前景色继承
  (set-face-attribute 'org-link nil :inherit nil :foreground 'unspecified :underline t)

  (setq org-startup-indented t)         ; 开启标题缩进
  (setq org-hide-leading-stars t)       ; 隐藏标题星号
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

  ;; 设置 Org 打开文件链接时在当前窗口打开 (不分屏)
  (setq org-link-frame-setup
        '((vm . vm-visit-folder)
          (vm-imap . vm-visit-imap-folder)
          (gnus . org-gnus-no-new-news)
          (file . find-file)
          (wl . wl)))

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
  (setq org-modern-star 'replace)
  ;; (setq org-modern-star '("●" "○" "◆" "◇" "▶" "▷"))
  (setq org-modern-replace-stars '("" "" "" "" ""))
  (setq org-modern-hide-stars t)
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
