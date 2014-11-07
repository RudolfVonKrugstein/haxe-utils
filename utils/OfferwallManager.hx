package utils;

class OfferwallManager {
  private var checkpointCounter : Int = 0;

  private var enabled = false;
  public function enable() {
    enabled = true;
  }
  public function disable() {
    enabled = false;
  }

  public function new() {
  }

  public function offerWallCheckpoint() {
    checkpointCounter = checkpointCounter + 1;
    if (checkpointCounter >= 10) {
      checkpointCounter = 0;
      if (enabled) {
        mobilecore.MobileCore.showOfferWall(null, true);
      }
    }
  }
}
