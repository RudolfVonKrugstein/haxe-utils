package utils;

import tink.core.Signal;
import tink.core.Future;
import tink.core.Outcome;
import tink.core.Noise;

class ProStatusManager {
  public var proStatusSignal(default,null) : Signal<Bool>;
  private var proStatusSignalTrigger : SignalTrigger<Bool>;
  public var proStatus(default,null) : Bool;

  private var iapManager : IIAPManager = null;
  private var proStatusItem : String = null;

  public function new () {
    proStatusSignalTrigger = Signal.trigger();
    proStatusSignal = proStatusSignalTrigger.asSignal();
  }

  public function initilize(iapManager : IIAPManager, proStatusItem : String) {
    this.iapManager = iapManager;
    this.proStatusItem = proStatusItem;
    // A zero iapManager means, it is always purchased
    if (iapManager == null) {
      proStatus = true;
      return;
    }

    // Get the local storage of the pro status ...
    var so : flash.net.SharedObject = flash.net.SharedObject.getLocal("proStatus");
    if (so.data.proEnabled == null) {
      proStatus = false;
    } else {
      proStatus = so.data.proEnabled;
    }
    // Signal it!
    proStatusSignalTrigger.trigger(proStatus);
    // Get the pro status from the play store ...
    monads.MonadSurprise.dO({
      iapManager.initFuture;
      iapManager.queryInventoryAndCheckForItem(proStatusItem);
    }).handle(function(r) {
      switch(r) {
        case Success(s):
          setProStatus(s);
        default:
      }
    });
  }

  public function purchaseProStatus() : Surprise<Bool,String> {
    var res = Future.trigger();
    if (iapManager == null) {
      res.trigger(Success(true));
    } else {
      if (!iapManager.iapAvailable) {
        res.trigger(Failure("IAP not available"));
      } else {
        iapManager.purchase(proStatusItem).handle(function(r) {
       	  if (r) {
	    setProStatus(true);
	    res.trigger(Success(r));
	  }
        });
      }
    }
    return res.asFuture();
  }

  private function setProStatus(s : Bool) {
    if (s == proStatus) return;
    proStatus = s;
    proStatusSignalTrigger.trigger(proStatus);
    var so : flash.net.SharedObject = flash.net.SharedObject.getLocal("proStatus");
    so.setProperty("proEnabled",s);
    so.flush();
  }
}
