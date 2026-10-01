{
  # SSH agent for every desktop session. gnome-keyring dropped its SSH
  # component in gcr 4; gcr-ssh-agent provides it now, independent of the
  # Secret Service. It exposes its socket at $XDG_RUNTIME_DIR/gcr/ssh and sets
  # SSH_AUTH_SOCK in the systemd user environment — which a bare Sway session
  # never imports, so modules/desktop/sway.nix exports it explicitly.
  #
  # The Secret Service itself (gnome-keyring) is enabled by the session stack
  # module, which wires its own PAM login auto-unlock hook.
  services.gnome.gcr-ssh-agent.enable = true;
}
