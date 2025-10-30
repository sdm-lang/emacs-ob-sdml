;;; ob-sdml.el --- Org-Babel for SDML -*- lexical-binding: t; -*-

;; Author: Simon Johnston <johnstonskj@gmail.com>
;; Version: 0.1.5
;; Package-Requires: ((emacs "28.2") (org "9.5.5") (sdml-mode "0.1.8"))
;; URL: https://github.com/johnstonskj/emacs-sdml-mode
;; Keywords: languages tools

;;; License:

;; Copyright (c) 2023, 2024 Simon Johnston
;;
;; Licensed under the Apache License, Version 2.0 (the "License");
;; you may not use this file except in compliance with the License.
;; You may obtain a copy of the License at
;;
;;     http://www.apache.org/licenses/LICENSE-2.0
;;
;; Unless required by applicable law or agreed to in writing, software
;; distributed under the License is distributed on an "AS IS" BASIS,
;; WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;; See the License for the specific language governing permissions and
;; limitations under the License.

;; Copyright 2023-2025 Simon Johnston <johnstonskj@gmail.com>
;; 
;; Permission is hereby granted, free of charge, to any person obtaining a copy
;; of this software and associated documentation files (the “Software”), to deal
;; in the Software without restriction, including without limitation the rights to
;; use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
;; the Software, and to permit persons to whom the Software is furnished to do so,
;; subject to the following conditions:
;; 
;; The above copyright notice and this permission notice shall be included in all
;; copies or substantial portions of the Software.
;; 
;; THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
;; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A
;; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
;; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
;; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
;; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

;;; Commentary:

;; Provides Org-Babel integration for SDML source blocks.  This relies on the
;; command-line tool `sdml' (https://github.com/johnstonskj/rust-sdml) to
;; run checkers, diagram generators, and conversion tools.
;;

;; Install
;;
;; Install is easiest from MELPA, here's how with `use-package`. Note the hook clause
;; to ensure this minor mode is always enabled for SDML source files.
;;
;; `(use-package ob-sdml
;;   :after (ob sdml-mode)
;;   :init (ob-sdml-setup))'
;;
;; Or, interactively; `M-x package-install RET ob-sdml RET' and then
;; run `M-x ob-sdml-setup RET' to add SDML to the Babel list of languages.
;;
;; You will also need to install the SDML command-line tool to execute commands
;; against source blocks.

;; Usage
;;
;; The following header arguments are specifically used on source blocks:
;;
;; `:cmd' -- optional, the name or path to the command-line tool.  Default is "sdml".
;; `:cmdline' -- required, denotes the action to perform.
;; `:file' -- required, the file to output results to.
;;
;; Examples
;;
;; #+BEGIN_SRC sdml :cmdline draw --diagram concepts :file diagram.svg
;;
;;
;; #+BEGIN_SRC sdml :cmdline draw --diagram concepts --output-format source :file diagram.dot
;;

;;; Code:

(require 'org)
(require 'ob)

(if (>= (string-to-number emacs-version) 29)
    (require 'sdml-ts-mode)
  (require 'sdml-mode))

(require 'sdml-mode-cli)

(defcustom ob-sdml-no-color nil
  "Disable color output from the `sdml-mode-cli-name' command."
  :tag "Org Babel SDML color switch"
  :type `(choice (const :tag "Default" ,nil)
                 (const :tag "No Color" t))
  :group 'org-babel)

(defvar org-babel-default-header-args:sdml
  '((:results . "file")
    (:exports . "results"))
  "Default arguments to use when evaluating a SDML source block.")

;; Following required naming convention
(defun ob-sdml-expand-body (body params)
  "Expand BODY according to PARAMS, return the expanded body."
  (let ((vars (org-babel--get-vars params)))
    (mapc
     (lambda (pair)
       (let ((name (symbol-name (car pair)))
             (value (cdr pair)))
	 (setq body
	       (replace-regexp-in-string
		(concat "$" (regexp-quote name))
		(if (stringp value) value (format "%S" value))
		body
		t
		t))))
     vars)
    body))

(defun org-babel-execute:sdml (body params)
  "Execute a block of SDML code with org-babel.
The code to process is in BODY, the block parameters are in PARAMS.
This function is called by `org-babel-execute-src-block'.

Note that this uses the variables `sdml-mode-cli-name' and
`sdml-mode-cli-log-filter' in constructing the command-line to execute."
  (let* ((out-file (cdr (or (assoc :file params)
			                (error "You need to specify a :file parameter"))))
         (cmd (or (cdr (assoc :cmd params)) sdml-mode-cli-name))
	     (cmdline (cdr (assoc :cmdline params)))
         (output-format (if (and (string-prefix-p "draw" cmdline)
                                 (not (string-search "--output-format" cmdline)))
                            (format " --output-format %s" (file-name-extension out-file))
                          ""))
	     (coding-system-for-read 'utf-8) ; use utf-8 with sub-processes
	     (coding-system-for-write 'utf-8)
	     (in-file (org-babel-temp-file (format "%s-" sdml-mode-cli-name))))
    (let ((expanded-source (ob-sdml-expand-body body params)))
      (with-temp-file in-file
        (insert expanded-source)))
    (let ((full-cmd-string (concat cmd
                                   (format " --log-filter %s" (symbol-name sdml-mode-cli-log-filter))
         	                       " " cmdline
                                   output-format
	                               " --output " (org-babel-process-file-name out-file)
                                   " --input " (org-babel-process-file-name in-file))))
      (message full-cmd-string)
      (org-babel-eval full-cmd-string ""))
    ;; signal that output has already been written to file
    nil))

(defun org-babel-prep-session:sdml (_session _params)
  "Return an error because sdml does not support sessions."
  (error "SDML does not support sessions"))

;;;###autoload
(defun ob-sdml-setup ()
  "Set up SDML language mapping for Org-Babel."
  (interactive)
  (message "Adding sdml to org-babel-load-languages")
  (add-to-list 'org-babel-load-languages '(sdml . t)))

(provide 'ob-sdml)

;;; ob-sdml.el ends here
