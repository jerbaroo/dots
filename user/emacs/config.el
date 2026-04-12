;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; https://github.com/doomemacs/doomemacs/blob/master/static/config.example.el

;; Prevent "void-variable haskell-indent-offset" errors from legacy project configs
(defvar haskell-indent-offset 2
  "Dummy variable to prevent void-variable errors in older Haskell projects.")

(setq
  catppuccin-flavor '@flavor@
  display-line-numbers-type 'relative
  doom-font (font-spec :family "@codeFontName@" :size @codeFontSize@)
  doom-theme 'catppuccin
  flycheck-checker-error-threshold 1000
  ;; doom-themes-treemacs-theme "doom-colors"
  ;; doom-variable-pitch-font (font-spec :family "@codeFontName@" :size @codeFontSize@)
  ;; lsp-disabled-clients '(pylsp)
  ;; lsp-enable-file-watchers nil
  ;; lsp-eldoc-enable-hover t
  ;; lsp-haskell-formatting-provider "fourmolu"
  ;; lsp-haskell-plugin-fourmolu-config-external t
  lsp-haskell-plugin-hlint-code-actions-on nil
  lsp-haskell-plugin-hlint-diagnostics-on nil
  ;; lsp-haskell-plugin-rename-config-cross-module t
  ;; lsp-haskell-plugin-semantic-tokens-global-on t
  ;; lsp-haskell-session-loading "multipleComponents"
  ;; lsp-haskell-server-path "haskell-language-server"
  lsp-haskell-server-args '("-d" "-l" "/tmp/hls.log")
  lsp-lens-enable nil
  ;; lsp-ui-peek-enable t
  ;; lsp-ui-sideline-enable t
  org-directory "~/org/"
  org-latex-pdf-process
    '("xelatex -shell-escape -interaction nonstopmode %f"
      "bibtex %b"
      "xelatex -shell-escape -interaction nonstopmode %f")
  user-full-name "jerbaroo"
  user-mail-address "jerbaroo.work@pm.me"
  which-key-idle-delay 0.0
  zoom-size '(0.60 . 0.60)
  )

(add-to-list
  'default-frame-alist
  '(alpha-background . @codeBackgroundOpacity@)
  )

(after! lsp-ui
  (setq
    ;; lsp-ui-doc-delay 0.2
    ;; lsp-ui-doc-enable t
    ;; lsp-ui-doc-show-with-cursor t
    ;; lsp-ui-doc-side 'right
    ;; lsp-ui-doc-position 'top
    )
  (add-to-list 'lsp-ui-doc-frame-parameters '(alpha-background . 100))
  )

(global-display-fill-column-indicator-mode)

(map!
  "C-h" #'evil-window-left
  "C-j" #'evil-window-down
  "C-k" #'evil-window-up
  "C-l" #'evil-window-right
  )

(map! :leader
  :desc "Show LSP UI Doc"
  "c c" #'lsp-ui-doc-show)

(custom-set-faces!
  ;; Using a different font messes with fill-column-indicator alignment.
  '(font-lock-comment-face :family "@codeFontName@" :foreground "@colourComment@" :size @codeFontSize@ :slant italic)
  '(line-number :foreground "@colourLineNumber@")
  '(line-number-current-line :foreground "@colourLineNumberCurrent@")
  )

;; Automatically load qml-mode for .qml files
(add-to-list 'auto-mode-alist '("\\.qml\\'" . qml-mode))
;; Optional: If you use LSP and want to use the Qt Language Server (qmlls)
(add-hook 'qml-mode-hook #'lsp!)
