;; -*- lexical-binding: t; -*-
(setq nix-librime-path "${pkgs.librime}")
(setq nix-rime-share-data-path "${pkgs.rime-data}")
(setq nix-jbrsdk-path "${pkgs.jbrsdk-17}")
(setq nix-openjdk21-path "${pkgs.openjdk21}")
(add-to-list 'load-path "~/.config/slin-emacs")
(require 'slin-emacs)
