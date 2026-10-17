;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Appearance

(setq
  catppuccin-flavor '@flavor@
  display-line-numbers-type 'relative
  doom-font (font-spec :family "@codeFontName@" :size @codeFontSize@)
  doom-theme 'catppuccin
  ;; doom-variable-pitch-font (font-spec :family "@codeFontName@" :size @codeFontSize@)
  global-display-fill-column-indicator-mode 1
  which-key-idle-delay 0.0
  )

;; Override parts of theme.
@paletteOverrides@

;; Theme background opacity.
(add-to-list
  'default-frame-alist
  '(alpha-background . @codeBackgroundOpacity@)
  )

;; Override some faces.
(custom-set-faces!
  ;; Using a different font messes with fill-column-indicator alignment.
  '(font-lock-comment-face :family "@codeFontName@" :foreground "@colourComment@" :size @codeFontSize@ :slant italic)
  '(line-number :foreground "@colourLineNumber@")
  '(line-number-current-line :foreground "@colourLineNumberCurrent@")
  )

;; Keep Eldoc type information, but show diagnostics only in popups and lists.
(add-hook 'flymake-mode-hook
          (lambda ()
            (remove-hook 'eldoc-documentation-functions
                         #'flymake-eldoc-function t)))

(after! flymake
  (defvar my/flymake-hidden-projects nil)

  (defun my/flymake-show-project-diagnostics (&rest _)
    (when-let* ((project (and buffer-file-name flymake-mode (project-current)))
                ((not (member (project-root project) my/flymake-hidden-projects)))
                (active-project
                 (with-current-buffer (window-buffer (selected-window))
                   (project-current)))
                ((equal (project-root project) (project-root active-project)))
                ((flymake--project-diagnostics project)))
      (save-selected-window
        (flymake-show-project-diagnostics))))
  (advice-add 'flymake--handle-report :after
              #'my/flymake-show-project-diagnostics)

  (defun my/flymake-toggle-project-diagnostics ()
    (interactive)
    (let* ((root (project-root (project-current t)))
           (window (get-buffer-window (flymake--project-diagnostics-buffer root))))
      (if window
          (progn
            (cl-pushnew root my/flymake-hidden-projects :test #'equal)
            (quit-window nil window))
        (setq my/flymake-hidden-projects
              (delete root my/flymake-hidden-projects))
        (save-selected-window
          (flymake-show-project-diagnostics)))))

  (map! :leader :desc "Toggle project diagnostics"
        "c x" #'my/flymake-toggle-project-diagnostics))

(use-package! persp-mode-tab-bar
  :after persp-mode
  :config
  (persp-mode-tab-bar-mode 1))

;; Navigation

(defvar-local my/ghostel-tmux-session nil)

(defun my/tmux-move (direction)
  "Move to a tmux pane in DIRECTION, returning non-nil if moved."
  (when (and (derived-mode-p 'ghostel-mode) my/ghostel-tmux-session)
    (let ((target (concat "=" my/ghostel-tmux-session ":"))
          (flag (alist-get direction '((left . "-L") (down . "-D")
                                      (up . "-U") (right . "-R"))))
          (edge (alist-get direction '((left . "left") (down . "bottom")
                                      (up . "top") (right . "right")))))
      (with-temp-buffer
        ;; At an edge, print a marker; otherwise select the adjacent pane.
        (and (zerop (call-process "tmux" nil t nil "if-shell" "-F" "-t" target
                                 (format "#{pane_at_%s}" edge)
                                 "display-message -p edge"
                                 (concat "select-pane " flag)))
             (zerop (buffer-size)))))))

(defun my/navigate (direction)
  "Move through tmux panes, then Emacs windows, in DIRECTION."
  (unless (my/tmux-move direction)
    (funcall (alist-get direction
      '((left . evil-window-left)
        (down . evil-window-down)
        (up . evil-window-up)
        (right . evil-window-right)))
    1)))

(map! "M-h" (cmd! (my/navigate 'left))
      "M-j" (cmd! (my/navigate 'down))
      "M-k" (cmd! (my/navigate 'up))
      "M-l" (cmd! (my/navigate 'right)))

(map! "M-;" #'evil-window-vsplit
      "M-/" #'evil-window-split)

(after! ghostel
  (defun my/ghostel-insert-cursor ()
    (if (and ghostel--term (ghostel--mode-enabled ghostel--term 1049))
        (ghostel--apply-cursor-style)
      (setq cursor-type 'bar)))
  (add-hook 'ghostel-mode-hook
            (lambda ()
              (setq-local evil-insert-state-cursor #'my/ghostel-insert-cursor)))
  (add-hook 'evil-normal-state-entry-hook
            (lambda ()
              (when (derived-mode-p 'ghostel-mode)
                (setq-local ghostel-ignore-cursor-change t))))
  (add-hook 'evil-insert-state-entry-hook
            (lambda ()
              (when (derived-mode-p 'ghostel-mode)
                (setq-local ghostel-ignore-cursor-change nil))))

  (defun my/ghostel-with-project-shell (orig-fn &rest args)
    (let* ((session (replace-regexp-in-string "[.:]" "_" (projectile-project-name)))
           (ghostel-shell (list "tmux" "new-session" "-A" "-s" session))
           (buffer (apply orig-fn args)))
      (with-current-buffer buffer
        (unless my/ghostel-tmux-session
          (setq my/ghostel-tmux-session session)))
      buffer))
  (advice-add 'ghostel :around #'my/ghostel-with-project-shell)

  (defun my/ghostel-navigation-keys (&rest _)
    (dolist (map (list ghostel-mode-map ghostel-semi-char-mode-map ghostel-char-mode-map))
      (dolist (key '("M-h" "M-j" "M-k" "M-l"))
        (define-key map (kbd key) (lookup-key global-map (kbd key))))))
  (my/ghostel-navigation-keys)
  (advice-add 'ghostel--rebuild-semi-char-keymap :after #'my/ghostel-navigation-keys))

(after! projectile
  (setq projectile-enable-caching nil))

;; Haskell

(with-eval-after-load 'eglot
  ;; A live report supersedes diagnostics cached while the file was unopened.
  ;; Otherwise cleared errors can linger in Flymake's project diagnostics list.
  (defun my/eglot-clear-cached-file-diagnostics (&rest _)
    (when buffer-file-name
      (setq flymake-list-only-diagnostics
            (assoc-delete-all buffer-file-name flymake-list-only-diagnostics))))
  (advice-add 'eglot--flymake-report-2 :before
              #'my/eglot-clear-cached-file-diagnostics)
  (add-to-list
   'eglot-server-programs
   (cons '(haskell-mode haskell-ts-mode)
         (eglot-alternatives
          '(("haskell-language-server-wrapper" "--lsp")
            ("haskell-language-server" "--lsp"))))))

;; Org-mode

(setq org-directory "~/org/")

;; vi keys for pane navigation.
(map!
   :leader
   :desc "Open global org file"
   "o g"
   (cmd! (find-file (expand-file-name "global.org" org-directory))))


;; QML

;; Automatically load qml-mode for .qml files
(add-to-list 'auto-mode-alist '("\\.qml\\'" . qml-mode))
;; Optional: If you use LSP and want to use the Qt Language Server (qmlls)
(add-hook 'qml-mode-hook #'lsp!)
