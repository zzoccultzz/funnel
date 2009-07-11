﻿package {	import flash.display.Shape;	import flash.display.Sprite;	import flash.events.Event;	import flash.events.MouseEvent;	import flash.text.TextField;	import flash.text.TextFieldAutoSize;		import funnel.*;	import funnel.i2c.*;	/**	 * HMC6352コンパスモジュールの方向情報を表示する。	 * Display heading values of a HMC6352 compass module.	 *	 * <p>準備<ol>	 * <li>HMC6352コンパスモジュールを接続する</li>	 * <li>hardware/arduino/SimpleI2CFirmataをArduinoにアップロードする</li>	 * </ol></p>	 *	 * <p>Preparation<ol>	 * <li>Connect a HMC6352 compass module to the Arduino</li>	 * <li>upload hardware/arduino/SimpleI2CFirmata to the Arduino</li>	 * </ol></p>	 */	public class ArduinoI2CTest extends Sprite {		private const defaultText:String = "Press the mouse button to start calibration.";		private var aio:Arduino;		private var compass:HMC6352;		private var clockHand:Shape;		private var messageArea:TextField;		public function ArduinoI2CTest() {			var config:Configuration = Arduino.FIRMATA;			config.enablePowerPins();			aio = new Arduino(config);			aio.addEventListener(FunnelEvent.I2C_POWER_PINS_READY, onI2CPowerPinsReady);			messageArea = new TextField();			messageArea.text = defaultText;			messageArea.autoSize = TextFieldAutoSize.LEFT;			addChild(messageArea);			initClockHand();			stage.addEventListener(MouseEvent.CLICK, enterUserCalibrationMode);			addEventListener(Event.ENTER_FRAME, loop);		}		private function loop(event:Event):void {			// NOTE: Put your code here to draw something (if needed)		}		private function onI2CPowerPinsReady(event:Event):void {			compass = new HMC6352(aio);			compass.addEventListener(Event.CHANGE, onCompassHeadingChange);		}		private function onCompassHeadingChange(e:Event):void {			clockHand.rotation = compass.heading;		}		private function enterUserCalibrationMode(e:MouseEvent):void {			stage.removeEventListener(MouseEvent.CLICK, enterUserCalibrationMode);			stage.addEventListener(MouseEvent.CLICK, exitUserCalibrationMode);			messageArea.text = "Rotate the device for 360 degrees, then press the mouse button again.";			compass.enterUserCalibrationMode();		}		private function exitUserCalibrationMode(e:MouseEvent):void {			stage.removeEventListener(MouseEvent.CLICK, exitUserCalibrationMode);			stage.addEventListener(MouseEvent.CLICK, enterUserCalibrationMode);			messageArea.text = defaultText;			compass.exitUserCalibrationMode();		}		private function initClockHand():void {			clockHand = new Shape();			clockHand.x = 200;			clockHand.y = 200;			clockHand.graphics.clear();			clockHand.graphics.beginFill(0x000000);			clockHand.graphics.moveTo(0, -100);			clockHand.graphics.lineTo(20, 20);			clockHand.graphics.lineTo(0, 0);			clockHand.graphics.lineTo(-20, 20);			clockHand.graphics.lineTo(0, -100);			clockHand.graphics.endFill();			clockHand.graphics.lineStyle(1, 0x000000);			clockHand.graphics.drawCircle(0, 0, 102);			clockHand.rotation = 0;			this.addChild(clockHand);		}	}}