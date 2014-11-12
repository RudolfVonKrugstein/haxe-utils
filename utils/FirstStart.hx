package utils;

class FirstStart {
  // Indicates if the app is started for the first time in this version
  public static function firstStart(version : Int) :  Bool {
    // Get a shared object indiciating if its first started
    var so : flash.net.SharedObject = flash.net.SharedObject.getLocal("firstStart");
    var lastStartedVersion : Int;
    if (so.data.lastStartedVersion == null) {
      lastStartedVersion = version - 1;
    } else {
      lastStartedVersion = so.data.lastStartedVersion;
    }
    so.setProperty("lastStartedVersion",version);
    so.flush();
    return (lastStartedVersion != version);
  }
}
