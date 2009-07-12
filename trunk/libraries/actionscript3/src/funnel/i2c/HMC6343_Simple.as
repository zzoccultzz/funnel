﻿package funnel.i2c {	import flash.events.Event;	import flash.events.EventDispatcher;	import flash.events.IEventDispatcher;	import flash.events.TimerEvent;	import flash.utils.Timer;	/**	 * This is the class to express HMC6343 tilt-compensated compass	 * Simple version only enables Heading, Pitch, and Roll data	 * 	 * Created by Jeff Hoefs	 * Modified by Shigeru Kobayashi	 *	 */	public class HMC6343_Simple extends I2CDevice implements IEventDispatcher {		public static const LEVEL:uint = 0x72;		public static const UPRIGHT_EDGE:uint = 0x73;		public static const UPRIGHT_FRONT:uint = 0x74;		public static const READ_HEADING:uint = 0x50;		public static const ENTER_USER_CALIBRATION_MODE:uint = 0x71;		public static const EXIT_USER_CALIBRATION_MODE:uint = 0x7E;		public static const RESET_THE_PROCESSOR:uint = 0x82;		private static const RESPONCE_DELAY_TIME_50MS:uint = 50;	// 50ms		private static const RESPONCE_DELAY_TIME_500MS:uint = 500;	// 500ms		// Operational Mode Register 2 (EEPROM 0x05)		private static const OP_MODE2:uint = 0x05;		// Measurement rates (for bits 0 and 1 of OP_MODE2)		private static const RATE_10HZ:uint = 0x02;		private static const RATE_5HZ:uint = 0x01;		private static const RATE_1HZ:uint = 0x00;		private static const RATE_NA:uint = 0x03;		private var _heading:Number = 0;		private var _pitch:Number = 0;		private var _roll:Number = 0;		private var _compassOrientation:uint;		private var _isReadContinuous:Boolean;		private var _dispatcher:EventDispatcher;		private var _timer:Timer = null;		private var _readOperationsEnabled:Boolean = true;		public function HMC6343_Simple(ioModule:*, compassOrientation:uint = 0, readContinuous:Boolean = true, address:uint = 0x19, measureRate:uint = RATE_10HZ) {			super(ioModule, address);			_dispatcher = new EventDispatcher(this);			_isReadContinuous = readContinuous;						if(compassOrientation == 0) {				_compassOrientation = LEVEL;			} else {				setCompassOrientation(compassOrientation);			}			// set measurement rate (device default is 5hz, but it is set as default to 10hz in this class)			// ensure that incorrect measurement rate is not passed			if(measureRate > 0x03) measureRate = RATE_10HZ;			_io.sendSysex(I2C_REQUEST, [WRITE, address, OP_MODE2, measureRate]);			if (_isReadContinuous) {				_io.sendSysex(I2C_REQUEST, [READ_CONTINUOUS, address, READ_HEADING, 6]);			}		}		public function setCompassOrientation(compassOrientation:uint):void {			if (compassOrientation == LEVEL || compassOrientation == UPRIGHT_EDGE || compassOrientation == UPRIGHT_FRONT) {				_compassOrientation = compassOrientation;				_io.sendSysex(I2C_REQUEST, [WRITE, address, _compassOrientation]);			} else {				throw new ArgumentError("Incorrect compass orientation specified, use only 0x72 - 0x74");			}		}		public override function update():void {			// read heading, pitch, roll			if (!_isReadContinuous && _readOperationsEnabled) {				_io.sendSysex(I2C_REQUEST, [READ, address, READ_HEADING, 6]);			} else {				throw new ArgumentError("Cannot call update method when Read Continuous is set to true");			}		}		public override function handleSysex(command:uint, data:Array):void {			var pitch_val:int, roll_val:int;			if (command != I2C_REPLY) {				return;			}			if (data[1] == READ_HEADING) {				// 360.0 degrees				_heading = (int(data[2]) << 8) | (int(data[3]));				// 90.0 degrees				pitch_val = (int(data[4]) << 8) | (int(data[5]));				// according to the datasheet, roll should be in the range of +/- 90				// however the range is actually +/- 180 degrees				roll_val = (int(data[6]) << 8) | (int(data[7]));				if (roll_val >> 15) {					_roll = ((roll_val ^ 0xFFFF) + 1) * -1;				} else					_roll = roll_val;				if (pitch_val >> 15) {					_pitch = ((pitch_val ^ 0xFFFF) + 1) * -1;				} else {					_pitch = pitch_val;				}				dispatchEvent(new Event(Event.CHANGE));			}		}		public function addEventListener(type:String, listener:Function, useCapture:Boolean = false, priority:int = 0, useWeakReference:Boolean = false):void {			_dispatcher.addEventListener(type, listener, useCapture, priority);		}		public function dispatchEvent(evt:Event):Boolean {			return _dispatcher.dispatchEvent(evt);		}		public function hasEventListener(type:String):Boolean {			return _dispatcher.hasEventListener(type);		}		public function removeEventListener(type:String, listener:Function, useCapture:Boolean = false):void {			_dispatcher.removeEventListener(type, listener, useCapture);		}		public function willTrigger(type:String):Boolean {			return _dispatcher.willTrigger(type);		}		public function get compassOrientation():uint {			return _compassOrientation;		}		/* Heading, Pitch, Roll */		public function get heading():Number {			return _heading / 10.0; // 0.0 to 360.0		}		public function get pitch():Number {			return _pitch / 10.0; // -90.0 to 90.0		}		public function get roll():Number {			return _roll / 10.0; // -180.0 to 180.0		}		public function enterUserCalibrationMode():void {			_io.sendSysex(I2C_REQUEST, [WRITE, address, ENTER_USER_CALIBRATION_MODE]);		}		public function exitUserCalibrationMode():void {			_readOperationsEnabled = false;			if (_isReadContinuous) {				_io.sendSysex(I2C_REQUEST, [STOP_READING, address]);			}			_io.sendSysex(I2C_REQUEST, [WRITE, address, EXIT_USER_CALIBRATION_MODE]);			_timer.reset();			_timer.delay = RESPONCE_DELAY_TIME_50MS;			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onReadyToReEnableReadOperations);			_timer.start();		}		public function resetTheProcessor():void {			_readOperationsEnabled = false;			if (_isReadContinuous) {				_io.sendSysex(I2C_REQUEST, [STOP_READING, address]);			}			_io.sendSysex(I2C_REQUEST, [WRITE, address, RESET_THE_PROCESSOR]);			_timer.reset();			_timer.delay = RESPONCE_DELAY_TIME_500MS;			_timer.addEventListener(TimerEvent.TIMER_COMPLETE, onReadyToReEnableReadOperations);			_timer.start();		}		private function onReadyToReEnableReadOperations(e:TimerEvent):void {			_timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onReadyToReEnableReadOperations);			_readOperationsEnabled = true;			if (_isReadContinuous) {				_io.sendSysex(I2C_REQUEST, [READ_CONTINUOUS, address, READ_HEADING, 6]);			}		}	}}