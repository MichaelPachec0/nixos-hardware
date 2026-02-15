{
  lib,
  fetchurl, # fetchpatch does unnecessary normalization
  ...
}@args:

{
  kernel,
  patchesFile,
  experimental ? false,
}:
let
  inherit (builtins) readFile fromJSON;

  patchset = fromJSON (readFile patchesFile);
  t2-patches = map (
    { name, hash }:
    {
      inherit name;
      patch = fetchurl {
        inherit name hash;
        url = patchset.base_url + name;
      };
    }
  ) patchset.patches;
  resume-patch = {
    name = "sleep/resume fix for t2 linux";
    patch = ./apple-bce-sleep.patch;
  };
  hid-resume-patch = {
    name = "apple kbd resume patch";
    patch = ./hid-appletb-kdb-resume.patch;
  };
in
kernel.override (
  args
  // {
    pname = "linux-t2";

    argsOverride.modDirVersion = "${kernel.modDirVersion}-t2";

    structuredExtraConfig = with lib.kernel; {
      APPLE_BCE = module;
      APPLE_GMUX = module;
      APFS_FS = module;
      BRCMFMAC = module;
      BT_BCM = module;
      BT_HCIBCM4377 = module;
      BT_HCIUART_BCM = yes;
      BT_HCIUART = module;
      HID_APPLETB_BL = module;
      HID_APPLETB_KBD = module;
      HID_APPLE = module;
      HID_MAGICMOUSE = module;
      DRM_APPLETBDRM = module;
      HID_SENSOR_ALS = module;
      SND_PCM = module;
      STAGING = yes;
      LOCALVERSION = freeform "-t2";
    };

    kernelPatches = t2-patches ++ (args.kernelPatches or [ ]) ++ (if experimental then [resume-patch hid-resume-patch] else []);

    argsOverride.extraMeta = {
      description = "The Linux kernel (with patches from the T2 Linux project)";

      # take responsibility for the downstream kernel
      maintainers = with lib.maintainers; [ soopyc ];
    };
  }
  // (args.argsOverride or { })
)
