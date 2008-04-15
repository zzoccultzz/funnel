package processing.funnel;

import java.util.Vector;

/**
 * @author endo
 * @version 1.0
 * 
 */
public final class Configuration{

	int[] portStatus;
	final int moduleID;
	final String moduleName;
	
	Vector outputPorts = new Vector();
	
	public Configuration(int moduleID, int[] config,String moduleName){
		this.moduleID = moduleID;
		this.moduleName = moduleName;
		portStatus = config;
	}


	
	public int[] getPortStatus(){
		return portStatus;
	}
	
	public int getModuleID(){
		return moduleID;
	}
	
	public String getModuleName(){
		return moduleName;
	}
	
	/**
	 * ARDUINOのDigitalPinを設定する
	 * （IOSystem作成後再設定はできません）
	 */
	public boolean setDigitalPinMode(int n,int digitalType){
		if(moduleName.equalsIgnoreCase(Arduino.moduleName)){
			portStatus[Arduino._digitalPin[n]] = digitalType;
			return true;
		}
		return false;
		
	}
	
	
	
	

}
