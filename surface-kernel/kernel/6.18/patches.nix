{
  lib,
  kernel ? lib.kernel,
  patchSrc,
  version,
  structuredExtraConfig,
}:

[
  {
    name = "microsoft-surface-patches-linux-${version}";
    patch = null;
    inherit structuredExtraConfig;
  }
  {
    name = "ms-surface/0001-secureboot";
    patch = patchSrc + "/0001-secureboot.patch";
  }
  {
    name = "ms-surface/0002-surface3";
    patch = patchSrc + "/0002-surface3.patch";
  }
  {
    name = "ms-surface/0003-mwifiex";
    patch = patchSrc + "/0003-mwifiex.patch";
  }
  {
    name = "ms-surface/0004-ath10k";
    patch = patchSrc + "/0004-ath10k.patch";
  }
  {
    name = "ms-surface/0005-ipts";
    patch = patchSrc + "/0005-ipts.patch";
  }
  {
    name = "ms-surface/0006-ithc";
    patch = patchSrc + "/0006-ithc.patch";
  }
  {
    name = "ms-surface/0007-surface-sam";
    patch = patchSrc + "/0007-surface-sam.patch";
  }
  {
    name = "ms-surface/0008-surface-sam-over-hid";
    patch = patchSrc + "/0008-surface-sam-over-hid.patch";
  }
  {
    name = "ms-surface/0009-surface-button";
    patch = patchSrc + "/0009-surface-button.patch";
  }
  {
    name = "ms-surface/0010-surface-typecover";
    patch = patchSrc + "/0010-surface-typecover.patch";
  }
  {
    name = "ms-surface/0011-surface-shutdown";
    patch = patchSrc + "/0011-surface-shutdown.patch";
  }
  {
    name = "ms-surface/0012-surface-gpe";
    patch = patchSrc + "/0012-surface-gpe.patch";
  }
  {
    name = "ms-surface/0013-cameras";
    patch = patchSrc + "/0013-cameras.patch";
  }
  {
    name = "ms-surface/0014-amd-gpio";
    patch = patchSrc + "/0014-amd-gpio.patch";
  }
  {
    name = "ms-surface/0015-rtc";
    patch = patchSrc + "/0015-rtc.patch";
  }
  {
    name = "ms-surface/0016-hid-surface";
    patch = patchSrc + "/0016-hid-surface.patch";
  }
]
