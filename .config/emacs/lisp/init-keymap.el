;;; init-org.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Commentary:
;;;code:

; vim 键位
(use-package evil
  :ensure t
  :init
  (setq evil-want-C-u-scroll t)               ; C-u 向上翻页
  (setq evil-complete-all-buffers nil)
  (evil-mode 1))

; 彩虹括号
(use-package rainbow-delimiters
 :ensure t
 :hook (prog-mode . rainbow-delimiters-mode))

(setq org-link-frame-setup '((file . find-file)))

(defun slin/org-open-at-point ()
  (interactive)
  (let ((context (org-element-context)))
    (cond
     ;; 如果光标在链接上
     ((string= (org-element-type context) "link")
      (if (string-match ".*\\.\\(jpg\\|jpeg\\|png\\|gif\\|bmp\\|tiff\\|svg\\)$" (org-element-property :path context))
	  (print (org-element-property :path context))
	  (org-open-at-point)))
     ;; 如果光标在列表项上
     ((string= (org-element-type context) "headline") (org-cycle))
     ((string= (org-element-type context) "example-block") (org-cycle))
     ;; 其他情况，执行默认的回车行为
     (t (nil)))))

(add-hook 'org-mode-hook (lambda () (evil-define-key 'normal 'global (kbd "RET") 'slin/org-open-at-point)))

(defun slin/kill-current-buffer ()
  (interactive)
  (kill-buffer (current-buffer)))

(defun slin/open-org-index ()
  (interactive)
  (find-file "~/org/index.org"))

(evil-set-leader nil (kbd "SPC"))
(evil-define-key 'normal 'global (kbd "<leader>fo") 'recentf-open)
(evil-define-key 'normal 'global (kbd "<leader>ff") 'find-file)
(evil-define-key 'normal 'global (kbd "<leader>fi") 'slin/open-org-index)
(evil-define-key 'normal 'global (kbd "<leader>bb") 'switch-to-buffer)
(evil-define-key 'normal 'global (kbd "<leader>bx") 'slin/kill-current-buffer)

(define-key evil-normal-state-map (kbd "C-n") 'next-line)
(define-key evil-normal-state-map (kbd "C-p") 'previous-line)
(define-key evil-normal-state-map (kbd "C-f") 'forward-char)
(define-key evil-normal-state-map (kbd "C-b") 'backward-char)

(provide 'init-keymap)
;;; init-keymap.el ends here
