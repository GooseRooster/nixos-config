# Shared dconf defaults layer.
#
# GNOME settings (fonts, shortcuts, extension config, ...) are declaratively
# managed as dconf *defaults*: they land in the system-db, which sits below the
# user-db, so Settings / Extension Manager can still override anything (soft
# defaults). Note that list-typed keys are all-or-nothing — a manual toggle in
# the UI writes the whole list to the user-db and shadows these defaults.
#
# Every module and host contributes into the single `modules.gnome.dconf`
# option below; contributions merge per-path and per-key (mkMerge), so hosts
# can override individual keys of the shared config. Gvariant-typed values
# (lib.gvariant.*) that need overriding should use mkForce/mkOverride, since
# mkMerge would try to merge the gvariant attrsets themselves.
{
  config,
  lib,
  ...
}:

{
  options.modules.gnome.dconf.settings = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
    description = ''
      dconf settings merged into the user profile as system-db defaults.
      Outer keys are dconf paths ("org/gnome/..."), inner keys are dconf keys.
      Non-trivial value types (empty arrays, uints, tuples) need lib.gvariant.
    '';
  };

  config.programs.dconf.profiles.user.databases = lib.mkIf
    (config.modules.gnome.dconf.settings != { })
    [
      {
        settings = config.modules.gnome.dconf.settings;
      }
    ];
}
