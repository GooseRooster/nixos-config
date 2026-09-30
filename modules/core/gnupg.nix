{ config, lib, pkgs, ... }:

{
  # GnuPG agent for commit signing etc. SSH agent stays on gcr-ssh-agent
  # (desktop) so SSH support is left off — two agents would fight over
  # SSH_AUTH_SOCK.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = false;
  };
}
