package utils;

import tink.core.Future;
import tink.core.Noise;
import tink.core.Outcome;

using tink.core.Outcome;

interface IIAPManager {
  public var iapAvailable(get,null) : Bool;
  public var initFuture(default,null) : Surprise<Noise,String>;
  public function initilize() : Surprise<Noise,String>;
  //public function queryInventory (queryItemDetails:Bool = false, moreItems:Array<String> = null) : Surprise<Inventory,String>;
  public function queryInventoryAndCheckForItem(itemId : String) : Surprise<Bool, String>;
  public function purchase (productID:String, devPayload:String = "") : Future<Bool>;
}
