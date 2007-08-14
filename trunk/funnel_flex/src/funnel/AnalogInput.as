package funnel
{
	public class AnalogInput extends Port
	{
		private var _sampleCount:uint = 0;
		private var _sum:Number = 0;
		
		public function AnalogInput(funnel:Funnel, commandPort:CommandPort, portNum:uint) {
			super(funnel, commandPort, portNum);
			minimum = Number.MAX_VALUE;
			maximum = 0;
		}
		
		override public function get direction():uint {
			return PortDirection.INPUT;
		}
		
		override public function get type():uint {
			return PortType.ANALOG;
		}
		
		internal function setInputValue(val:Number):void {
			minimum = Math.min(val, minimum);
			maximum = Math.max(val, maximum);
			_sum += val;
			average = _sum / (++_sampleCount);
			detectEdge(val);
		    _value = val;
		}
	}
}