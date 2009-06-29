﻿package funnel{	import flash.events.Event;	import flash.events.EventDispatcher;	import flash.events.IOErrorEvent;		import funnel.gui.IOModuleGUI;	import funnel.osc.*;		/**	 * @copy FunnelEvent#READY	 */	[Event(name="ready",type="FunnelEvent")]		/**	 * @copy FunnelErrorEvent#ERROR	 */	[Event(name="error",type="FunnelErrorEvent")]		/**	 * @copy FunnelErrorEvent#CONFIGURATION_ERROR	 */	[Event(name="configurationError",type="FunnelErrorEvent")]		/**	 * @copy FunnelErrorEvent#REBOOT_ERROR	 */	[Event(name="rebootError",type="FunnelErrorEvent")]		/**	 * 複数のI/Oモジュールから構成されるシステムを表現するためのクラスです。 	 */	public class IOSystem extends EventDispatcher	{			/**		* 出力ポートを手動で更新する場合はfalseにします。		* @default true		*/				public var autoUpdate:Boolean;		private var _modules:Object;		private var _commandPort:*;		private var _samplingInterval:int;		private var _task:Task;		private var _host:String;		private var _portNum:Number;		/**		 * @param configs Configuration配列		 * @param host ホスト名		 * @param portNum ポート番号		 * @param samplingInterval サンプリング間隔(ms)		 */		public function IOSystem(configs:Array, host:String = "localhost", portNum:Number = 9000, samplingInterval:int = 33) {			autoUpdate = true;			_modules = {};			_commandPort = new CommandPort();			_task = new Task().complete();			_task.addCallback(_commandPort.connect, host, portNum);			_task.addCallback(sendInitCommands, new FunnelEvent(FunnelEvent.READY));			_host = host;			_portNum = portNum;			_commandPort.addEventListener(IOErrorEvent.IO_ERROR, handleSocketConnectionError);			for each (var config:Configuration in configs) {				var id:uint = config.moduleID;				_modules[id] = new IOModule(this, config);			}			this.samplingInterval = samplingInterval;		}		private function sendInitCommands(e:Event):void {			sendReset();			_commandPort.addEventListener(Event.CHANGE, onReceiveInput);			_commandPort.addEventListener(SysexEvent.SYSEX, onSysexMessage);			for each (var ioModule:IOModule in _modules) {				sendConfiguration(ioModule.id, ioModule.configuration.config);			}			sendPolling(true);			_task.addCallback(dispatchEvent, new FunnelEvent(FunnelEvent.READY));			_task.addErrback(dispatchEvent);		}		private function handleSocketConnectionError(e:Event):void {			for each (var ioModule:IOModule in _modules) {				if (ioModule.gui != null) {					ioModule.gui.setControllerMode();					ioModule.gui.addEventListener(Event.CHANGE, onReceiveInputFromGUI);				}			}		}				/**		 * moduleNumで指定した番号のI/Oモジュールを取得します。		 * @param moduleNum I/Oモジュールの番号。このIDは、Configuration#moduleIDと同じものを指定します。		 * @return moduleNumで指定したIOModuleオブジェクト		 * @see IOModule		 * @see Configuration#moduleID		 */				public function ioModule(moduleNum:uint):IOModule {			return _modules[moduleNum];		}				/**		 * サンプリング間隔		 * @default 33		 */				public function get samplingInterval():int {			return _samplingInterval;		}					public function set samplingInterval(val:int):void {			_samplingInterval = val;			sendSamplingInterval(val);		}				/**		 * 全ての出力ポートの値を更新します。通常、autoUpdateをfalseに設定して利用します。		 * @see IOSystem#autoUpdate		 */				public function update():void {			for each (var module:IOModule in _modules) {				module.update();			}		}				private function onReceiveInput(event:Event):void {			var message:OSCMessage = _commandPort.inputMessage;			var pinValues:Array = message.value;			var module:IOModule = _modules[pinValues[0].value];			var startPinNum:uint = pinValues[1].value;			for (var j:uint = 0; j < pinValues.length - 2; ++j) {				var aPin:Pin = module.pin(startPinNum + j);				var type:uint = aPin.type;				if (type == Pin.AIN || type == Pin.DIN) {					aPin.value = pinValues[j + 2].value;					if (module.gui != null) {						module.gui.setValue(aPin.number, aPin.value);					}				}			}		}		private function onReceiveInputFromGUI(event:Event):void {			var gui:IOModuleGUI = event.target as IOModuleGUI;			var message:OSCMessage = gui.inputMessage;			var pinValues:Array = message.value;			var module:IOModule = _modules[pinValues[0].value];			var startPinNum:uint = pinValues[1].value;			for (var j:uint = 0; j < pinValues.length - 2; ++j) {				var aPin:Pin = module.pin(startPinNum + j);				var type:uint = aPin.type;				if (type == Pin.AIN || type == Pin.DIN) {					aPin.value = pinValues[j + 2].value;				}			}		}		private function onSysexMessage(event:Event):void {			var message:OSCMessage = _commandPort.inputMessage;			var sysexMessage:Array = message.value;			var module:IOModule = _modules[sysexMessage.shift()];			var command:uint = sysexMessage.shift();			module.handleSysex(command, sysexMessage);		}		private function sendReset():void {			_task.addCallback(_commandPort.writeCommand, new OSCMessage("/reset"));		}				private function sendConfiguration(moduleNum:uint, config:Array):void {			var msg:OSCMessage = new OSCMessage("/configure", new OSCInt(moduleNum));			for each (var pinType:uint in config) {				msg.addValue(new OSCInt(pinType));			}			_task.addCallback(_commandPort.writeCommand, msg);		}				private function sendSamplingInterval(interval:int):void {			_task.addCallback(_commandPort.writeCommand, new OSCMessage("/samplingInterval", new OSCInt(interval)));		}				private function sendPolling(enabled:Boolean):void {			_task.addCallback(_commandPort.writeCommand, new OSCMessage("/polling", new OSCInt(enabled ? 1 : 0)));		}				/**		 * @private		 */				internal function sendOut(moduleNum:uint, pinNum:uint, pinValues:Array):void {			var message:OSCMessage = new OSCMessage("/out", new OSCInt(moduleNum), new OSCInt(pinNum));			for (var i:uint = 0; i < pinValues.length; ++i) {				message.addValue(new OSCFloat(pinValues[i]));			}			_task.addCallback(_commandPort.writeCommand, message);		}				internal function sendSysex(moduleNum:uint, command:uint, sysexMessage:Array):void {			var message:OSCMessage = new OSCMessage("/sysex/request", new OSCInt(moduleNum), new OSCInt(command));			for (var i:uint = 0; i < sysexMessage.length; ++i) {				message.addValue(new OSCInt(sysexMessage[i]));			}			_task.addCallback(_commandPort.writeCommand, message);		}	}}