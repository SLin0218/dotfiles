
(with-eval-after-load 'org
  (set-face-attribute 'org-level-1 nil :weight 'bold :height 1.25 :foreground "#ff6b6b")
  (let ((colors '("#ff6b6b" "#4ecdc4" "#a0c4ff" "#9bf6ff" "#ffd6a5" "#ffadad")))
    (dolist (i (number-sequence 2 6))
      (set-face-attribute (intern (format "org-level-%d" i)) nil
			  :weight 'bold
			  :height (- 1.15 (* 0.03 (- i 2)))
			  :foreground (nth (1- i) colors))))

  ;开启标题缩进
  (setq org-startup-indented t)

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

  ;行间距
  (setq line-spacing 0.25)

  ;quote高亮
  (setq org-indent-indentation-per-level 2)
  (setq org-fontify-quote-and-verse-blocks t)
  (setq org-indent-mode-respect-standard-blocks t))


(use-package org-modern
  :ensure t
  :hook (org-mode . org-modern-mode)
  :config
  (setq org-modern-star '("●" "○" "◆" "◇" "▶" "▷"))
  (setq org-hide-emphasis-markers t)
  (setq org-pretty-entities t)
  (setq org-agenda-tags-column 0)
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
(provide 'init-org)
