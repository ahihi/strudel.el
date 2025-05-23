;;; strudel.el --- Interact with strudel for livecoding music  -*- lexical-binding: t; -*-

;;; Commentary:

;;; Code:

(require 'cl)
(require 'comint)
(require 'pulse)

(require 'websocket)

(defvar strudel-buffer
  "*strudel*"
  "*The name of the strudel process buffer (default=*strudel*).")

(defvar strudel-websocket-address
  "127.0.0.1"
  "*The network address on which to open the Strudel websocket server.")

(defvar strudel-websocket-port
  8080
  "*The network port on which to open the Strudel websocket server.")

(defvar strudel-websocket-server
  nil)

(defvar strudel-highlight
  #'pulse-momentary-highlight-region
  "*Function to momentarily highlight code being evaluated (default=pulse-momentary-highlight-region). Takes two arguments specifying the endpoints of the region containing the code.")

(defvar strudel-websockets
  nil)

(defvar strudel-mode-map (make-sparse-keymap))

(define-minor-mode strudel-mode
  "Minor mode for livecoding music with strudel."
  :lighter " strudel")

(defun strudel-mode-if-appropriate ()
  "Enable strudel-mode if appropriate for the current buffer, i.e. its buffer-file-name has the extension `.strudel'."
  (interactive)
  (when (string-match-p "\.strudel$" buffer-file-name)
    (strudel-mode t)))

(defun strudel-start ()
  "Start strudel."
  (interactive)
  (if strudel-websocket-server
      (error "A strudel websocket server is already running")
    (setq strudel-websocket-server
          (websocket-server strudel-websocket-port
                            :host strudel-websocket-address
                            :on-open (lambda (ws &rest args)
                                       (print (list 'open ws args))
                                       (setq strudel-websockets (cons ws strudel-websockets))
                                       (print (length strudel-websockets)))
                            :on-close (lambda (ws &rest args)
                                        (print (list 'close args))
                                        (setq strudel-websockets (delq ws strudel-websockets))
                                        (print (length strudel-websockets)))
                            :on-error (lambda (&rest args) (print (list 'error args)))
                            :on-message (lambda (&rest args) (print (list 'message args)))))
  ))

(defun strudel-stop ()
  "Stop the websocket server."
  (interactive)
  (when strudel-websocket-server
    (websocket-server-close strudel-websocket-server)
    (setq strudel-websocket-server nil)))

(defun strudel-buffer-message (&rest args)
  (apply #'message args))

(defun strudel-see-output ()
  "Show strudel output."
  (interactive)
  (when (comint-check-proc strudel-buffer)
    (with-current-buffer strudel-buffer
      (let ((window (display-buffer (current-buffer))))
	(goto-char (point-max))
	(save-selected-window
	  (set-window-point window (point-max)))))))

(defun strudel-send-string (s)
  (if strudel-websocket-server
      (dolist (ws strudel-websockets)
        (websocket-send-text ws s))
    (error "no strudel websocket server running?")))

(defun strudel-chunk-string (n s)
  "Split a string S into chunks of N characters."
  (let* ((l (length s))
         (m (min l n))
         (c (substring s 0 m)))
    (if (<= l n)
        (list c)
      (cons c (strudel-chunk-string n (substring s n))))))

(defun strudel-eval-buffer-interval (a b &optional transform-text)
  (interactive)
  (let* ((l (min a b))
         (r (max a b))
         (s (buffer-substring-no-properties l r))
         (s (if transform-text (funcall transform-text s) s)))
    (strudel-send-string s)
    (if strudel-highlight
        (funcall strudel-highlight l r))))

(defun strudel-run (&optional transform-text)
  "Send the contents of the current buffer to Strudel."
  (interactive)
  (save-mark-and-excursion
    (mark-whole-buffer)
    (strudel-eval-buffer-interval (mark) (point) transform-text)))

(provide 'strudel)
;;; strudel.el ends here
