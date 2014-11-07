package utils;

import mobilecore.MobileCore;

class StickeezManager extends haxe.Timer{
  public function new() {
    super(10000);
  }
  private var enabled = false;
  public function enable() {
    enabled = true;
  }
  public function disable() {
    enabled = false;
    if (MobileCore.isStickeeShowing()) {
      MobileCore.hideStickee();
    }
  }

  // For how many run invokes has the stickeez not been shown?
  private var notShownCounter : Int = 15;

  public override function run() {
    if (!MobileCore.isStickeeReady()) {
      return;
    }
    if (MobileCore.isStickeeShowing()) {
      notShownCounter = 0;
      return;
    }
    // Stickeez ready, for how long not shown?
    notShownCounter = notShownCounter + 1;
    if (notShownCounter >= 5) {
      if (enabled) {
        MobileCore.showStickee();
      }
      notShownCounter = 0;
    }
  }
}
