;;; init-org.el --- Load the full configuration -*- lexical-binding: t -*-
;;; Commentary:
;;;code:

(defun slin/org-open-at-point ()
  (interactive)
  (org-cycle))

(add-hook 'org-mode-hook
	(lambda ()
	    (evil-define-key 'normal 'global (kbd "RET") 'slin/org-open-at-point)))


(defun slin/kill-current-buffer ()
  (interactive)
  (kill-buffer (current-buffer)))

(defun slin/open-org-index ()
  (interactive)
  (find-file "~/org/index.org"))

(evil-set-leader nil (kbd "SPC"))
(evil-define-key 'normal 'global (kbd "<leader>fr") 'recentf-open)
(evil-define-key 'normal 'global (kbd "<leader>ff") 'find-file)
(evil-define-key 'normal 'global (kbd "<leader>fo") 'slin/open-org-index)
(evil-define-key 'normal 'global (kbd "<leader>bb") 'switch-to-buffer)
(evil-define-key 'normal 'global (kbd "<leader>bx") 'slin/kill-current-buffer)

(provide 'init-keymap)
;;; init-keymap.el ends here
