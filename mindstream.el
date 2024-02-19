;;; mindstream.el --- A scratch buffer -*- lexical-binding: t -*-

;; Author: Siddhartha Kasivajhula <sid@countvajhula.com>
;; URL: https://github.com/countvajhula/mindstream
;; Version: 0.0
;; Package-Requires: ((emacs "25.1") (racket-mode "20210517.1613") (magit "3.3.0"))
;; Keywords: lisp, convenience, languages

;; This program is "part of the world," in the sense described at
;; https://drym.org.  From your perspective, this is no different than
;; MIT or BSD or other such "liberal" licenses that you may be
;; familiar with, that is to say, you are free to do whatever you like
;; with this program.  It is much more than BSD or MIT, however, in
;; that it isn't a license at all but an idea about the world and how
;; economic systems could be set up so that everyone wins.  Learn more
;; at drym.org.
;;
;; This work transcends traditional legal and economic systems, but
;; for the purposes of any such systems within which you may need to
;; operate:
;;
;; This is free and unencumbered software released into the public domain.
;; The authors relinquish any copyright claims on this work.
;;

;;; Commentary:

;; A scratch buffer.

;;; Code:

(require 'magit-git)

(require 'mindstream-custom)
(require 'mindstream-scratch)
(require 'mindstream-util)

;; These are customization or config variables defined elsewhere;
;; explicitly declare them here to avoid byte compile warnings
;; TODO: handle this via an explicit configuration step
(declare-function racket-run "ext:racket-mode")

;;;###autoload
(define-minor-mode mindstream-mode
  "Minor mode providing keybindings for mindstream mode."
  :lighter " mindstream"
  :keymap
  (let ((mindstream-map (make-sparse-keymap)))
    (define-key mindstream-map (kbd "C-c C-r n") #'mindstream-new)
    (define-key mindstream-map (kbd "C-c C-r c") #'mindstream-clear)
    (define-key mindstream-map (kbd "C-c C-r s") #'mindstream-save-file)
    (define-key mindstream-map (kbd "C-c C-r S") #'mindstream-save-session)
    (define-key mindstream-map (kbd "C-c C-r r") #'mindstream-load-session)
    mindstream-map))

(defun mindstream--commit ()
  "Commit the current state as part of iteration."
  (mindstream--execute-shell-command "git add -A && git commit -a --allow-empty-message -m ''"))

(defun mindstream--iterate ()
  "Write scratch buffer to disk and increment the version.

This assumes that the scratch buffer is the current buffer, so
it should typically be run using `with-current-buffer`."
  (let ((anonymous (mindstream-anonymous-scratch-buffer-p)))
    ;; writing the file changes the buffer name to the filename,
    ;; so we restore the original buffer name
    (when anonymous
      (rename-buffer mindstream-anonymous-buffer-name))
    (mindstream--commit)))

(defun mindstream--end-anonymous-session ()
  "End the current anonymous session.

This always affects the current anonymous session and does not affect
a named session that you may happen to be visiting."
  (let ((buf (mindstream--get-anonymous-scratch-buffer)))
    (when buf
      (with-current-buffer buf
        ;; first write the existing scratch buffer
        ;; if there are unsaved changes
        (mindstream--iterate)
        ;; then kill it
        (kill-buffer)))))

(defun mindstream--new (template)
  "Start a new scratch buffer using a specific TEMPLATE.

This also begins a new session."
  ;; end the current anonymous session
  (mindstream--end-anonymous-session)
  ;; start a new session (sessions always start anonymous)
  (let ((buf (mindstream-start-session template)))
    ;; (ab initio) iterate
    (with-current-buffer buf
      (mindstream-mode 1)
      (mindstream--iterate))
    buf))

(defun mindstream-new (template)
  "Start a new scratch buffer using a specific TEMPLATE.

This also begins a new session."
  (interactive (list (read-file-name "Which template? " mindstream-template-path)))
  (let ((buf (mindstream--new template)))
    (switch-to-buffer buf)))

(defun mindstream-clear ()
  "Start a new scratch buffer using a specific template."
  (interactive)
  (unless mindstream-mode
    (error "Not a mindstream buffer!"))
  ;; first write the existing scratch buffer
  ;; if there are unsaved changes
  (mindstream--iterate)
  ;; clear the buffer
  (erase-buffer)
  ;; if the buffer was originally created using a template,
  ;; then insert the template contents
  (when mindstream-template-used
    (insert (mindstream--file-contents mindstream-template-used)))
  ;; write the fresh state
  (mindstream--iterate))

;;;###autoload
(defun mindstream-initialize ()
  "Advise any functions that should implicitly cause the scratch buffer to iterate."
  (dolist (fn mindstream-triggers)
    (advice-add fn :around #'mindstream-implicitly-iterate-advice)))

(defun mindstream-disable ()
  "Remove any advice for racket scratch buffers."
  (dolist (fn mindstream-triggers)
    (advice-remove fn #'mindstream-implicitly-iterate-advice)))

(defun mindstream-implicitly-iterate-advice (orig-fn &rest args)
  "Implicitly iterate the scratch buffer upon execution of some command.

This only iterates the buffer if it is the current buffer and has been
modified since the last persistent state.  Otherwise, it takes no
action.

ORIG-FN is the original function invoked, and ARGS are the arguments
in that invocation."
  (let ((result (apply orig-fn args)))
    (when (and mindstream-mode
               (magit-anything-modified-p))
      (mindstream--iterate))
    result))

(defun mindstream-save-file (filename)
  "Save the current scratch buffer to a file.

This is for interactive use only, for saving the file to a persistent
location of your choice (i.e. FILENAME).  To just save the file to its
existing (tmp) location, use a low-level utility like `save-buffer` or
`write-file` directly."
  (interactive (list (read-file-name "Save file as: " mindstream-save-file-path "")))
  (unless mindstream-mode
    (error "Not a mindstream buffer!"))
  (save-buffer)  ; ensure it saves any WIP
  (write-file filename)
  (mindstream-mode -1))

(defun mindstream--session-name ()
  "Name of the current session.

This is simply the name of the containing folder."
  (string-trim-left
   (directory-file-name
    (file-name-directory (buffer-file-name)))
   "^.*/"))

(defun mindstream-save-session (dest-dir)
  "Save the current scratch session to a directory.

If DEST-DIR is a non-existent path, it will be used as the name of a
new directory that will contain the session.  If it is an existing
path, then the session will be saved at that path using its current
(e.g. randomly generated) name as the name of the saved session folder.

It is advisable to use a descriptive name when saving a session, i.e.
you would typically want to specify a new, non-existent folder."
  (interactive (list (read-directory-name "Save session in: " mindstream-save-session-path)))
  (unless mindstream-mode
    (error "Not a mindstream buffer!"))
  (save-buffer) ; ensure it saves any WIP
  ;; The chosen name of the directory becomes the name of the session.
  (let ((original-session-name (mindstream--session-name))
        (named (not (file-directory-p dest-dir))))
    ;; ensure no unsaved changes
    ;; note: this is a no-op if save-buffer is a trigger for iteration
    (mindstream--iterate)
    ;; TODO: verify behavior with existing vs non-existent containing folder
    (copy-directory (file-name-directory (buffer-file-name))
                    dest-dir)
    (mindstream--end-anonymous-session)
    (if named
        (mindstream-load-session dest-dir)
      (mindstream-load-session (concat dest-dir original-session-name)))))

(defun mindstream-load-session (filename)
  "Load a session from a directory.

FILENAME is the directory containing the session."
  (interactive (list (read-file-name "Load session: " mindstream-save-session-path)))
  ;; restore the old session
  (find-file filename)
  (mindstream-mode 1))

(defun mindstream--get-or-create-scratch-buffer ()
  "Get the active scratch buffer or create a new one.

If the scratch buffer doesn't exist, this creates a new one using
the default configured template.

This is a convenience utility for \"read only\" cases where we simply
want to get the scratch buffer - whatever it may be. It is too
connoted to be useful in features implementing the scratch buffer
iteration model."
  (or (mindstream--get-anonymous-scratch-buffer)
      (mindstream--new mindstream-default-template)))

(defun mindstream-switch-to-scratch-buffer ()
  "Switch to the anonymous scratch buffer."
  (interactive)
  (let ((buf (mindstream--get-or-create-scratch-buffer)))
    (switch-to-buffer buf)))

(provide 'mindstream)
;;; mindstream.el ends here
