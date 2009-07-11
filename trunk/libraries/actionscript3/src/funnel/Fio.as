package funnel {	import flash.events.TimerEvent;	import flash.utils.Timer;	/**	 * FioクラスはFunnel I/Oモジュールを扱うためのクラスです。	 *	 */	public class Fio extends IOSystem {		/**		 * 全てのモジュールを表します。fio.module(ALL).pin(10).value = xのようにすることで、全モジュールの10番目のピンの値をxに設定します。		 */		public static const ALL:uint = 0xFFFF;		/**		 * Fio用のデフォルトのコンフィギュレーションを取得します。		 * @return Configurationオブジェクト		 */		public static function get FIRMATA():Configuration {			var k:Configuration = new Configuration();			k.config = [				DOUT, DOUT, DOUT, AOUT, DOUT, AOUT, AOUT,				DOUT, DOUT, AOUT, AOUT, AOUT, DOUT, DOUT,				AIN, AIN, AIN, AIN, AIN, AIN, AIN, AIN			];			k.analogPins = [14, 15, 16, 17, 18, 19, 20, 21];			k.digitalPins = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21];			return k;		}		/**		 * @param nodes 利用するモジュールのID配列		 * @param config コンフィギュレーション		 * @param host ホスト名		 * @param portNum ポート番号		 * @param samplingInterval サンプリング間隔(ms)		 */		public function Fio(nodes:Array = null, config:Configuration = null, host:String = "localhost", portNum:Number = 9000, samplingInterval:int = 33) {			if (nodes == null) nodes = [];			if (config == null) config = Fio.FIRMATA;			nodes.push(ALL);			var configs:Array = [];			for each (var id:uint in nodes) {				var c:Configuration = config.clone();				c.moduleID = id;				configs.push(c);			}			super(configs, host, portNum, samplingInterval);			if (config.powerPinsEnabled) {				var timer:Timer = new Timer(I2C_POWER_PINS_STARTUP_TIME, 1);				timer.addEventListener(TimerEvent.TIMER_COMPLETE, function(e:TimerEvent):void {					dispatchEvent(new FunnelEvent(FunnelEvent.I2C_POWER_PINS_READY));				});				timer.start();			}		}	}}