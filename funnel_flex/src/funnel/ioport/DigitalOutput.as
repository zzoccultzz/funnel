package funnel.ioport
{
	public class DigitalOutput extends OutputPort
	{
		override public function get type():uint {
			return PortType.DIGITAL;
		}
		
		
	}
}