;;; mindstream-scratch.el --- A scratch buffer -*- lexical-binding: t -*-

;; Author: Siddhartha Kasivajhula <sid@countvajhula.com>
;; URL: https://github.com/countvajhula/mindstream
;; Version: 0.0
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

(require 'cl-lib)
(require 'mindstream-custom)
(require 'mindstream-util)

;; These are customization or config variables defined elsewhere;
;; explicitly declare them here to avoid byte compile warnings
;; TODO: handle this via an explicit configuration step
(defvar racket-repl-buffer-name)

(defvar-local mindstream-template-used nil
  "The template used (if any) in creating the current buffer.

This is a string representing a path to a file on disk.")

(defun mindstream--unique-session-name ()
  "Unique name for a scratch buffer session."
  (let ((time (current-time)))
    (concat (format-time-string "%F" time)
            "-"
            (sha1 (format "%s" time)))))

(cl-defun mindstream-start-session (&optional template)
  "Start a new anonymous session.

This creates a new directory and Git repository for the new session.
It populates the empty buffer with the contents of TEMPLATE if one is
specified.  Otherwise, it uses the configured default template.

New sessions always start anonymous."
  (let* ((session (mindstream--unique-session-name))
         (base-path (mindstream--generate-anonymous-session-path session))
         (template (or template mindstream-default-template))
         (file-extension (file-name-extension template))
         (buf (mindstream--new-buffer-from-template template))
         ;; TODO: use platform-independent path construction
         (filename (concat base-path
                           mindstream-filename
                           "."
                           file-extension)))
    (unless (file-directory-p base-path)
      (mkdir base-path t)
      (mindstream--execute-shell-command "git init" base-path)
      (with-current-buffer buf
        (write-file filename)
        (rename-buffer mindstream-anonymous-buffer-name))
      buf)))

(defun mindstream--generate-anonymous-session-path (session)
  "A path on disk to use for a newly created SESSION."
  (concat (file-name-as-directory mindstream-path)
          (file-name-as-directory session)))

(defun mindstream--ensure-templates-exist ()
  "Ensure that the templates directory exists and contains the default template."
  ;; consider alternative: an initialization function to do this the first time
  (unless (file-directory-p mindstream-template-path)
    (mkdir mindstream-template-path t))
  (let ((default-template-file (concat mindstream-template-path
                                       mindstream-default-template-name)))
    (unless (file-exists-p default-template-file)
      (let ((buf (generate-new-buffer "default-template")))
        (with-current-buffer buf
          (insert mindstream-default-template-contents)
          (write-file default-template-file))
        (kill-buffer buf)))))

(defun mindstream--file-contents (filename)
  "Get contents of FILENAME as a string."
  (with-temp-buffer
    (insert-file-contents filename)
    (buffer-string)))

(defun mindstream--initialize-buffer (major-mode-to-use)
  "Initialize a newly created buffer.

This sets the major mode and any other necessary attributes."
  (unless (eq major-mode major-mode-to-use)
    (funcall major-mode-to-use))
  (setq buffer-offer-save nil)
  ;; Ignore whatever `racket-repl-buffer-name-function' just did to
  ;; set `racket-repl-buffer-name' and give this its own REPL.
  (setq-local racket-repl-buffer-name "*scratch - Racket REPL*")
  ;; place point at the end of the buffer
  (goto-char (point-max)))

(defun mindstream--new-buffer-with-contents (contents major-mode-to-use)
  "Create a new scratch buffer containing CONTENTS.

This does not save the buffer.

As a \"scratch\" buffer, its contents will be treated as
disposable, and it will not prompt to save if it is closed or
if Emacs is exited."
  (let* ((buffer-name mindstream-anonymous-buffer-name)
         (buf (generate-new-buffer buffer-name)))
    (with-current-buffer buf
      (insert contents)
      (mindstream--initialize-buffer major-mode-to-use))
    buf))

(defun mindstream--infer-major-mode (file)
  "Infer a major mode to use based on the file extension."
  (let ((extension (file-name-extension file)))
    ;; TODO: use `auto-mode-alist` instead?
    (cond ((equal "rkt" extension) #'racket-mode)
          ((equal "txt" extension) #'text-mode)
          (t (error "Unknown template extension!")))))

(defun mindstream--new-buffer-from-template (template)
  "Create a new (unsaved) buffer from TEMPLATE."
  (mindstream--ensure-templates-exist)
  (let* ((contents (mindstream--file-contents template))
         (major-mode-to-use (mindstream--infer-major-mode template))
         (buf (mindstream--new-buffer-with-contents contents
                                                    major-mode-to-use)))
    (with-current-buffer buf
      ;; store the template used as a buffer-local variable
      ;; on the scratch buffer
      ;; and also declare/document it so we know it's a fully
      ;; qualified path
      (setq mindstream-template-used template))
    buf))

(defun mindstream--get-anonymous-scratch-buffer ()
  "Get the active scratch buffer, if it exists."
  (let ((buffer-name mindstream-anonymous-buffer-name))
    (get-buffer buffer-name)))

(defun mindstream-anonymous-scratch-buffer-p ()
  "Predicate to check if the current buffer is the anonymous scratch buffer."
  (equal mindstream-anonymous-buffer-name (buffer-name)))

(provide 'mindstream-scratch)
;;; mindstream-scratch.el ends here
