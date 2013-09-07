;;; php-extras-gen-eldoc.el --- Extra features for `php-mode'

;; Copyright (C) 2012, 2013 Arne Jørgensen

;; Author: Arne Jørgensen <arne@arnested.dk>

;; This software is free software: you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation, either version 3 of the
;; License, or (at your option) any later version.

;; This software is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this software.  If not, see
;; <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Download and parse PHP manual from php.net and build a new
;; `php-extras-function-arguments' hash table of PHP functions and
;; their arguments.

;; Please note that build a new `php-extras-function-arguments' is a
;; slow process and might be error prone.

;;; Code:

(require 'php-extras)



(defvar php-extras-php-funcsummary-url "http://svn.php.net/repository/phpdoc/doc-base/trunk/funcsummary.txt"
  "URL of the PHP funcsummary.txt file.")



;;;###autoload
(defun php-extras-generate-eldoc ()
  "Regenerate PHP function argument hash table from php.net. This is slow!"
  (interactive)
  (when (yes-or-no-p "Regenerate PHP function argument hash table from php.net. This is slow! ")
    (php-extras-generate-eldoc-1 t)))

(defun php-extras-generate-eldoc-1 (&optional byte-compile)
  "Regenerate PHP function argument hash table from php.net. This is slow!"
  (save-excursion
    (let ((php-extras-function-arguments (make-hash-table
                                          :size 8400
                                          :rehash-threshold 1.0
                                          :rehash-size 1.1
                                          :test 'equal))
          (methodname nil)
          (help-string ""))
      (with-temp-buffer (url-insert-file-contents php-extras-php-funcsummary-url)
                        (goto-char (point-min))
                        (while (re-search-forward "^[^(]* \\([^(]+\\)(.*)
 +.*" nil t)
                          (setq methodname (match-string-no-properties 1))
                          (message "Parsing %s..." methodname)
                          (setq help-string (replace-regexp-in-string "[ \t]+" " " (replace-regexp-in-string "
" " - " (match-string-no-properties 0))))
                          (puthash methodname help-string php-extras-function-arguments)))
      (let* ((file (concat php-extras-eldoc-functions-file ".el"))
             (buf (find-file file)))
        (with-current-buffer buf
          (widen)
          (kill-region (point-min) (point-max))
          (insert (format 
                   ";;; %s.el -- file auto generated by `php-extras-generate-eldoc'

(require 'php-extras)

(setq php-extras-function-arguments %s)

(provide 'php-extras-eldoc-functions)

;;; %s.el ends here
"
          (file-name-nondirectory php-extras-eldoc-functions-file)
          (prin1-to-string php-extras-function-arguments)
          (file-name-nondirectory php-extras-eldoc-functions-file)))
          (save-buffer)
          (when byte-compile
            (byte-compile-file file t)))))))



(provide 'php-extras-gen-eldoc)

;;; php-extras-gen-eldoc.el ends here
