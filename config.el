;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

(setq user-full-name "Mason Fox"
      user-mail-address "masonfox22@gmail.com")

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; (setq user-full-name "John Doe"
;;       user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-symbol-font' -- for symbols
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:
;;
;; Complete font configuration
(setq doom-font (font-spec :family "JetBrains Mono" :size 14 :weight 'regular)
      doom-variable-pitch-font (font-spec :family "JetBrains Mono" :size 14)
      doom-big-font (font-spec :family "JetBrains Mono" :size 20)
      doom-serif-font (font-spec :family "JetBrains Mono" :size 14 :weight 'light))

;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default: .
(setq doom-gruvbox-dark-variant nil)
(setq doom-theme 'doom-gruvbox)

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/notes")
                                        ;
;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;;;;;;;;;;;;;;;;;;;;;;;;
;; PERSONAL FUNCTIONS ;;
;;;;;;;;;;;;;;;;;;;;;;;;

;; This fixes an issue where 'SPC-/' searches the CWD.
;; However, I want it to search the entire org-roam directory
;; See ORG-ROAM CONFIG for key binding override
(defun mason/search-org-roam ()
  "Search across all org-roam notes"
  (interactive)
  (let ((default-directory (expand-file-name org-roam-directory)))
    (consult-ripgrep default-directory)))


;; Async git commits for the notes repo
;; Commits run in the background, one at a time, so saving never blocks Emacs
;; and queued commits don't fight over git's index lock.
(defvar mason/notes-git--queue nil
  "Pending (FILES . MESSAGE) commits for the notes repo.")
(defvar mason/notes-git--running nil
  "Non-nil while a notes git commit is in progress.")

(defun mason/notes-file-p (file)
  "Return non-nil if FILE is inside `org-roam-directory'."
  (string-prefix-p (file-name-as-directory (expand-file-name org-roam-directory))
                   (expand-file-name file)))

(defun mason/notes-git-commit (files message)
  "Stage FILES in the notes repo and commit them with MESSAGE, asynchronously.
Only FILES are staged and committed; nothing else in the repo is touched."
  (setq mason/notes-git--queue
        (append mason/notes-git--queue (list (cons files message))))
  (mason/notes-git--run-next))

(defun mason/notes-git--run-next ()
  "Start the next queued notes commit, unless one is already running."
  (when (and mason/notes-git--queue (not mason/notes-git--running))
    (let* ((job (pop mason/notes-git--queue))
           (message-text (cdr job))
           (default-directory (file-name-as-directory (expand-file-name org-roam-directory)))
           (paths (mapcar (lambda (f) (file-relative-name (expand-file-name f) default-directory))
                          (car job)))
           (buf (get-buffer-create " *notes-git*")))
      (with-current-buffer buf (erase-buffer))
      (setq mason/notes-git--running t)
      (make-process
       :name "notes-git"
       :buffer buf
       ;; $0 is the message, $@ the paths. Drop paths that neither exist nor
       ;; are tracked (git rejects them), and skip the commit if nothing changed.
       :command `("sh" "-c"
                  ,(concat "for p; do shift; "
                           "if [ -e \"$p\" ] || git ls-files --error-unmatch -- \"$p\" >/dev/null 2>&1; "
                           "then set -- \"$@\" \"$p\"; fi; done; "
                           "[ $# -eq 0 ] && exit 0; "
                           "git add -A -- \"$@\" && "
                           "{ git diff --cached --quiet -- \"$@\" || git commit -q -m \"$0\" -- \"$@\"; }")
                  ,message-text ,@paths)
       :sentinel (lambda (proc _event)
                   (unless (process-live-p proc)
                     (setq mason/notes-git--running nil)
                     (if (zerop (process-exit-status proc))
                         (message "Git commit success — %s" message-text)
                       (message "Git commit failed — %s (see the \" *notes-git*\" buffer)" message-text))
                     (mason/notes-git--run-next)))))))


;; Get around annoying orf-roam-node-insert oddities
(defun mason/org-roam-node-insert-old ()
  "Insert an Org-roam node without unwanted leading or trailing spaces,
place point after the link, and re-enter insert mode."
  (interactive)
  (let ((start (point)))
    (org-roam-node-insert)
    ;; Find the link that was just inserted and check for leading space
    (save-excursion
      (goto-char start)
      ;; Search for the [[ that starts the link
      (when (search-forward "[[" nil t)
        (goto-char (match-beginning 0))
        ;; Check if there's a space before it
        (when (and (> (point) (point-min))
                   (= (char-before) ?\s))
          (delete-char -1))))
    ;; Move point to end of the inserted link
    (when (org-in-regexp org-link-bracket-re 1)
      (goto-char (match-end 0)))
    ;; Back to insert mode
    (when (bound-and-true-p evil-mode)
      (evil-insert 1))))


;; Cleans up whitespace on org-roam insert and also returns to insert mode - maintain flow.
(defun mason/org-roam-node-insert ()
  "Insert an Org-roam node without unwanted leading or trailing spaces,
place point after the link, and re-enter insert mode."
  (interactive)
  (let* ((buf (current-buffer))
         (start (point-marker))
         (tick (buffer-chars-modified-tick))
         (returned nil)
         (cleanup-fn nil)
         ;; Remove the space before the link inserted at START, move past
         ;; the link, and re-enter insert mode
         (finish
          (lambda ()
            (with-current-buffer buf
              (goto-char start)
              (when (search-forward "[[" nil t)
                (goto-char (match-beginning 0))
                (when (eq (char-before) ?\s)
                  (delete-char -1))
                (when (org-in-regexp org-link-bracket-re 1)
                  (goto-char (match-end 0))))
              (when (bound-and-true-p evil-mode)
                (evil-insert 1))))))

    ;; New nodes: org-roam inserts the link once the capture is finalized
    (setq cleanup-fn
          (lambda ()
            (remove-hook 'org-capture-after-finalize-hook cleanup-fn)
            (unless (bound-and-true-p org-note-abort)
              (funcall finish))))
    (add-hook 'org-capture-after-finalize-hook cleanup-fn)

    (unwind-protect
        (progn (org-roam-node-insert)
               (setq returned t))
      ;; Prompt cancelled - no capture will ever finalize
      (unless returned
        (remove-hook 'org-capture-after-finalize-hook cleanup-fn)))

    ;; Existing nodes: the link is already in, so clean up now and drop the
    ;; hook, otherwise it would fire on some unrelated capture later
    (unless (= tick (buffer-chars-modified-tick buf))
      (remove-hook 'org-capture-after-finalize-hook cleanup-fn)
      (funcall finish))))


;; This removes the generated UUID from journal entries.
;; My template otherwise insert it's own in a yyyy-mm-dd format, which I prefer.
(defun mason/org-roam-dailies-remove-duplicate-id ()
  "Remove the first auto-generated ID if there's a custom ID below it."
  (save-excursion
    (goto-char (point-min))
    (let ((first-id-end nil)
          (second-id-start nil))
      ;; Find the first properties drawer
      (when (re-search-forward "^:PROPERTIES:" nil t)
        (let ((first-start (match-beginning 0)))
          (when (re-search-forward "^:END:" nil t)
            (setq first-id-end (match-end 0))
            ;; Look for a second properties drawer
            (when (re-search-forward "^:PROPERTIES:" nil t)
              (setq second-id-start (match-beginning 0))
              ;; Delete from start of file to end of first drawer
              (delete-region (point-min) (1+ first-id-end))))))
      ;; Clean up any extra blank lines at the top
      (goto-char (point-min))
      (while (looking-at "^$")
        (delete-char 1)))))

;; attach the function above to the org-roam hook for journal file creation
(add-hook 'org-roam-dailies-find-file-hook 'mason/org-roam-dailies-remove-duplicate-id)


;; Follows node in parent file header or inserts one
(defun mason/org-roam-goto-or-insert-parent ()
 "Go to parent node if #+parent exists, otherwise insert one using org-roam."
  (interactive)
  (goto-char (point-min))
  (cond
   ;; Case 1: Parent link already exists - follow it
   ((re-search-forward "^#\\+parent:\\s-*\\[\\[id:\\([^]]+\\)\\]" nil t)
    (let ((parent-id (match-string 1)))
      (org-roam-id-open parent-id nil)))

   ;; Case 2: Empty #+parent: line exists - fill it in
   ((re-search-forward "^#\\+parent:" nil t)
    ;; Check if there's already a link on this line
    (let ((line-end (line-end-position)))
      (if (re-search-forward "\\[\\[id:" line-end t)
          ;; There's already a link, do nothing
          (message "Parent link already exists")
        ;; No link yet, insert one
        (end-of-line)
        ;; Use org-roam-node-insert with template "m" for new nodes
        (let ((org-roam-capture-templates
               (list (assoc "m" org-roam-capture-templates))))
          (org-roam-node-insert nil))
        (save-buffer))))

   ;; No match
   (t
    (message "No #+parent: line found!"))))


;; Move file functionality - keeps DB in sync
(defun mason/org-roam-move-file ()
 "Move an org-roam file to a different folder, keeping the same filename."
  (interactive)
  (let* ((file (or (buffer-file-name)
                   (read-file-name "Select file to move: ")))
         (filename (file-name-nondirectory file))
         (target-dir (read-directory-name "Move to folder: "
                                          (file-name-as-directory org-roam-directory)))
         (new-path (expand-file-name filename target-dir)))
    ;; Ensure we're not "moving" to the same location
    (if (string= (expand-file-name file) (expand-file-name new-path))
        (message "File not moved - same location")
      ;; Perform the move
      (rename-file file new-path 1)
      ;; Update the current buffer if we were visiting the file
      (when (and (buffer-file-name)
                 (string= (expand-file-name (buffer-file-name))
                         (expand-file-name file)))
        (set-visited-file-name new-path t t)
        (set-buffer-modified-p nil))
      ;; org-roam-db-autosync-mode updates the DB for the rename
      (message "File moved to: %s" new-path))))


;; Automatically move files based on tags on save
(defun mason/org-roam-auto-organize-by-tag ()
  "Automatically move org-roam file to appropriate directory based on tags."
  (when (and (buffer-file-name)
             (derived-mode-p 'org-mode)
             (boundp 'org-roam-directory)
             org-roam-directory
             (stringp org-roam-directory)
             (file-exists-p org-roam-directory))
    (condition-case err
        (let* ((current-file (buffer-file-name))
               (tags (condition-case nil
                         (org-get-tags)
                       (error '())))
               (filename (file-name-nondirectory current-file))
               (current-dir (file-name-directory current-file))
               (templates-dir (expand-file-name "support/templates/" org-roam-directory))
               (target-dir nil))

          ;; Only proceed if we're in org-roam-directory and not in templates
          (when (string-prefix-p (expand-file-name org-roam-directory)
                                (expand-file-name current-file))
            ;; Skip if file is in templates directory
            (unless (string-prefix-p templates-dir current-file)
              ;; Determine target directory based on tag combinations
              (cond
               ;; :zettel: only (not fleeting) -> /permanent
               ((and (member "zettel" tags)
                     (not (member "fleeting" tags)))
                (setq target-dir (expand-file-name "permanent/" org-roam-directory)))

               ;; :literature: only (not fleeting, not book) -> /literature
               ((and (member "literature" tags)
                     (not (member "fleeting" tags))
                     (not (member "book" tags)))
                (setq target-dir (expand-file-name "literature/" org-roam-directory)))

               ;; :zettel:fleeting: or :literature:fleeting: -> stay in /fleeting
               ;; (no action needed, these are already filed correctly by template)
               )

              ;; Move file if target directory is different from current
              (when (and target-dir
                         (not (string= (file-name-as-directory current-dir)
                                      (file-name-as-directory target-dir))))
                ;; Create directory if it doesn't exist
                (unless (file-exists-p target-dir)
                  (make-directory target-dir t))

                (let ((new-path (expand-file-name filename target-dir)))
                  ;; Move the file (org-roam-db-autosync-mode updates the DB)
                  (rename-file current-file new-path 1)
                  ;; Update buffer
                  (set-visited-file-name new-path t t)
                  (set-buffer-modified-p nil)
                  ;; Git commit the move: stage removal of old path and addition of new
                  (mason/notes-git-commit
                   (list current-file new-path)
                   (format "#desktop: MOVE %s → %s"
                           (file-relative-name current-file org-roam-directory)
                           (file-relative-name new-path org-roam-directory)))
                  (message "File - %s - moved to %s - based on tags (committed)" filename target-dir))))))
      (error nil))))  ; Silently ignore any errors

;; Hook it up to run after saving
(add-hook 'after-save-hook #'mason/org-roam-auto-organize-by-tag)


;; Auto-commit when files are deleted
(defun mason/org-roam-auto-commit-deletion-advice (orig-fun file &optional trash)
  "Advice to automatically commit when an org-roam file is deleted."
  ;; First, actually delete the file
  (funcall orig-fun file trash)
  ;; Then commit the deletion
  (when (and (boundp 'org-roam-directory)
             org-roam-directory
             (stringp org-roam-directory)
             (file-exists-p org-roam-directory)
             (string-suffix-p ".org" file))
    (condition-case err
        (let ((relative-path (file-relative-name file org-roam-directory)))
          ;; Only proceed if we're in org-roam-directory
          (when (string-prefix-p (expand-file-name org-roam-directory)
                                (expand-file-name file))
            ;; org-roam-db-autosync-mode removes the file from the DB
            (mason/notes-git-commit (list (expand-file-name file))
                                    (format "#desktop: DELETE %s" relative-path))))
      (error nil))))  ; Silently ignore any errors

;; Advise delete-file to auto-commit after deletion
(advice-add 'delete-file :around #'mason/org-roam-auto-commit-deletion-advice)


;; Opens a random journal note
(defun mason/open-random-journal-note ()
  "Open a random org-roam note from the journal directory."
  (interactive)
  (let* ((journal-dir (expand-file-name "journal" org-roam-directory))
         (journal-files (directory-files journal-dir t "\\.org$"))
         (random-file (when journal-files
                        (nth (random (length journal-files)) journal-files))))
    (if random-file
        (progn
          (find-file random-file)
          (goto-char (point-min)))
      (message "No journal files found in %s" journal-dir))))


;; auto git commit files
(defun mason/org-roam-auto-commit (&optional file)
  "Auto-commit FILE (default: the current buffer's file) in the notes repo."
  (let ((file (or file buffer-file-name)))
    (when (and file (mason/notes-file-p file))
      (mason/notes-git-commit
       (list file)
       (format "#desktop: UPDATE %s - %s"
               (file-name-nondirectory file)
               (format-time-string "%Y-%m-%d %I:%M %p"))))))

;; Only commit on regular saves (not during capture buffers)
(defun mason/org-roam-auto-commit-on-save ()
  "Auto-commit, but skip if we're in a capture buffer."
  (unless (bound-and-true-p org-capture-mode)
    (mason/org-roam-auto-commit)))

;; Register for regular saves (but skip captures). Depth 90 runs this after
;; the tag-based auto-organize, so a moved file is committed once, as a MOVE.
(add-hook 'after-save-hook #'mason/org-roam-auto-commit-on-save 90)

;; Commit the captured file once capture is finalized. Capture buffers are
;; indirect buffers with no file name, so remember the target file beforehand.
(defvar mason/org-capture--file nil
  "File targeted by the capture currently being finalized.")

(defun mason/org-capture-remember-file-h ()
  (setq mason/org-capture--file (buffer-file-name (buffer-base-buffer))))

(defun mason/org-roam-auto-commit-after-capture-h ()
  (unless (bound-and-true-p org-note-abort)
    (when mason/org-capture--file
      (mason/org-roam-auto-commit mason/org-capture--file)))
  (setq mason/org-capture--file nil))

(add-hook 'org-capture-prepare-finalize-hook #'mason/org-capture-remember-file-h)
(add-hook 'org-capture-after-finalize-hook #'mason/org-roam-auto-commit-after-capture-h)

;; go to the top of the buffer. great to use with :after
;; see org-roam config you advice-add declarations
(defun mason/goto-buffer-top (&rest _)
  "Move to top of buffer."
  (goto-char (point-min)))

;;;;;;;;;;;;;;;;;;;
;; GLOBAL CONFIG ;;
;;;;;;;;;;;;;;;;;;;

;; Override buffer kill selection to current buffer
(global-set-key (kbd "C-x k") 'kill-current-buffer)

;; Since 'C-x k' allows your to kill the current buffer
;; Map 'C-x K' (upper) to ibuffer, allowing you to kill MANY buffers
(global-set-key (kbd "C-x K") 'ibuffer)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ORG-ROAM CONFIGURATION ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Set directory at top level so commands bound below (e.g. 'SPC /', 'SPC j r')
;; work before org-roam is lazily loaded
(setq org-roam-directory "~/notes"
      org-roam-dailies-directory "journal/")

;; Moves and deletions rely on org-roam-db-autosync-mode to keep the DB current.
;; Doom enables it when org loads; this runs afterwards (depth 90) as a fallback.
(add-hook 'org-load-hook
          (defun mason/ensure-org-roam-autosync-h ()
            (unless (bound-and-true-p org-roam-db-autosync-mode)
              (org-roam-db-autosync-mode +1)))
          90)

(after! org-roam
  (setq org-roam-completion-everywhere t)

  ;; set DB connector and location
  (setq org-roam-db-location (expand-file-name "org-roam.db" (expand-file-name "support" org-roam-directory)))
  (setq org-roam-database-connector 'sqlite)

  ;; set journal template
  (setq org-roam-dailies-capture-templates
      '(("d" "default" entry
         "* "
         :target (file+head "%<%Y-%m-%d>.org"
                            ":PROPERTIES:\n:ID: %<%Y-%m-%d>\n:END:\n#+title: %<%B, %d %Y (%a)>\n#+filetags: :journal:daily:\n\n* "))))

;; set note capture templates
;; set note type variable
  (setq mason/org-roam-filename "${slug}.org")

;; template definitions
  (setq org-roam-capture-templates
        `(("z" "zettel" plain
           (file "~/notes/support/templates/zettel.org")
           :target (file+head ,(concat "fleeting/" mason/org-roam-filename) "")
           :unnarrowed t)

          ;; lit notes default to /fleeting due to :fleeting: tag
          ("l" "literature" plain
           (file "~/notes/support/templates/literature.org")
           :target (file+head ,(concat "fleeting/" mason/org-roam-filename) "")
           :unnarrowed t)

          ("m" "moc" plain
           (file "~/notes/support/templates/moc.org")
           :target (file+head ,(concat "maps/" mason/org-roam-filename) "")
           :unnarrowed t)

          ("b" "book" plain
           (file "~/notes/support/templates/book.org")
           :target (file+head ,(concat "literature/books/" mason/org-roam-filename) "")
           :unnarrowed t)

          ("p" "person" plain
           (file "~/notes/support/templates/person.org")
           :target (file+head ,(concat "people/" mason/org-roam-filename) "")
           :unnarrowed t)))

  ;; Extend/add advice to the org-roam functions
  ;; Ensure we go to the top of the buffer on these roam-daily functions
  (advice-add 'org-roam-dailies-goto-date :after #'mason/goto-buffer-top)
  (advice-add 'org-roam-dailies-goto-yesterday :after #'mason/goto-buffer-top)
  (advice-add 'org-roam-dailies-goto-today :after #'mason/goto-buffer-top)
  (advice-add 'org-roam-dailies-goto-previous-note :after #'mason/goto-buffer-top)
  (advice-add 'org-roam-dailies-goto-next-note :after #'mason/goto-buffer-top))

;; Keybindings
;; Defined at top level (not inside `after! org-roam') so they're available
;; immediately on startup, e.g. from the dashboard. Org-roam commands are
;; autoloaded, so using one will load org-roam on demand.
(defun mason/goto-notes-home ()
  "Open the notes home file, ~/notes/root.org."
  (interactive)
  (find-file "~/notes/root.org"))

;; Note - 'n' - key bindings
(map! :leader
      (:prefix ("n" . "notes")
       :desc "Toggle Org Roam buffer"       "l" #'org-roam-buffer-toggle
       :desc "Find node"                    "f" #'org-roam-node-find
       :desc "Capture node"                 "c" #'org-roam-capture
       :desc "Insert node"                  "i" #'mason/org-roam-node-insert
       :desc "See backlinks"                "b" #'org-roam-buffer-toggle
       :desc "Move file"                    "m" #'mason/org-roam-move-file
       :desc "Goto or insert parent node"   "p" #'mason/org-roam-goto-or-insert-parent
       :desc "Go to home/root.org"          "h" #'mason/goto-notes-home
       :desc "Extract subtree to node"      "x" #'org-roam-extract-subtree))

;; set org-roam journal global entries
(map! :leader
    (:prefix ("j" . "journal")
     :desc "Open journal note by date"      "d" #'org-roam-dailies-goto-date
     :desc "Open yesterday's journal note"  "y" #'org-roam-dailies-goto-yesterday
     :desc "Open today's journal note"      "t" #'org-roam-dailies-goto-today
     :desc "Find previous journal note"     "p" #'org-roam-dailies-goto-previous-note
     :desc "Find next journal note"         "n" #'org-roam-dailies-goto-next-note
     :desc "Open random journal note"       "r" #'mason/open-random-journal-note))

;; Override 'SPC-/' to search all org-roam-directory notes
(map! :leader
      :desc "Search all org-roam notes"
      "/" #'mason/search-org-roam)

;; Quick access to magit/git operations
(map! :leader
    (:prefix ("g" . "git")
     :desc "Git push"      "P" #'magit-push-current-to-upstream ;; uppercase
     :desc "Git pull"      "p" #'magit-pull-from-upstream))     ;; lowercase

;; toggle neotree
(map! :leader
    (:prefix ("t" . "toggle")
            :desc "Toggle neotree"      "t" #'neotree-toggle))

;; Completion key inside org-mode
(map! :after org
      :map org-mode-map
      "C-M-i" #'completion-at-point)

;; Quick node insert that works in insert mode (SPC n i only works in normal)
(map! :after org
      :map org-mode-map
      :ni "C-c i" #'mason/org-roam-node-insert)

;; Dashboard menu
;; Set the whole list rather than modifying the default: the dashboard module's
;; `defcustom' isn't loaded yet here, and it won't override a value already set.
(setq +dashboard-menu-sections
      '(("Notes home"
         :icon (nerd-icons-octicon "nf-oct-home" :face '+dashboard-menu-title)
         :action mason/goto-notes-home)
        ("Find note"
         :icon (nerd-icons-octicon "nf-oct-note" :face '+dashboard-menu-title)
         :action org-roam-node-find)
        ("Today's journal"
         :icon (nerd-icons-octicon "nf-oct-calendar" :face '+dashboard-menu-title)
         :action org-roam-dailies-goto-today)
        ("Recently opened files"
         :icon (nerd-icons-faicon "nf-fa-file_text" :face '+dashboard-menu-title)
         :action recentf-open-files)
        ("Reload last session"
         :icon (nerd-icons-octicon "nf-oct-history" :face '+dashboard-menu-title)
         :when (cond ((modulep! :ui workspaces)
                      (file-exists-p (expand-file-name persp-auto-save-fname persp-save-dir)))
                     ((require 'desktop nil t)
                      (file-exists-p (desktop-full-file-name))))
         :action doom/quickload-session)
        ("Open private configuration"
         :icon (nerd-icons-octicon "nf-oct-tools" :face '+dashboard-menu-title)
         :when (file-directory-p doom-user-dir)
         :action doom/open-private-config)))


;; Windows Clean Up
(add-to-list 'default-frame-alist '(undecorated . t))
