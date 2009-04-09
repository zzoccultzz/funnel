﻿package {	import flash.display.Shape;	import flash.display.Sprite;	import flash.display.MovieClip;	import flash.events.Event;	import flash.text.TextField;	import funnel.*;	/**	 * ボタンが押されている間LEDをサイン波でドライブする。	 * このサンプルではデジタルとアナログの入出力に加えてI2Cデバイスを	 * 利用する方法を紹介する。	 * Drive a LED with sin wave while the button is pressed.	 * This example demonstrates the use of 2 I2C devices along with digital	 * and analog I/O.	 *	 * <p>準備<ol>	 * <li>D12にスイッチを接続する（プルアップが必要）</li>	 * <li>D11にLEDを接続する（電流制限のための抵抗器が必要）</li>	 * <li>A0にセンサを接続する（例：ボリューム）</li>	 * <li>HMC6352（デジタルコンパス）、LIS3LV02DQ（加速度センサ）をI2Cバスに接続する</li>	 * </ol></p>	 *	 * <p>Preparation<ol>	 * <li>Connect a button to D12 (should be pulled-up)</li>	 * <li>Connect a LED to D11 (current-limiting resistor is needed)</li>	 * <li>Connect a sensor to A0 (e.g. a potentiometer)</li>	 * <li>Connect a HMC6352 (compass), LIS3LV02DQ (accelerometer), or other I2C device to the I2C bus</li>	 * </ol></p>	 */	public class ArduinoTestWithI2C extends Sprite {		// To change number of analog channels, modify this constant		// 表示するアナログチャンネル数を変更するにはこの定数を変更する		private const NUM_CHANNELS:int = 1;		private var aio:Arduino;		private var scope:SimpleScope;		private var scopes:Array;		private var accl:LIS3LV02DQ;		private var compass:HMC6352;		public function ArduinoTestWithI2C() {			var config:Configuration = Arduino.FIRMATA;			config.setDigitalPinMode(11, PWM);			config.setDigitalPinMode(12, IN);			config.setDigitalPinMode(13, OUT);						// set unused analog pins to digital outputs to save processor time			config.setDigitalPinMode(15, OUT);	// set A1 as digital output			config.setDigitalPinMode(16, OUT);	// set A2 as digital output			config.setDigitalPinMode(17, OUT);	// set A3 as digital output					aio = new Arduino(config);			aio.addEventListener(FunnelEvent.READY, trace);			aio.addEventListener(FunnelErrorEvent.REBOOT_ERROR, trace);			aio.addEventListener(FunnelErrorEvent.CONFIGURATION_ERROR, trace);			aio.addEventListener(FunnelErrorEvent.ERROR, trace);						// You can set the second parameter to "false" to disable Read Continuous mode			// Read Continuous mode is recommended because it significantly			// improves the Flash Players performance since the Arduino handles			// most of the work in reading the I2C device			accl = new LIS3LV02DQ(aio);		// default mode = Read Continuous			//accl = new LIS3LV02DQ(aio, false);	// this will disable Read Continuous			                                        // you will need to call the update method													// to request data from the device			accl.addEventListener(Event.CHANGE, onAcclUpdate);						compass =  new HMC6352(aio);			compass.addEventListener(Event.CHANGE, onCompassUpdate);			scopes = new Array(NUM_CHANNELS);			for (var i:int = 0; i < NUM_CHANNELS; i++) {				scopes[i] = new SimpleScope(10, 10 + (60 * i), 200);				addChild(scopes[i]);			}			var circle:Shape = new Shape();			circle.graphics.beginFill(0x000000);			circle.graphics.drawCircle(0, 0, 50);			circle.graphics.endFill();			circle.alpha = 0.2;			circle.x = 300;			circle.y = 70;			this.addChild(circle);			var button:Pin = aio.digitalPin(12);			var externalLED:Pin = aio.digitalPin(11);			var onBoardLED:Pin = aio.digitalPin(13);			externalLED.filters = [new Osc(Osc.SIN, 0.5, 1, 0, 0)];			button.addEventListener(PinEvent.FALLING_EDGE, function(e:Event):void {				onBoardLED.value = 1.0;				circle.alpha = 1.0;				externalLED.filters[0].reset();				externalLED.filters[0].start();			});			button.addEventListener(PinEvent.RISING_EDGE, function(e:Event):void {				onBoardLED.value = 0.0;				circle.alpha = 0.2;				externalLED.filters[0].stop();				externalLED.value = 0.0;			});			addEventListener(Event.ENTER_FRAME, loop);		}		private function loop(event:Event):void {			for (var i:int = 0; i < NUM_CHANNELS; i++) {				scopes[i].update(aio.analogPin(i));			}						// only need to call this method if Read Continuous mode is not enabled			//accl.update(); // request new x, y, z values from accelerometer					}				private function onAcclUpdate(event:Event):void {			textContainer.xVal.text = String(accl.x);			textContainer.yVal.text = String(accl.y);			textContainer.zVal.text = String(accl.z);						}				private function onCompassUpdate(event:Event):void {			textContainer.heading.text = String(compass.heading);					}	}}