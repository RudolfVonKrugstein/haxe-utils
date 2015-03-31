package utils;

class InterstitialManager {
  private var checkpointCounter : Int = 0;

  private var enabled = false;
  public function enable() {
    enabled = true;
  }
  public function disable() {
    enabled = false;
  }

  // Position where this will be shown
  var position : mobilecore.MobileCore.InterstitialPosition;
  public function new(position : mobilecore.MobileCore.InterstitialPosition = NOT_SET) {
    this.position = position;
  }

  public function interstitialCheckpoint() {
    checkpointCounter = checkpointCounter + 1;
    if (checkpointCounter >= 10) {
      checkpointCounter = 0;
      if (enabled) {
        mobilecore.MobileCore.showInterstitial(null, position);
      }
    }
  }
}
