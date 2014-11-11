package utils;

import extension.iap.IAP;
import extension.iap.IAPEvent;
import extension.iap.Inventory;
import tink.core.Future;
import tink.core.Noise;
import tink.core.Outcome;

using tink.core.Outcome;

class IAPManager {
  private static function oneTimeEventListeners(eventFuncMap : Map<String,Void -> Void>) {
    var eFunc : flash.events.Event -> Void = null;
    eFunc = function(e : flash.events.Event) {
      eventFuncMap.get(e.type)();
      for (eventType in eventFuncMap.keys()) {
        IAP.removeEventListener(eventType, eFunc);
      }
    }
    for (eventType in eventFuncMap.keys()) {
      IAP.addEventListener(eventType,eFunc);
    }
  }

  private var publicKey : String;
  public function new(publicKey : String) {
    this.publicKey = publicKey;
    initFutureTrigger = Future.trigger();
    initFuture = initFutureTrigger.asFuture();
  }

  // A future, that is triggered when the library is succesfully initilized
  // This is usefull so that a class, that does not call initilize can still be informed when init is done
  public var initFuture(default,null) : Surprise<Noise,String>;
  private var initFutureTrigger       : FutureTrigger<Outcome<Noise,String>>;

  public function initilize() : Surprise<Noise,String> {
    oneTimeEventListeners([IAPEvent.PURCHASE_INIT        => function() {initFutureTrigger.trigger(Success(Noise));},
                           IAPEvent.PURCHASE_INIT_FAILED => function() {initFutureTrigger.trigger(Failure(Main.tongue.get("$IAP_INIT_FAILED")));}]);
    IAP.initialize(publicKey);
    return initFuture;
  }

  public function queryInventory (queryItemDetails:Bool = false, moreItems:Array<String> = null) : Surprise<Inventory,String> {
    var res = Future.trigger();
    oneTimeEventListeners([IAPEvent.PURCHASE_QUERY_INVENTORY_COMPLETE => function() {res.trigger(Success(IAP.inventory));},
                                IAPEvent.PURCHASE_QUERY_INVENTORY_FAILED   => function() {res.trigger(Failure(Main.tongue.get("$IAP_QUERY_INVENTORY_FAILED")));}]);
    IAP.queryInventory(queryItemDetails, moreItems);
    return res.asFuture();
  }

  public function queryInventoryAndCheckForItem(itemId : String) : Surprise<Bool, String> {
    return queryInventory().map(
      function(s) {
        return s.map(
          function(i) {
            return i.hasPurchase(itemId);
          }
        );
      }
    );
  }

  public function purchase (productID:String, devPayload:String = "") : Future<Bool> {
    var res = Future.trigger();
    // Ensure that we are initilized ...
    initFuture.handle(function(_) {
      oneTimeEventListeners([IAPEvent.PURCHASE_SUCCESS => function() {res.trigger(true);},
                             IAPEvent.PURCHASE_FAILURE => function() {res.trigger(false);},
                             IAPEvent.PURCHASE_CANCEL  => function() {res.trigger(false);}]);
      IAP.purchase(productID, devPayload);
    });
    return res.asFuture();
  }

}
