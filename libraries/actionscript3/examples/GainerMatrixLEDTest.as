package
{
	import flash.display.*;
	import flash.events.Event;
	import flash.geom.Point;
	import funnel.*;

	/**
	 * Gainer I/O MODE7を使用してマトリクスLEDをコントロールする。
	 * An example of Gainer I/O MODE 7 to control a matrix LED.
	 */
	public class GainerMatrixLEDTest extends Sprite
	{
		public function GainerMatrixLEDTest() {
			var mat:MatrixLED = new MatrixLED();
			var data:BitmapData = new BitmapData(8, 8);
			addChild(new Bitmap(data));
			width = height = 500;

			var p:Point = new Point();
			addEventListener(Event.ENTER_FRAME, function(e:Event):void {
				p.x++;
				data.perlinNoise(8, 8, 1, 0, false, false, 7, true, [p]);
				data.draw(data, null, null, BlendMode.ADD);
				mat.scanMatrix(data);
			});
		}
	}
}