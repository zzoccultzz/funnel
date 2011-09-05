﻿package funnel.i2c {	import flash.events.Event;	import flash.events.EventDispatcher;	import flash.events.IEventDispatcher;	/**	 * This is the class to express a Honeywell HMC6352 Digital Compass Module	 *	 */	public class HMC6352 extends I2CDevice implements IEventDispatcher {		public static const DEVICE_ID:uint = 0x21;			private var _address:uint;		private var _dispatcher:EventDispatcher;		private var _heading:Number;		private var _isReading:Boolean = false;		public function HMC6352(ioModule:*, address:uint = DEVICE_ID) {			super(ioModule, address);			_address = address;			_heading = 0;			_dispatcher = new EventDispatcher(this);						// 0x51 = 10 Hz measurement rate, Query Mode			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'G'.charCodeAt(0), 0x74, 0x51]);			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'A'.charCodeAt(0)]);			startReading();		}		/**		 * <p>Manual calibration should not be necessary under most circumstances. If calibration		 * is necessary, please use the following instructions when calling this method:</p>		 *		 * <p>To manually calibrate: slowly rotate the compass on a flat surface at 		 * least one full circular rotation. Optimally, two rotations over 20 seconds 		 * duration would provide an accurate calibration.</p>		 * <p>The calibration time window is recommended to be from 6 seconds up to 3 minutes</p>		 * 		 */		public function enterUserCalibrationMode():void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'C'.charCodeAt(0)]);		}				/**		 * call this method to end the manual calibration routine		 */		public function exitUserCalibrationMode():void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, 'E'.charCodeAt(0)]);		}		/**		 * @private		 */		override public function handleSysex(command:uint, data:Array):void {			if (command != I2C_REPLY) {				return;			}			_heading = (int(data[2]) * 256 + int(data[3])) / 10.0;			dispatchEvent(new Event(Event.CHANGE));		}				/**		 * compass heading in degrees (0 to 360)		 */		public function get heading():Number {			return _heading;		}				/**		 * start continuous reading of the sensor		 */				public function startReading():void {			if (!_isReading) {				_isReading = true;				_io.sendSysex(I2C_REQUEST, [READ_CONTINUOUS, address, 0x7F, 0x02]);							}		}						/**		 * stop continuous reading of the sensor		 */					public function stopReading():void {			_isReading = false;			_io.sendSysex(I2C_REQUEST, [STOP_READING, _address]);		}						/* implement EventDispatcher */				public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {			_dispatcher.addEventListener(type, listener, useCapture, priority);		}		public function dispatchEvent(evt:Event):Boolean {			return _dispatcher.dispatchEvent(evt);		}				public function hasEventListener(type:String):Boolean {			return _dispatcher.hasEventListener(type);		}		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {			_dispatcher.removeEventListener(type, listener, useCapture);		}		public function willTrigger(type:String):Boolean {			return _dispatcher.willTrigger(type);		}	}}