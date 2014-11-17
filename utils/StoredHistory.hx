package utils;

class StoredHistory<T> {
  private var name : String;
  private var maxElements : Int;

  private var history : Array<T> = [];
  public var length(get,null) : Int;

  public function get(i : Int) : T {
    return history[i];
  }

  private function get_length() : Int {
    return history.length;
  }

  private var so : flash.net.SharedObject;

  public function new(name : String, maxElements : Int) {
    this.name = name;
    this.maxElements = maxElements;
    so = flash.net.SharedObject.getLocal(name);
    if (so.data.history != null) {
      history = so.data.history;
    }
  }

  public function addElement(e : T, compare : T -> T -> Bool = null) {
    trace("addElement");
    if (compare != null) {
      for (h in history) {
        if (compare(h,e)) {
          history.remove(h);
          break;
        }
      }
    }
    // Add to history and shorten it
    history.insert(0,e);
    while(history.length > maxElements) {
      history.pop();
    }
    so.setProperty("history",history);
    so.flush();
  }
}
