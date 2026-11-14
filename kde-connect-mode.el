;;; kde-connect-mode.el --- Live stream keys and cursor movement via D-Bus -*- lexical-binding: t; -*-

;; Author: Reto Hubmann (@steckerhalter)
;; Version: 0.3.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: comm, convenience, hardware

;;; Commentary:

;; Provides `kde-connect-mode`, a minor mode that hooks into post-insertion
;; and post-command actions to stream keystrokes, backspaces, and cursor
;; movements live to a paired KDE Connect device via `qdbus6`.

;;; Code:

(defgroup kde-connect nil
  "Stream keystrokes and cursor movements to KDE Connect via D-Bus."
  :group 'comm
  :prefix "kde-connect-")

(defcustom kde-connect-device-name ""
  "Name of the target device in KDE Connect."
  :type 'string
  :group 'kde-connect)

(defun kde-connect--get-device-id ()
  "Retrieve the D-Bus device ID.
If `kde-connect-device-name' is set, try to find its matching ID.
Otherwise, or if not found, fall back to the first available device."
  (let* ((output (shell-command-to-string "kdeconnect-cli -a"))
         (lines (split-string output "\n" t))
         matched-id
         first-id)
    (dolist (line lines)
      (when (string-match "- \\(.*?\\): \\([a-zA-Z0-9_]+\\) " line)
        (let ((name (match-string 1 line))
              (id (match-string 2 line)))
          (unless first-id (setq first-id id))
          (when (and kde-connect-device-name
                     (string= name kde-connect-device-name))
            (setq matched-id id)))))
    (or matched-id
        first-id
        (string-trim (shell-command-to-string "kdeconnect-cli -a --id-only | head -n1")))))

(defun kde-connect--dbus-call (key special-key)
  "Send KEY string and SPECIAL-KEY integer via D-Bus to KDE Connect."
  (let* ((dev-id (kde-connect--get-device-id))
         (path (format "/modules/kdeconnect/devices/%s/remotekeyboard" dev-id)))
    (when (not (string-empty-p dev-id))
      (call-process "qdbus6" nil 0 nil
                    "org.kde.kdeconnect"
                    path
                    "org.kde.kdeconnect.device.remotekeyboard.sendKeyPress"
                    key
                    (number-to-string special-key)
                    "false"
                    "false"))))

(defun kde-connect--on-self-insert ()
  "Forward inserted character immediately via D-Bus."
  (when (and kde-connect-mode
             (characterp last-command-event))
    (kde-connect--dbus-call (char-to-string last-command-event) 0)))

(defun kde-connect--post-command ()
  "Inspect `this-command' and stream navigation or deletion actions via D-Bus."
  (when kde-connect-mode
    (cond
     ;; Newline / Return
     ((memq this-command '(newline electric-newline-and-easily-indent))
      (kde-connect--dbus-call "\n" 0))
     ;; Backspace / Delete
     ((memq this-command '(delete-backward-char backward-delete-char))
      (kde-connect--dbus-call "" 1))
     ;; Arrow Left (specialKey = 4)
     ((eq this-command 'backward-char)
      (kde-connect--dbus-call "" 4))
     ;; Arrow Up (specialKey = 5)
     ((eq this-command 'previous-line)
      (kde-connect--dbus-call "" 5))
     ;; Arrow Right (specialKey = 6)
     ((eq this-command 'forward-char)
      (kde-connect--dbus-call "" 6))
     ;; Arrow Down (specialKey = 7)
     ((eq this-command 'next-line)
      (kde-connect--dbus-call "" 7)))))

(defun kde-connect-quit ()
  "Disable `kde-connect-mode' and close window."
  (interactive)
  (kde-connect-mode -1)
  (quit-window))

;;;###autoload
(define-minor-mode kde-connect-mode
  "Minor mode that streams keystrokes and navigation live via D-Bus hooks."
  :lighter " KDE-DBus"
  (if kde-connect-mode
      (progn
        (add-hook 'post-self-insert-hook #'kde-connect--on-self-insert nil t)
        (add-hook 'post-command-hook #'kde-connect--post-command nil t))
    (remove-hook 'post-self-insert-hook #'kde-connect--on-self-insert t)
    (remove-hook 'post-command-hook #'kde-connect--post-command t)))

;;;###autoload
(defun kde-connect-scratchpad ()
  "Open a dedicated scratchpad buffer with D-Bus live typing active."
  (interactive)
  (let ((buf (get-buffer-create "*KDE Connect Scratchpad*")))
    (switch-to-buffer-other-window buf)
    (erase-buffer)
    (kde-connect-mode 1)
    (message "Live KDE Connect typing active (run M-x kde-connect-quit to finish)")))

(provide 'kde-connect-mode)

;;; kde-connect-mode.el ends here
