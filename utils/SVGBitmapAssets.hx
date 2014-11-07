package utils;

import flash.display.Shape;
import flash.display.BitmapData;
import haxe.ds.StringMap;
import format.SVG;

class SVGBitmapAssets
{
  static var loadedAssets : StringMap<BitmapData> = new StringMap();

  static public function loadSVG(path : String, width : Int, height : Int) {
    var assetName = path + width + "x" + height;
    if (!loadedAssets.exists(assetName)) {
      //Load it ...
      loadedAssets.set(assetName,createBitmapData(path, width, height));
    }
    return loadedAssets.get(assetName);
  }
  private static function createBitmapData(path : String, width : Int, height : Int) : BitmapData {
    var res = new BitmapData(width, height, true, 0x000000FF);
    var svg = new SVG(openfl.Assets.getText(path));
    var shape = new Shape();
    svg.render(shape.graphics,0,0,width,height);
    res.draw(shape);
    return res;
  }
}
