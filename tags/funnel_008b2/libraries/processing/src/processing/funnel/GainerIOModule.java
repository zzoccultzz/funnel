package processing.funnel;

import processing.core.PApplet;
import java.lang.reflect.Method;

/**
 * @author endo
 * @version 1.0
 * 
 */
public class GainerIOModule extends IOModule{
	
	Method gainerButtonEventMethod = null;
	
	private GainerPort port[];

	
	
	public GainerIOModule(PApplet parent,int id,Configuration config,String name){
		super(parent,id,config,name);

		
		int[] conf = config.getPortStatus();
		
		port = new GainerPort[conf.length];
		for(int i=0;i<port.length;i++){
			port[i] = new GainerPort(parent,conf[i],i);
		}
		
		try {
			gainerButtonEventMethod = 
				parent.getClass().getMethod("gainerButtonEvent",new Class[] { Boolean.TYPE });
		} catch (Exception e) {
		  // no such method, or an error.. which is fine, just ignore
		}	
	}
	
	//Portそのものを返す
	public Port port(int nPort){
		if(nPort<port.length){
			return port[nPort];
		}
		return null;
	}
	
	
	public class GainerPort extends IOModule.Port{
	
		public GainerPort(PApplet parent, int type, int n){
			super(parent,type,n);
		}
		
		public void updateValueInput(float value){
			lastValue = this.value;
			if(this.value != value){
				this.value = value;

				if(onChange != null && lastValue != this.value){
					try{
						onChange.invoke(parent,new Object[]{ new PortEvent(this) });
					}catch(Exception e){
						e.printStackTrace();
						onChange = null;
						errorMessage("onChange handler error !!");
					}
				}
				
				if(gainerButtonEventMethod != null && lastValue != this.value && number == Gainer.button){
					try{
						if(this.value==0){
							gainerButtonEventMethod.invoke(parent,new Object[]{ new Boolean(false) });
						}else{
							gainerButtonEventMethod.invoke(parent,new Object[]{ new Boolean(true) });
						}
					}catch(Exception e){
						e.printStackTrace();
						onChange = null;
						errorMessage("gainerButtonEvent handler error !!");
					}
				}
			}
		}
		
	}
}
