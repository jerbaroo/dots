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

(map! "M-h" #'evil-window-left
      "M-j" #'evil-window-down
      "M-k" #'evil-window-up
      "M-l" #'evil-window-right
      "M-;" #'evil-window-vsplit
      "M-/" #'evil-window-split)

(defun my/project-kitty ()
  "Open Kitty below Emacs, attached to the project's tmux session."
  (interactive)
  (let* ((default-directory (or (projectile-project-root) default-directory))
         (session (replace-regexp-in-string
                   "[.:]" "_" (projectile-project-name))))
    ;; Share the focused-window height calculation used by Super+Shift+Return.
    (call-process "hyprctl" nil nil nil "eval"
                  "local w = hl.get_active_window(); _G.kitty_below_height = w and w.size.y or nil")
    (start-process "project-kitty" nil
                   "kitty" "--class" "kitty-below"
                   "--directory" default-directory
                   "tmux" "new-session" "-A" "-s" session
                   "-c" default-directory)))

(map! :leader
      :desc "Project terminal in Kitty"
      "o k" #'my/project-kitty)

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
