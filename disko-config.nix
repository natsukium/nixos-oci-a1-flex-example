# https://github.com/nix-community/disko/blob/502241afa3de2a24865ddcbe4c122f4546e32092/example/bcachefs.nix
{
  disko.devices = {
    disk = {
      vdb = {
        device = "/dev/sda";
        type = "disk";
        content = {
          type = "gpt";
          partitions = {
            ESP = {
              end = "500M";
              type = "EF00";
              content = {
                type = "filesystem";
                format = "vfat";
                mountpoint = "/boot";
              };
            };
            root = {
              name = "root";
              end = "-0";
              content = {
                type = "filesystem";
                format = "bcachefs";
                mountpoint = "/";
              };
            };
          };
        };
      };
    };
  };
}
