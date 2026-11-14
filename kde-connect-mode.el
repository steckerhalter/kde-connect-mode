;;; kde-connect-mode.el --- Live stream keys and backspace via D-Bus -*- lexical-binding: t; -*-

;; Author: Reto Hubmann (@steckerhalter)
;; Version: 0.2.0
;; Package-Requires: ((emacs "26.1"))
;; Keywords: comm, convenience, hardware

;;; Commentary:

;; Provides `kde-connect-mode', a minor mode that forwards keystrokes,
;; newlines, and backspaces in real time to a paired KDE Connect device
;; via `qdbus6` and the remote keyboard D-Bus interface, along with
;; `kde-connect-scratchpad` for quick distraction-free typing on desktop.

;;; Code:

(defgroup kde-connect nil
  "Stream keystrokes and backspace to KDE Connect via D-Bus."
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
      ;; kdeconnect-cli -a output looks like: "- Device Name: id_string (paired and reachable)"
      (when (string-match "- \\(.*?\\): \\([a-zA-Z0-9_]+\\) " line)
        (let ((name (match-string 1 line))
              (id (match-string 2 line)))
          (unless first-id (setq first-id id))
          (when (and kde-connect-device-name
                     (string= name kde-connect-device-name))
            (setq matched-id id)))))
    ;; Return matched device, or fallback to first available, or raw --id-only output
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

(defun kde-connect-send-return ()
  "Send Enter (newline) via D-Bus and insert locally."
  (interactive)
  (kde-connect--dbus-call "\n" 0)
  (newline))

(defun kde-connect-send-backspace ()
  "Send Backspace keycode (specialKey = 1) via D-Bus and delete locally."
  (interactive)
  (kde-connect--dbus-call "" 1)
  (delete-char -1))

(defun kde-connect-send-left ()
  "Send Left arrow key (specialKey = 4) via D-Bus and move cursor left."
  (interactive)
  (kde-connect--dbus-call "" 4)
  (backward-char 1))

(defun kde-connect-send-up ()
  "Send Up arrow key (specialKey = 5) via D-Bus and move cursor up."
  (interactive)
  (kde-connect--dbus-call "" 5)
  (previous-line 1))

(defun kde-connect-send-right ()
  "Send Right arrow key (specialKey = 6) via D-Bus and move cursor right."
  (interactive)
  (kde-connect--dbus-call "" 6)
  (forward-char 1))

(defun kde-connect-send-down ()
  "Send Down arrow key (specialKey = 7) via D-Bus and move cursor down."
  (interactive)
  (kde-connect--dbus-call "" 7)
  (next-line 1))

(defun kde-connect-quit ()
  "Disable `kde-connect-mode' and close window."
  (interactive)
  (kde-connect-mode -1)
  (quit-window))

(defvar kde-connect-mode-map
  (let ((map (make-sparse-keymap)))
    (define-key map (kbd "RET") #'kde-connect-send-return)
    (define-key map (kbd "<backspace>") #'kde-connect-send-backspace)
    (define-key map (kbd "DEL") #'kde-connect-send-backspace)
    (define-key map (kbd "<left>") #'kde-connect-send-left)
    (define-key map (kbd "<right>") #'kde-connect-send-right)
    (define-key map (kbd "<up>") #'kde-connect-send-up)
    (define-key map (kbd "<down>") #'kde-connect-send-down)
    (define-key map (kbd "C-c C-c") #'kde-connect-quit)
    map)
  "Keymap for `kde-connect-mode'.")

;;;###autoload
(define-minor-mode kde-connect-mode
  "Minor mode that streams keystrokes and backspaces live via D-Bus."
  :lighter " KDE-DBus"
  :keymap kde-connect-mode-map
  (if kde-connect-mode
      (add-hook 'post-self-insert-hook #'kde-connect--on-self-insert nil t)
    (remove-hook 'post-self-insert-hook #'kde-connect--on-self-insert t)))

;;;###autoload
(defun kde-connect-scratchpad ()
  "Open a dedicated scratchpad buffer with D-Bus live typing active."
  (interactive)
  (let ((buf (get-buffer-create "*KDE Connect Scratchpad*")))
    (switch-to-buffer-other-window buf)
    (erase-buffer)
    (kde-connect-mode 1)
    (message "Live KDE Connect typing active (C-c C-c to finish)")))

(provide 'kde-connect-mode)

;;; kde-connect-mode.el ends here
