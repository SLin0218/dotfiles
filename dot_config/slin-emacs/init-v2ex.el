;;; init-v2ex.el --- Asynchronous V2EX Client & Homepage Dashboard for Emacs  -*- lexical-binding: t; -*-

;;; Commentary:
;; A complete non-blocking V2EX client for Emacs featuring a Single-Buffer Homepage Dashboard:
;; - Async HTTP requests (zero UI freezing/blocking when loading homepage or viewing topics)
;; - Top Section: Today's Hot Topics (今日热议主题)
;; - Bottom Section: Aggregated Tech RSS Feed (tech.xml)
;; - Full Browser Header Simulation (User-Agent, Accept-Language, Sec-Ch-Ua, etc.)
;; - Personal Access Token authentication (API 2.0 Beta)
;; - Notifications (GET /api/v2/notifications?p=N, DELETE /api/v2/notifications/:id)
;; - User Profile (GET /api/v2/member) & Token Information (GET /api/v2/token)
;; - Topic Details & Replies View (GET /api/v2/topics/:id, GET /api/v2/topics/:id/replies)
;; - Evil Vim mode integration (j/k navigation, RET/o open, g/r refresh, q quit)

;;; Code:

(require 'json)
(require 'url)
(require 'tabulated-list)
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
(defvar-local v2ex--current-node nil)
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

;;; Helper for field lookups (supports both string and symbol keys in JSON alists)

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

(defun v2ex--unwrap-result (res)
  "Extract data payload from API response RES."
  (if (not (plist-get res :success))
      (error "V2EX Request Failed: %s" (plist-get res :error))
    (let ((raw (plist-get res :data)))
      (if (and (listp raw) (v2ex--get-field 'result raw))
          (let ((success (v2ex--get-field 'success raw)))
            (if (eq success :json-false)
                (error "V2EX API Error: %s" (v2ex--get-field 'message raw))
              (v2ex--get-field 'result raw)))
        raw))))

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
;;; Asynchronous & Synchronous HTTP Request Engine
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

(defun v2ex--request (endpoint &rest args)
  "Perform synchronous HTTP request using `v2ex--request-async`."
  (let ((res nil)
        (done nil))
    (apply #'v2ex--request-async endpoint
           (lambda (ok data)
             (setq res (list :success ok :data data))
             (setq done t))
           args)
    (while (not done)
      (accept-process-output nil 0.05))
    res))

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
     (lambda (proc event)
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

;;; ----------------------------------------------------------------------------
;;; Asynchronous Single-Buffer V2EX Homepage Dashboard
;;; ----------------------------------------------------------------------------

(defvar v2ex-homepage-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'v2ex-homepage-open-topic)
    (define-key map (kbd "o") #'v2ex-homepage-open-topic)
    (define-key map (kbd "g") #'v2ex-homepage-refresh)
    (define-key map (kbd "r") #'v2ex-homepage-refresh)
    (define-key map (kbd "q") #'quit-window)
    (define-key map [mouse-2] #'v2ex-homepage-open-topic)
    map)
  "Keymap for `v2ex-homepage-mode'.")

(define-derived-mode v2ex-homepage-mode special-mode "V2EX-Homepage"
  "Major mode for Single-Buffer V2EX Homepage."
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
        (let ((sep-line (make-string (max 10 (- (window-width) 4)) ?─)))
          (insert (propertize " 🔥 今日热议主题\n" 'face 'v2ex-header-face))
          (insert sep-line "\n")
          (insert "  ⏳ Loading hot topics...\n\n")
          (insert (make-string (max 10 (- (window-width) 4)) ?═) "\n\n")
          (insert (propertize " 💻 技术聚合 Feed (tech.xml)\n" 'face 'v2ex-header-face))
          (insert sep-line "\n")
          (insert "  ⏳ Loading tech feed...\n")))
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
          (if (re-search-forward "  ⏳ Loading hot topics[^\n]*\n*" nil t)
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
                        (insert (propertize (format " (💬 %d)" replies) 'face 'v2ex-reply-count-face))
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
          (if (re-search-forward "  ⏳ Loading tech feed[^\n]*\n*" nil t)
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
                        (insert "  ● ")
                        (insert (propertize title 'face 'v2ex-title-face))
                        (insert (propertize (format "  💬 %d" replies) 'face 'v2ex-reply-count-face))
                        (insert "\n    ")
                        (insert (propertize (format "by %s  •  %s\n\n" author (v2ex--format-timestamp created))
                                            'face 'v2ex-meta-face))
                        (put-text-property start-pos (point) 'v2ex-topic-id id))))))
            (message "V2EX: RSS feed loading marker not found")))))))

(defun v2ex-homepage-refresh ()
  "Refresh current Homepage asynchronously."
  (interactive)
  (v2ex-homepage-render))

(defun v2ex-homepage-open-topic ()
  "Open topic under point or anywhere on current line asynchronously in topic detail buffer."
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
    (define-key map (kbd "s") #'v2ex-topic-set-sticky)
    (define-key map (kbd "b") #'v2ex-topic-boost)
    (define-key map (kbd "g") #'v2ex-topic-refresh)
    (define-key map (kbd "r") #'v2ex-topic-refresh)
    (define-key map (kbd "q") #'quit-window)
    map)
  "Keymap for `v2ex-topic-mode'.")

(define-derived-mode v2ex-topic-mode special-mode "V2EX-Topic"
  "Major mode for viewing a V2EX topic and its replies."
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
        (insert (propertize (format "Topic #%d\n\n" topic-id) 'face 'v2ex-title-face))
        (insert "  ⏳ Fetching topic content and replies asynchronously...\n"))
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
          :params `((topic_id . ,topic-id) (p . ,p))))
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
          (let* ((sep-line (make-string (max 10 (- (window-width) 4)) ?─))
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
            (insert (propertize (format "%s\n\n" title) 'face 'v2ex-title-face))
            (insert (propertize (format "Node: %s  |  Author: %s  |  Created: %s  |  Replies: %d\n"
                                        node-title author (v2ex--format-timestamp created) reply-count)
                                'face 'v2ex-meta-face))
            (insert sep-line "\n\n")

            ;; 2. Topic Content Body
            (v2ex--render-html-or-text content)
            (insert "\n\n" (make-string (max 10 (- (window-width) 4)) ?═) "\n")
            (insert (propertize (format "💬 Replies (%d items, Page %d):\n\n" (length reply-list) p)
                                'face 'v2ex-header-face))

            ;; 3. Replies Section
            (if (null reply-list)
                (insert "  No replies yet.\n")
              (let ((idx 1))
                (dolist (reply reply-list)
                  (let* ((r-member (v2ex--get-field 'member reply))
                         (r-author (or (v2ex--get-field 'username r-member) "anonymous"))
                         (r-created (v2ex--get-field 'created reply))
                         (r-content (or (v2ex--get-field 'content_rendered reply) (v2ex--get-field 'content reply) "")))
                    (insert (propertize (format "#%d  %s  (%s)\n" idx r-author (v2ex--format-timestamp r-created))
                                        'face 'v2ex-reply-header-face))
                    (v2ex--render-html-or-text r-content)
                    (insert "\n" sep-line "\n\n")
                    (setq idx (1+ idx))))))))
        (goto-char (point-min)))
      (message "Topic #%d loaded asynchronously." topic-id))))

(defun v2ex--render-html-or-text (str)
  "Render HTML snippet STR using `shr-insert-document' if HTML tags present, else insert text."
  (if (string-match-p "<[a-z1-6]+[^>]*>" str)
      (condition-case _
          (let ((dom (libxml-parse-html-region (point) (point))))
            (shr-insert-document (with-temp-buffer
                                   (insert str)
                                   (libxml-parse-html-region (point-min) (point-max)))))
        (error (insert str)))
    (insert str)))

(defun v2ex-topic-refresh ()
  "Refresh current topic asynchronously."
  (interactive)
  (if v2ex--current-topic-id
      (v2ex-view-topic v2ex--current-topic-id (or v2ex--current-page 1))
    (user-error "Not in a V2EX topic buffer")))

(defun v2ex-topic-set-sticky (duration)
  "Set sticky for current topic (POST /api/v2/topics/:topic_id/set-sticky?duration=...)."
  (interactive
   (list (completing-read "Sticky duration: " '("15min" "1hr" "8hr") nil t "1hr")))
  (unless v2ex--current-topic-id
    (user-error "Not in a V2EX topic buffer"))
  (unless (and v2ex-token (not (string-empty-p v2ex-token)))
    (call-interactively #'v2ex-set-token))
  (let ((endpoint (format "topics/%d/set-sticky" v2ex--current-topic-id)))
    (v2ex--request-async
     endpoint
     (lambda (ok res)
       (if ok
           (message "Topic #%d sticky set to %s successfully." v2ex--current-topic-id duration)
         (message "Failed to set sticky: %s" res)))
     :method "POST" :params `((duration . ,duration)))))

(defun v2ex-topic-boost ()
  "Boost current topic to homepage (POST /api/v2/topics/:topic_id/boost)."
  (interactive)
  (unless v2ex--current-topic-id
    (user-error "Not in a V2EX topic buffer"))
  (unless (and v2ex-token (not (string-empty-p v2ex-token)))
    (call-interactively #'v2ex-set-token))
  (when (y-or-n-p (format "Boost topic #%d to homepage (costs 100 copper coins)? " v2ex--current-topic-id))
    (let ((endpoint (format "topics/%d/boost" v2ex--current-topic-id)))
      (v2ex--request-async
       endpoint
       (lambda (ok res)
         (if ok
             (message "Topic #%d boosted to homepage successfully." v2ex--current-topic-id)
           (message "Failed to boost topic: %s" res)))
       :method "POST"))))

;;; ----------------------------------------------------------------------------
;;; Notifications, Profile, Token Info API Functions
;;; ----------------------------------------------------------------------------

(defvar v2ex-notifications-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'v2ex-notifications-open-topic)
    (define-key map (kbd "o") #'v2ex-notifications-open-topic)
    (define-key map (kbd "d") #'v2ex-delete-notification-at-point)
    (define-key map (kbd "k") #'v2ex-delete-notification-at-point)
    (define-key map (kbd "n") #'v2ex-notifications-next-page)
    (define-key map (kbd "p") #'v2ex-notifications-prev-page)
    (define-key map (kbd "g") #'v2ex-notifications-refresh)
    (define-key map (kbd "r") #'v2ex-notifications-refresh)
    (define-key map (kbd "q") #'quit-window)
    map)
  "Keymap for `v2ex-notifications-mode'.")

(define-derived-mode v2ex-notifications-mode tabulated-list-mode "V2EX-Notifications"
  "Major mode for browsing V2EX notifications."
  (setq tabulated-list-format [("ID" 10 t)
                               ("Sender" 14 t)
                               ("Notification Content" 55 nil)
                               ("Created Time" 18 t)])
  (setq tabulated-list-padding 2)
  (tabulated-list-init-header))

(defun v2ex-notifications (&optional page)
  "Fetch and display latest notifications asynchronously."
  (interactive "P")
  (unless (and v2ex-token (not (string-empty-p v2ex-token)))
    (call-interactively #'v2ex-set-token))
  (let* ((p (or page 1))
         (buf (get-buffer-create "*V2EX Notifications*")))
    (with-current-buffer buf
      (v2ex-notifications-mode)
      (setq v2ex--current-page p)
      (setq tabulated-list-entries nil)
      (tabulated-list-print t))
    (switch-to-buffer buf)
    (message "Fetching V2EX Notifications (Page %d)..." p)
    (v2ex--request-async
     "notifications"
     (lambda (ok data)
       (when (buffer-live-p buf)
         (with-current-buffer buf
           (if (not ok)
               (message "Error loading notifications: %s" data)
             (setq tabulated-list-entries
                   (mapcar (lambda (item)
                             (let* ((id (format "%s" (or (v2ex--get-field 'id item) "")))
                                    (member-info (v2ex--get-field 'member item))
                                    (member-name (or (v2ex--get-field 'username member-info) "System"))
                                    (text (or (v2ex--get-field 'text item) ""))
                                    (payload (or (v2ex--get-field 'payload item) ""))
                                    (created (v2ex--get-field 'created item))
                                    (content-str (if (string-empty-p payload) text (concat text ": " payload))))
                               (list item
                                     (vector id
                                             member-name
                                             (truncate-string-to-width content-str 55 nil nil "...")
                                             (v2ex--format-timestamp created)))))
                           data))
             (tabulated-list-print t)
             (message "Notifications loaded.")))))
     :params `((p . ,p)))))

(defun v2ex-notifications-refresh ()
  "Refresh current notifications page."
  (interactive)
  (v2ex-notifications (or v2ex--current-page 1)))

(defun v2ex-notifications-next-page ()
  "Load next page of notifications."
  (interactive)
  (v2ex-notifications (1+ (or v2ex--current-page 1))))

(defun v2ex-notifications-prev-page ()
  "Load previous page of notifications."
  (interactive)
  (if (> (or v2ex--current-page 1) 1)
      (v2ex-notifications (1- (or v2ex--current-page 1)))
    (message "Already on page 1.")))

(defun v2ex-delete-notification-at-point ()
  "Delete notification at point asynchronously."
  (interactive)
  (let ((item (tabulated-list-get-id)))
    (unless item
      (user-error "No notification selected"))
    (let* ((id (v2ex--get-field 'id item))
           (id-str (format "%s" id)))
      (when (y-or-n-p (format "Delete notification #%s? " id-str))
        (v2ex--request-async
         (format "notifications/%s" id-str)
         (lambda (ok res)
           (if ok
               (progn
                 (message "Notification #%s deleted successfully." id-str)
                 (v2ex-notifications-refresh))
             (message "Failed to delete notification: %s" res)))
         :method "DELETE")))))

(defun v2ex-notifications-open-topic ()
  "Extract topic ID from notification payload or prompt user to open topic."
  (interactive)
  (let ((item (tabulated-list-get-id)))
    (unless item
      (user-error "No notification selected"))
    (let* ((payload (or (v2ex--get-field 'payload item) ""))
           (text (or (v2ex--get-field 'text item) ""))
           (combined (concat text " " payload))
           (topic-id nil))
      (when (string-match "/t/\\([0-9]+\\)" combined)
        (setq topic-id (string-to-number (match-string 1 combined))))
      (unless topic-id
        (setq topic-id (read-number "Topic ID: ")))
      (when topic-id
        (v2ex-view-topic topic-id)))))

(defun v2ex-member ()
  "Fetch and display current user profile asynchronously."
  (interactive)
  (unless (and v2ex-token (not (string-empty-p v2ex-token)))
    (call-interactively #'v2ex-set-token))
  (let ((buf (get-buffer-create "*V2EX Profile*")))
    (with-current-buffer buf
      (read-only-mode -1)
      (erase-buffer)
      (insert (propertize "=== V2EX User Profile ===\n\n" 'face 'v2ex-header-face))
      (insert "  ⏳ Loading profile asynchronously...\n")
      (goto-char (point-min))
      (special-mode))
    (switch-to-buffer buf)
    (v2ex--request-async
     "member"
     (lambda (ok data)
       (when (buffer-live-p buf)
         (with-current-buffer buf
           (read-only-mode -1)
           (erase-buffer)
           (insert (propertize "=== V2EX User Profile ===\n\n" 'face 'v2ex-header-face))
           (if (not ok)
               (insert (format "Error loading profile: %s\n" data))
             (insert (format "ID:            %s\n" (v2ex--get-field 'id data)))
             (insert (format "Username:      %s\n" (v2ex--get-field 'username data)))
             (insert (format "URL:           %s\n" (or (v2ex--get-field 'url data) "N/A")))
             (insert (format "Tagline:       %s\n" (or (v2ex--get-field 'tagline data) "N/A")))
             (insert (format "Bio:           %s\n" (or (v2ex--get-field 'bio data) "N/A")))
             (insert (format "Website:       %s\n" (or (v2ex--get-field 'website data) "N/A")))
             (insert (format "Twitter:       %s\n" (or (v2ex--get-field 'twitter data) "N/A")))
             (insert (format "GitHub:        %s\n" (or (v2ex--get-field 'github data) "N/A")))
             (insert (format "Created:       %s\n" (v2ex--format-timestamp (v2ex--get-field 'created data))))
             (insert (format "Last Modified: %s\n" (v2ex--format-timestamp (v2ex--get-field 'last_modified data)))))
           (goto-char (point-min))
           (special-mode)))))))

(defun v2ex-token-info ()
  "Fetch and display information about current Personal Access Token asynchronously."
  (interactive)
  (unless (and v2ex-token (not (string-empty-p v2ex-token)))
    (call-interactively #'v2ex-set-token))
  (let ((buf (get-buffer-create "*V2EX Token Info*")))
    (with-current-buffer buf
      (read-only-mode -1)
      (erase-buffer)
      (insert (propertize "=== Current V2EX Access Token ===\n\n" 'face 'v2ex-header-face))
      (insert "  ⏳ Loading token info asynchronously...\n")
      (goto-char (point-min))
      (special-mode))
    (switch-to-buffer buf)
    (v2ex--request-async
     "token"
     (lambda (ok data)
       (when (buffer-live-p buf)
         (with-current-buffer buf
           (read-only-mode -1)
           (erase-buffer)
           (insert (propertize "=== Current V2EX Access Token ===\n\n" 'face 'v2ex-header-face))
           (if (not ok)
               (insert (format "Error loading token info: %s\n" data))
             (insert (format "Token:       %s\n" (or (v2ex--get-field 'token data) v2ex-token)))
             (insert (format "Scope:       %s\n" (or (v2ex--get-field 'scope data) "N/A")))
             (insert (format "Expiration:  %s seconds\n" (or (v2ex--get-field 'expiration data) "N/A")))
             (insert (format "Created:     %s\n" (v2ex--format-timestamp (v2ex--get-field 'created data))))
             (insert (format "Last Used:   %s\n" (v2ex--format-timestamp (v2ex--get-field 'last_used data)))))
           (goto-char (point-min))
           (special-mode)))))))

;;; ----------------------------------------------------------------------------
;;; Evil Mode Integration
;;; ----------------------------------------------------------------------------

(defun v2ex--setup-evil-keys ()
  "Setup Evil initial states and keybindings for V2EX buffers."
  (when (fboundp 'evil-set-initial-state)
    (evil-set-initial-state 'v2ex-homepage-mode 'normal)
    (evil-set-initial-state 'v2ex-notifications-mode 'normal)
    (evil-set-initial-state 'v2ex-topics-mode 'normal)
    (evil-set-initial-state 'v2ex-topic-mode 'normal))

  (when (fboundp 'evil-define-key*)
    (evil-define-key* '(normal motion) v2ex-homepage-mode-map
      (kbd "RET") #'v2ex-homepage-open-topic
      (kbd "o") #'v2ex-homepage-open-topic
      (kbd "g") #'v2ex-homepage-refresh
      (kbd "r") #'v2ex-homepage-refresh
      (kbd "q") #'quit-window
      (kbd "j") #'evil-next-line
      (kbd "k") #'evil-previous-line)

    (evil-define-key* '(normal motion) v2ex-topic-mode-map
      (kbd "q") #'quit-window
      (kbd "g") #'v2ex-topic-refresh
      (kbd "r") #'v2ex-topic-refresh
      (kbd "s") #'v2ex-topic-set-sticky
      (kbd "b") #'v2ex-topic-boost
      (kbd "j") #'evil-next-line
      (kbd "k") #'evil-previous-line)))

(with-eval-after-load 'evil
  (v2ex--setup-evil-keys))

(when (featurep 'evil)
  (v2ex--setup-evil-keys))

(provide 'init-v2ex)
;;; init-v2ex.el ends here
