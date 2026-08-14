;;; init-v2ex.el --- Asynchronous V2EX Client & Homepage Dashboard for Emacs  -*- lexical-binding: t; -*-

;;; Commentary:
;; A streamlined, non-blocking V2EX client for Emacs focused on:
;; - Single-Buffer Homepage Dashboard (Today's Hot Topics & Aggregated Tech RSS Feed)
;; - Topic Details & Paginated Replies View
;; - Async HTTP requests (zero UI freezing)
;; - Evil keybindings integration

;;; Code:

(require 'json)
(require 'url)
(require 'shr)
(require 'subr-x)

(defgroup v2ex nil
  "V2EX client for Emacs."
  :group 'applications
  :prefix "v2ex-")

(defcustom v2ex-token nil
  "V2EX Personal Access Token (Bearer Token).
Can be obtained from https://www.v2ex.com/settings/tokens or https://edge.v2ex.com/help/personal-access-token"
  :type '(choice (const :tag "Not set" nil)
                 (string :tag "Token")))

(defcustom v2ex-api-base-url "https://www.v2ex.com/api/v2/"
  "Base URL for V2EX API v2 endpoints."
  :type 'string)

(defcustom v2ex-user-agent "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36"
  "User-Agent header string simulating a modern browser for HTTP requests."
  :type 'string)

;; Buffer & State variables
(defvar-local v2ex--current-page 1)
(defvar-local v2ex--current-topic-id nil)
(defvar-local v2ex--current-topic-data nil)

;; Faces
(defface v2ex-title-face
  '((t :height 1.15 :weight bold :inherit font-lock-keyword-face))
  "Face for topic titles."
  :group 'v2ex)

(defface v2ex-meta-face
  '((t :height 0.9 :inherit font-lock-comment-face))
  "Face for metadata (author, node, date)."
  :group 'v2ex)

(defface v2ex-header-face
  '((t :height 1.2 :weight bold :inherit header-line))
  "Face for buffer header lines."
  :group 'v2ex)

(defface v2ex-reply-header-face
  '((t :weight bold :inherit font-lock-function-name-face))
  "Face for reply headers."
  :group 'v2ex)

(defface v2ex-node-badge-face
  '((t :weight bold :foreground "#367bf0"))
  "Face for node badges."
  :group 'v2ex)

(defface v2ex-reply-count-face
  '((t :weight bold :foreground "#888888"))
  "Face for reply count badges."
  :group 'v2ex)

(defface v2ex-separator-face
  '((t :foreground "#555555" :inherit font-lock-comment-face))
  "Face for separator lines."
  :group 'v2ex)

;;; Helpers

(defun v2ex--separator-line (&optional char width)
  "Return a separator line string fitting the window body width using CHAR (default ?─)."
  (let* ((win (or (get-buffer-window (current-buffer) t) (selected-window)))
         (win-w (if (window-live-p win) (window-body-width win) 80))
         (len (max 10 (or width (- win-w 4)))))
    (propertize (make-string len (or char ?─)) 'face 'v2ex-separator-face)))

(defun v2ex--get-field (key alist)
  "Get value for KEY from ALIST, checking both symbol and string keys."
  (if (not (listp alist))
      nil
    (let ((sym-key (if (symbolp key) key (intern key)))
          (str-key (if (stringp key) key (symbol-name key))))
      (or (cdr (assq sym-key alist))
          (cdr (assoc str-key alist))))))

(defun v2ex--unwrap-result-data (raw)
  "Extract data payload from API response JSON structure RAW."
  (if (and (listp raw) (v2ex--get-field 'result raw))
      (let ((success (v2ex--get-field 'success raw)))
        (if (eq success :json-false)
            (error "V2EX API Error: %s" (v2ex--get-field 'message raw))
          (v2ex--get-field 'result raw)))
    raw))

(defun v2ex--parse-atom-feed (str)
  "Parse V2EX Atom RSS feed XML string STR into list of topic alists."
  (let ((entries nil))
    (with-temp-buffer
      (insert str)
      (goto-char (point-min))
      (while (re-search-forward "<entry>" nil t)
        (let ((start (match-beginning 0)))
          (when (re-search-forward "</entry>" nil t)
            (let* ((entry-str (buffer-substring-no-properties start (match-end 0)))
                   (title (when (string-match "<title>\\([^\000]*?\\)</title>" entry-str)
                            (string-trim (match-string 1 entry-str))))
                   (link-href (when (string-match "<link[^>]*href=\"\\([^\"]+\\)\"" entry-str)
                                (match-string 1 entry-str)))
                   (author (when (string-match "<name>\\([^<]+\\)</name>" entry-str)
                             (match-string 1 entry-str)))
                   (published (when (string-match "<published>\\([^<]+\\)</published>" entry-str)
                                (match-string 1 entry-str)))
                   (topic-id (when (and link-href (string-match "/t/\\([0-9]+\\)" link-href))
                               (string-to-number (match-string 1 link-href))))
                   (replies (if (and link-href (string-match "#reply\\([0-9]+\\)" link-href))
                                (string-to-number (match-string 1 link-href))
                              0)))
              (when (and topic-id title)
                (push `((id . ,topic-id)
                        (title . ,title)
                        (member . ((username . ,(or author "anonymous"))))
                        (replies . ,replies)
                        (created . ,published))
                      entries)))))))
    (nreverse entries)))

(defun v2ex--format-timestamp (time-val)
  "Format unix timestamp TIME-VAL to readable date string."
  (cond
   ((numberp time-val)
    (format-time-string "%Y-%m-%d %H:%M" (seconds-to-time time-val)))
   ((and (stringp time-val) (string-match-p "^[0-9]+$" time-val))
    (format-time-string "%Y-%m-%d %H:%M" (seconds-to-time (string-to-number time-val))))
   ((stringp time-val)
    time-val)
   (t "N/A")))

;;; Interactive Token Command

(defun v2ex-set-token (token)
  "Set `v2ex-token' interactively and save it."
  (interactive "sEnter V2EX Personal Access Token: ")
  (let ((clean-token (string-trim token)))
    (if (string-empty-p clean-token)
        (message "V2EX Token cleared.")
      (setq v2ex-token clean-token)
      (when (bound-and-true-p custom-file)
        (customize-save-variable 'v2ex-token v2ex-token))
      (message "V2EX Personal Access Token updated successfully."))))

;;; ----------------------------------------------------------------------------
;;; Asynchronous HTTP Request Engine
;;; ----------------------------------------------------------------------------

(defun v2ex--request-async (url callback &rest args)
  "Perform asynchronous HTTP request to URL using curl process or `url-retrieve`.
Calls (funcall CALLBACK status payload) when completed."
  (let* ((method (or (plist-get args :method) "GET"))
         (params (plist-get args :params))
         (data (plist-get args :data))
         (raw (plist-get args :raw))
         (full-url (if (string-prefix-p "http" url)
                       url
                     (concat (file-name-as-directory v2ex-api-base-url)
                             (string-remove-prefix "/" url)))))
    (when params
      (let ((query-str (mapconcat (lambda (p)
                                    (format "%s=%s"
                                            (url-hexify-string (format "%s" (car p)))
                                            (url-hexify-string (format "%s" (cdr p)))))
                                  params "&")))
        (setq full-url (concat full-url (if (string-match-p "\\?" full-url) "&" "?") query-str))))
    (if (executable-find "curl")
        (v2ex--request-curl-async full-url method data raw callback)
      (v2ex--request-url-async full-url method data raw callback))))

(defun v2ex--request-curl-async (url method data raw callback)
  "Execute asynchronous curl process to URL, calling CALLBACK when done."
  (let* ((out-buf (generate-new-buffer " *v2ex-curl-async-out*"))
         (err-file (make-temp-file "v2ex-curl-async-err"))
         (cmd-args `("-s" "-L" "--connect-timeout" "15" "-X" ,method
                     "-H" ,(concat "User-Agent: " v2ex-user-agent)
                     "-H" "Accept-Language: zh-CN,zh;q=0.9,en;q=0.8,en-US;q=0.7"
                     "-H" "Sec-Ch-Ua: \"Chromium\";v=\"127\", \"Not)A;Brand\";v=\"99\""
                     "-H" "Sec-Ch-Ua-Mobile: ?0"
                     "-H" "Sec-Ch-Ua-Platform: \"macOS\""
                     "-H" "Sec-Fetch-Dest: document"
                     "-H" "Sec-Fetch-Mode: navigate"
                     "-H" "Sec-Fetch-Site: same-origin"
                     "-H" "Upgrade-Insecure-Requests: 1")))
    (if raw
        (setq cmd-args (append cmd-args '("-H" "Accept: application/xml,application/atom+xml,text/xml,*/*;q=0.9")))
      (setq cmd-args (append cmd-args '("-H" "Accept: application/json, text/plain, */*"))))
    (when (and v2ex-token (not (string-empty-p v2ex-token)))
      (setq cmd-args (append cmd-args `("-H" ,(concat "Authorization: Bearer " v2ex-token)))))
    (when data
      (setq cmd-args (append cmd-args `("-H" "Content-Type: application/json"
                                        "-d" ,(json-serialize data)))))
    (setq cmd-args (append cmd-args (list url)))

    (make-process
     :name "v2ex-curl-async"
     :buffer out-buf
     :command (cons "curl" cmd-args)
     :sentinel
     (lambda (proc _event)
       (when (memq (process-status proc) '(exit signal))
         (let ((exit-code (process-exit-status proc)))
           (if (= exit-code 0)
               (let ((payload (with-current-buffer out-buf (buffer-string))))
                 (if raw
                     (funcall callback t payload)
                   (condition-case parse-err
                       (let ((json-data (with-temp-buffer
                                          (insert payload)
                                          (goto-char (point-min))
                                          (json-parse-buffer :object-type 'alist :array-type 'list))))
                         (funcall callback t (v2ex--unwrap-result-data json-data)))
                     (error (funcall callback nil (format "JSON Parse Error: %s" parse-err))))))
             (let ((err-msg (if (file-exists-p err-file)
                                (with-temp-buffer (insert-file-contents err-file) (buffer-string))
                              "Curl process failed")))
               (funcall callback nil err-msg))))
         (when (buffer-live-p out-buf) (kill-buffer out-buf))
         (when (file-exists-p err-file) (delete-file err-file)))))))

(defun v2ex--request-url-async (url method data raw callback)
  "Execute asynchronous HTTP request using `url-retrieve'."
  (let* ((url-request-method method)
         (url-request-extra-headers
          (append
           `(("User-Agent" . ,v2ex-user-agent)
             ("Accept-Language" . "zh-CN,zh;q=0.9,en;q=0.8,en-US;q=0.7")
             ("Sec-Ch-Ua" . "\"Chromium\";v=\"127\", \"Not)A;Brand\";v=\"99\"")
             ("Sec-Ch-Ua-Mobile" . "?0")
             ("Sec-Ch-Ua-Platform" . "\"macOS\"")
             ("Upgrade-Insecure-Requests" . "1"))
           (if raw
               '(("Accept" . "application/xml,application/atom+xml,text/xml,*/*;q=0.9"))
             '(("Accept" . "application/json, text/plain, */*")))
           (when (and v2ex-token (not (string-empty-p v2ex-token)))
             `(("Authorization" . ,(concat "Bearer " v2ex-token))))
           (when data
             '(("Content-Type" . "application/json")))))
         (url-request-data (when data (encode-coding-string (json-serialize data) 'utf-8))))
    (url-retrieve
     url
     (lambda (status)
       (if (plist-get status :error)
           (funcall callback nil (format "HTTP Error: %s" (plist-get status :error)))
         (goto-char (point-min))
         (if (re-search-forward "^\r?\n" nil t)
             (let ((payload (buffer-substring (point) (point-max))))
               (if raw
                   (funcall callback t payload)
                 (condition-case parse-err
                     (let ((json-data (with-temp-buffer
                                        (insert payload)
                                        (goto-char (point-min))
                                        (json-parse-buffer :object-type 'alist :array-type 'list))))
                       (funcall callback t (v2ex--unwrap-result-data json-data)))
                   (error (funcall callback nil (format "JSON Parse Error: %s" parse-err))))))
           (funcall callback nil "Invalid HTTP Response")))))))

;;; ----------------------------------------------------------------------------
;;; Asynchronous Single-Buffer V2EX Homepage Dashboard
;;; ----------------------------------------------------------------------------

(defvar v2ex-homepage-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'v2ex-homepage-open-topic)
    (define-key map (kbd "o") #'v2ex-homepage-open-topic)
    (define-key map (kbd "r") #'v2ex-homepage-refresh)
    (define-key map (kbd "q") #'quit-window)
    (define-key map [mouse-2] #'v2ex-homepage-open-topic)
    map)
  "Keymap for `v2ex-homepage-mode'.")

(define-derived-mode v2ex-homepage-mode special-mode "V2EX-Homepage"
  "Major mode for Single-Buffer V2EX Homepage."
  (setq-local truncate-lines t)
  (use-local-map v2ex-homepage-mode-map))

;;;###autoload
(defun v2ex ()
  "Launch V2EX Homepage Dashboard (Single Buffer Layout)."
  (interactive)
  (v2ex-homepage))

;;;###autoload
(defun v2ex-homepage ()
  "Launch V2EX Homepage Dashboard asynchronously."
  (interactive)
  (let ((buf (get-buffer-create "*V2EX Homepage*")))
    (switch-to-buffer buf)
    (v2ex-homepage-mode)
    (v2ex-homepage-render)))

(defun v2ex-homepage-render ()
  "Render single-buffer V2EX homepage asynchronously."
  (interactive)
  (let ((buf (get-buffer-create "*V2EX Homepage*")))
    (with-current-buffer buf
      (v2ex-homepage-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (let ((sep-line (v2ex--separator-line ?─)))
          (insert (propertize " 󰈸 今日热议主题\n" 'face 'v2ex-header-face))
          (insert sep-line "\n")
          (insert "  󰔟 Loading hot topics...\n")
          (insert (v2ex--separator-line ?═) "\n")
          (insert (propertize " 󰌢 技术聚合 Feed (tech.xml)\n" 'face 'v2ex-header-face))
          (insert sep-line "\n")
          (insert "  󰔟 Loading tech feed...\n")))
      (goto-char (point-min)))

    ;; Fetch Hot Topics Async
    (v2ex--request-async
     "https://www.v2ex.com/api/topics/hot.json"
     (lambda (ok data)
       (when (buffer-live-p buf)
         (v2ex--render-homepage-hot-topics buf ok data))))

    ;; Fetch Tech RSS Feed Async
    (v2ex--request-async
     "https://www.v2ex.com/feed/tab/tech.xml"
     (lambda (ok data)
       (when (buffer-live-p buf)
         (let ((topics (when ok (v2ex--parse-atom-feed data))))
           (v2ex--render-homepage-rss-feed buf ok (or topics data)))))
     :raw t)))

(defun v2ex--render-homepage-hot-topics (buf ok data)
  "Update hot topics section in BUF."
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (if (re-search-forward "  󰔟 Loading hot topics[^\n]*\n*" nil t)
              (progn
                (replace-match "")
                (if (not ok)
                    (insert (format "  Error loading hot topics: %s\n" data))
                  (let ((idx 1))
                    (dolist (item (seq-take data 8))
                      (let* ((id (v2ex--get-field 'id item))
                             (title (or (v2ex--get-field 'title item) ""))
                             (node-obj (v2ex--get-field 'node item))
                             (node-title (or (v2ex--get-field 'name node-obj) (v2ex--get-field 'title node-obj) ""))
                             (replies (or (v2ex--get-field 'replies item) 0))
                             (start-pos (point)))
                        (insert (format "  %d. " idx))
                        (insert (propertize title 'face 'v2ex-title-face))
                        (unless (string-empty-p node-title)
                          (insert (propertize (format " [%s]" node-title) 'face 'v2ex-node-badge-face)))
                        (insert (propertize (format " (󰭹 %d)" replies) 'face 'v2ex-reply-count-face))
                        (insert "\n")
                        (put-text-property start-pos (point) 'v2ex-topic-id id)
                        (setq idx (1+ idx)))))))
            (message "V2EX: Hot topics loading marker not found")))))))

(defun v2ex--render-homepage-rss-feed (buf ok topics)
  "Update RSS feed section in BUF."
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (save-excursion
          (goto-char (point-min))
          (if (re-search-forward "  󰔟 Loading tech feed[^\n]*\n*" nil t)
              (progn
                (replace-match "")
                (if (not ok)
                    (insert (format "  Error loading RSS feed: %s\n" topics))
                  (if (null topics)
                      (insert "  No topics found in RSS feed.\n")
                    (dolist (item topics)
                      (let* ((id (v2ex--get-field 'id item))
                             (title (or (v2ex--get-field 'title item) ""))
                             (member-obj (v2ex--get-field 'member item))
                             (author (or (v2ex--get-field 'username member-obj) "anonymous"))
                             (created (v2ex--get-field 'created item))
                             (replies (or (v2ex--get-field 'replies item) 0))
                             (start-pos (point)))
                        (insert "  󰅂 ")
                        (insert (propertize title 'face 'v2ex-title-face))
                        (insert (propertize (format " (󰭹 %d)" replies) 'face 'v2ex-reply-count-face))
                        (insert (propertize (format "  by %s • %s\n" author (v2ex--format-timestamp created))
                                            'face 'v2ex-meta-face))
                        (put-text-property start-pos (point) 'v2ex-topic-id id))))))
            (message "V2EX: RSS feed loading marker not found")))))))

(defun v2ex-homepage-refresh ()
  "Refresh current Homepage asynchronously."
  (interactive)
  (v2ex-homepage-render))

(defun v2ex-homepage-open-topic ()
  "Open topic under point asynchronously."
  (interactive)
  (let ((topic-id (or (get-text-property (point) 'v2ex-topic-id)
                      (get-text-property (line-beginning-position) 'v2ex-topic-id)
                      (get-text-property (line-end-position) 'v2ex-topic-id))))
    (unless topic-id
      (let ((p (line-beginning-position))
            (end (line-end-position)))
        (while (and (not topic-id) (< p end))
          (setq topic-id (get-text-property p 'v2ex-topic-id))
          (setq p (1+ p)))))
    (if topic-id
        (v2ex-view-topic topic-id)
      (user-error "No V2EX topic selected at point"))))

;;; ----------------------------------------------------------------------------
;;; Asynchronous Topic Details & Replies View
;;; ----------------------------------------------------------------------------

(defvar v2ex-topic-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "]") #'v2ex-topic-next-page)
    (define-key map (kbd "[") #'v2ex-topic-prev-page)
    (define-key map (kbd "M-n") #'v2ex-topic-next-page)
    (define-key map (kbd "M-p") #'v2ex-topic-prev-page)
    (define-key map (kbd "M-g g") #'v2ex-topic-goto-page)
    (define-key map (kbd "M-g M-g") #'v2ex-topic-goto-page)
    (define-key map (kbd "r") #'v2ex-topic-refresh)
    (define-key map (kbd "q") #'quit-window)
    map)
  "Keymap for `v2ex-topic-mode'.")

(define-derived-mode v2ex-topic-mode special-mode "V2EX-Topic"
  "Major mode for viewing a V2EX topic and its replies."
  (setq-local truncate-lines t)
  (use-local-map v2ex-topic-mode-map))

(defun v2ex-view-topic (topic-id &optional page)
  "Fetch and view topic TOPIC-ID asynchronously with full content and replies list."
  (interactive "nTopic ID: ")
  (let* ((p (or page 1))
         (buf-name (format "*V2EX Topic #%d*" topic-id))
         (buf (get-buffer-create buf-name))
         (has-token (and v2ex-token (not (string-empty-p v2ex-token)))))
    (with-current-buffer buf
      (v2ex-topic-mode)
      (let ((inhibit-read-only t))
        (erase-buffer)
        (setq v2ex--current-topic-id topic-id)
        (setq v2ex--current-page p)
        (insert (propertize (format "Topic #%d (Loading Page %d...)\n\n" topic-id p) 'face 'v2ex-title-face))
        (insert "  󰔟 Fetching topic content and replies asynchronously...\n"))
      (goto-char (point-min)))
    (switch-to-buffer buf)

    (if has-token
        ;; API v2 Async
        (v2ex--request-async
         (format "topics/%d" topic-id)
         (lambda (t-ok t-data)
           (v2ex--request-async
            (format "topics/%d/replies" topic-id)
            (lambda (r-ok r-data)
              (v2ex--update-topic-buffer buf topic-id t-ok t-data r-ok r-data p))
            :params `((p . ,p)))))
      ;; API v1 Async Fallback
      (v2ex--request-async
       "https://www.v2ex.com/api/topics/show.json"
       (lambda (t-ok t-data)
         (v2ex--request-async
          "https://www.v2ex.com/api/replies/show.json"
          (lambda (r-ok r-data)
            (let ((topic-obj (when (and t-ok (listp t-data)) (car t-data))))
              (v2ex--update-topic-buffer buf topic-id t-ok topic-obj r-ok r-data p)))
          :params `((topic_id . ,topic-id) (p . ,p) (page . ,p))))
       :params `((id . ,topic-id))))))

(defun v2ex--update-topic-buffer (buf topic-id t-ok topic r-ok replies p)
  "Render topic content and replies into BUF after async fetch completes."
  (when (buffer-live-p buf)
    (with-current-buffer buf
      (let ((inhibit-read-only t))
        (erase-buffer)
        (if (not (and t-ok topic))
            (insert (format "Error loading Topic #%d: %s\n" topic-id (or topic "Topic not found")))
          (setq v2ex--current-topic-data topic)
          (setq v2ex--current-topic-id topic-id)
          (setq v2ex--current-page p)
          (let* ((sep-line (v2ex--separator-line ?─))
                 (double-sep-line (v2ex--separator-line ?═))
                 (title (v2ex--get-field 'title topic))
                 (member-obj (v2ex--get-field 'member topic))
                 (author (or (v2ex--get-field 'username member-obj) "anonymous"))
                 (node-obj (v2ex--get-field 'node topic))
                 (node-title (or (v2ex--get-field 'name node-obj) (v2ex--get-field 'title node-obj) ""))
                 (created (v2ex--get-field 'created topic))
                 (content (or (v2ex--get-field 'content_rendered topic) (v2ex--get-field 'content topic) ""))
                 (reply-list (if (and r-ok (listp replies)) replies nil))
                 (reply-count (or (v2ex--get-field 'replies topic) (if (listp replies) (length replies) 0))))
            ;; 1. Topic Title & Meta Header
            (insert (propertize (format "%s\n" title) 'face 'v2ex-title-face))
            (insert (propertize (format "Node: %s  •  Author: %s  •  Created: %s  •  Total Replies: %d\n"
                                        node-title author (v2ex--format-timestamp created) reply-count)
                                'face 'v2ex-meta-face))
            (insert sep-line "\n")

            ;; 2. Topic Content Body
            (v2ex--render-html-or-text content)
            (insert "\n" double-sep-line "\n")

            ;; 3. Replies Navigation Header
            (insert (propertize (format "󰭹 Replies (Page %d, %d items loaded, Total: %d):\n"
                                        p (length reply-list) reply-count)
                                'face 'v2ex-header-face))
            (insert (propertize "  []] Next Page  •  [[] Prev Page  •  [M-g g] Go to Page  •  [r] Refresh\n"
                                'face 'v2ex-meta-face))
            (insert sep-line "\n")

            ;; 4. Replies Section
            (if (null reply-list)
                (insert (format "  No replies found on page %d.\n" p))
              (let ((idx 1)
                    (total (length reply-list)))
                (dolist (reply reply-list)
                  (let* ((r-member (v2ex--get-field 'member reply))
                         (r-author (or (v2ex--get-field 'username r-member) "anonymous"))
                         (r-created (v2ex--get-field 'created reply))
                         (r-content (or (v2ex--get-field 'content_rendered reply) (v2ex--get-field 'content reply) "")))
                    (insert (propertize (format "#%d  %s  (%s)\n"
                                                (+ (* (1- p) (length reply-list)) idx)
                                                r-author
                                                (v2ex--format-timestamp r-created))
                                        'face 'v2ex-reply-header-face))
                    (v2ex--render-html-or-text r-content)
                    (unless (= idx total)
                      (insert "\n" sep-line "\n"))
                    (setq idx (1+ idx))))))
            (insert "\n" sep-line "\n")
            (insert (propertize (format "  Page %d  •  []] Next Page  •  [[] Prev Page  •  [M-g g] Go to Page\n" p)
                                'face 'v2ex-meta-face))))
        (goto-char (point-min)))
      (message "Topic #%d (Page %d) loaded asynchronously." topic-id p))))

(defun v2ex--render-html-or-text (str)
  "Render HTML snippet STR using `shr-insert-document' if HTML tags present, else insert text."
  (if (and (stringp str) (string-match-p "<[a-z1-6]+[^>]*>" str))
      (condition-case _
          (let ((dom (with-temp-buffer
                       (insert str)
                       (libxml-parse-html-region (point-min) (point-max)))))
            (shr-insert-document dom))
        (error (insert (or str ""))))
    (insert (or str "")))
  (save-excursion
    (skip-chars-backward " \t\r\n")
    (unless (bobp)
      (delete-region (point) (point-max)))))

(defun v2ex-topic-refresh ()
  "Refresh current topic asynchronously."
  (interactive)
  (if v2ex--current-topic-id
      (v2ex-view-topic v2ex--current-topic-id (or v2ex--current-page 1))
    (user-error "Not in a V2EX topic buffer")))

(defun v2ex-topic-next-page ()
  "Load next page of replies for current topic."
  (interactive)
  (if v2ex--current-topic-id
      (v2ex-view-topic v2ex--current-topic-id (1+ (or v2ex--current-page 1)))
    (user-error "Not in a V2EX topic buffer")))

(defun v2ex-topic-prev-page ()
  "Load previous page of replies for current topic."
  (interactive)
  (if v2ex--current-topic-id
      (if (> (or v2ex--current-page 1) 1)
          (v2ex-view-topic v2ex--current-topic-id (1- (or v2ex--current-page 1)))
        (message "Already on page 1."))
    (user-error "Not in a V2EX topic buffer")))

(defun v2ex-topic-goto-page (page)
  "Jump to specified PAGE of replies for current topic."
  (interactive "nPage: ")
  (if v2ex--current-topic-id
      (v2ex-view-topic v2ex--current-topic-id (max 1 page))
    (user-error "Not in a V2EX topic buffer")))

;;; ----------------------------------------------------------------------------
;;; Evil Mode Integration
;;; ----------------------------------------------------------------------------

(with-eval-after-load 'evil
  (evil-set-initial-state 'v2ex-homepage-mode 'normal)
  (evil-set-initial-state 'v2ex-topic-mode 'normal)

  (evil-define-key '(normal motion) v2ex-homepage-mode-map
    (kbd "RET") #'v2ex-homepage-open-topic
    (kbd "o") #'v2ex-homepage-open-topic
    (kbd "r") #'v2ex-homepage-refresh
    (kbd "q") #'quit-window
    (kbd "j") #'evil-next-line
    (kbd "k") #'evil-previous-line)

  (evil-define-key '(normal motion) v2ex-topic-mode-map
    (kbd "q") #'quit-window
    (kbd "r") #'v2ex-topic-refresh
    (kbd "]") #'v2ex-topic-next-page
    (kbd "[") #'v2ex-topic-prev-page
    (kbd "M-n") #'v2ex-topic-next-page
    (kbd "M-p") #'v2ex-topic-prev-page
    (kbd "j") #'evil-next-line
    (kbd "k") #'evil-previous-line))

(provide 'init-v2ex)
;;; init-v2ex.el ends here
