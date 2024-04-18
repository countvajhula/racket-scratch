;;; mindstream-custom.el --- Scratch buffer sessions -*- lexical-binding: t -*-

;; URL: https://github.com/countvajhula/mindstream

;; This program is "part of the world," in the sense described at
;; http://drym.org.  From your perspective, this is no different than
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
;;
;; User customizations for Mindstream
;;

;;; Code:

(require 'mindstream-util)

(defvar mindstream--user-home-directory (getenv "HOME"))

(defgroup mindstream nil
  "A scratch buffer."
  :group 'Editing)

(defcustom mindstream-path
  ;; platform-independent ~/.emacs.d/mindstream/anon
  (mindstream--joindirs user-emacs-directory
                        "mindstream"
                        "anon")
  "Directory path where anonymous mindstream sessions will be stored during development."
  :type 'string
  :group 'mindstream)

(defcustom mindstream-template-path
  ;; platform-independent ~/.emacs.d/mindstream/templates
  (mindstream--joindirs user-emacs-directory
                        "mindstream"
                        "templates")
  "Directory path where mindstream will look for templates."
  :type 'string
  :group 'mindstream)

(defcustom mindstream-save-session-path mindstream--user-home-directory
  "Default directory path for saving mindstream sessions."
  :type 'string
  :group 'mindstream)

(defcustom mindstream-triggers (list #'save-buffer)
  "Functions that, when called, should implicitly iterate the mindstream buffer."
  :type 'list
  :group 'mindstream)

(defcustom mindstream-live-delay 1.5
  "Delay in typing after which the session is iterated."
  :type 'list
  :group 'mindstream)

(defcustom mindstream-live-action nil
  "Periodic action to take while in 'live mode'."
  :type '(plist :key-type symbol
                :value-type function)
  :group 'mindstream)

(defcustom mindstream-preferred-template nil
  "The preferred template for each major mode.

In cases where you don't indicate a template (e.g.
`mindstream-enter-session`), we search the templates folder for a
template that has an extension recognizable to the major mode, and use
the first one we find.  But if you have many templates that share the
same extension, you may prefer to indicate which one is \"preferred\"
for the major mode so that it would be selected."
  :type '(plist :key-type symbol
                :value-type function)
  :group 'mindstream)

(defcustom mindstream-filename "scratch"
  "Filename to use for mindstream buffers."
  :type 'string
  :group 'mindstream)

(defcustom mindstream-anonymous-buffer-prefix "scratch"
  "The prefix to use in the name of a mindstream scratch buffer."
  :type 'string
  :group 'mindstream)

(defcustom mindstream-default-template "text.txt"
  "Default template to use for new mindstream sessions.

If no templates exist, this one will be created with the default template contents."
  :type 'string
  :group 'mindstream)

(defcustom mindstream-default-template-contents "The past is a memory, the future a dream, and now's a dance.\n"
  "Contents of the default template that is created if none exist."
  :type 'string
  :group 'mindstream)

(provide 'mindstream-custom)
;;; mindstream-custom.el ends here
