;;; read-library.el --- read library from minibuffer with completion

;; Author: Gareth Rees <gareth.rees@pobox.com>
;; Version: 0.2
;; Time-stamp: <2000-03-15T11:37:46>
;; Copyright (c) 2000 Gareth Rees

;;; Licence:

;; This file is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the
;; Free Software Foundation; either version 2, or (at your option) any
;; later version.
;;
;; This file is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;;; Commentary:

;; The function `read-library' reads a loadable library name from the
;; minibuffer with completion.  Because it may take a long time to
;; search all of `load-path' to find the loadable libraries, the list is
;; cached and is only refreshed when `load-path' changes.  Note that
;; this means that newly added files on a directory on `load-path' won't
;; be noticed.
;;
;; The function `read-library-load' has the same interface and
;; functionality as `load-library' except that it reads with completion.

;;; Usage:

;; Put the following in your .emacs:
;;
;;   (autoload 'read-library-load "read-library" nil t)
;;
;; and then run the command `read-library-load' to load a library with
;; completion.  If you like this so much that you think it should be the
;; default behaviour, you can do
;;
;;   (fset 'load-library 'read-library-load)

;;; Code:

(require 'cl)

(defun read-library-all-libraries ()
  "Return a list of all libraries on `load-path'.
File extensions .el and .elc are removed.
The list may contain duplicates."
  (sort (loop for dir in load-path
              nconc (loop for file in (directory-files dir nil "\\.el\\'" t)
                          collect (subseq file 0 -3))
              nconc (loop for file in (directory-files dir nil "\\.elc\\'" t)
                          collect (subseq file 0 -4)))
        #'string<))

(defun read-library-alist ()
  "Return an alist whose cars are all Emacs Lisp libraries on `load-path'."
  (let* ((libraries (read-library-all-libraries)))
    ;; Remove duplicates and make into a alist for `completing-read'.
    (loop for l on libraries
          for n from 0
          if (or (endp (cdr l))
                 (not (string= (car l) (cadr l))))
          collect (cons (car l) n))))

(defvar read-library-cache nil
  "Cache of the result of `read-library-alist'.")

(defvar read-library-load-path-cache nil
  "Copy of `load-path' when `read-library-cache' was last stored.
This allows to detect changes to `load-path' that mean that
`read-library-cache' must be updated.")

(defvar read-library-history nil
  "Minibuffer history for `read-library'.")

;;;###autoload
(defun read-library (prompt &optional default)
  "Read name of library from minibuffer with completion; return as a string.
Prompts with PROMPT.  Optional second argument DEFAULT is value to
return if users enters an empty line."
  ;; Reading all the directories in `load-path' takes a while
  (when (or (null read-library-cache)
            (not (equal load-path read-library-load-path-cache)))
    (setq read-library-load-path-cache (copy-list load-path))
    (setq read-library-cache (read-library-alist)))
  (completing-read prompt read-library-cache nil t nil 'read-library-history
                   default))

;;;###autoload
(defun read-library-load (library)
  "Load the library named LIBRARY.
This is an interface to the function `load'.
When called interactively, prompt with completion."
  (interactive (list (read-library "Load library: ")))
  (load library))

(provide 'read-library)

;;; read-library.el ends here
