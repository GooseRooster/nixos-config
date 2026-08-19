{ config, lib, pkgs, inputs, ... }:

{
  imports = [ inputs.noctalia-greeter.nixosModules.default ];

  programs.noctalia-greeter = {
    enable = true;

    # Optional: declarative greeter.toml (see examples/greeter.toml upstream).
    # settings = {
    #   cursor = {
    #     theme = "Adwaita";
    #     size = 24;
    #   };
    # };
  };
}
