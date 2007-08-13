﻿/**
 * A hardware abstraction layer for the Gainer I/O module v1.0
 * 
 * @see http://gainer.cc
 */

package funnel;

import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.util.Enumeration;

import com.illposed.osc.OSCBundle;
import com.illposed.osc.OSCMessage;

import gnu.io.CommPortIdentifier;
import gnu.io.SerialPort;
import gnu.io.SerialPortEvent;
import gnu.io.SerialPortEventListener;

public class GainerIO extends IOModule implements SerialPortEventListener {
	private SerialPort port;
	private InputStream input;
	private OutputStream output;

	private final int rate = 38400;
	private final int parity = SerialPort.PARITY_NONE;
	private final int databits = 8;
	private final int stopbits = SerialPort.STOPBITS_1;

	private funnel.BlockingQueue rebootCommandQueue;
	private funnel.BlockingQueue endCommandQueue;
	private funnel.BlockingQueue versionCommandQueue;
	private funnel.BlockingQueue ledCommandQueue;
	private funnel.BlockingQueue configCommandQueue;
	private funnel.BlockingQueue aoutCommandQueue;
	private funnel.BlockingQueue doutCommandQueue;

	private funnel.PortRange ainPortRange;
	private funnel.PortRange dinPortRange;
	private funnel.PortRange aoutPortRange;
	private funnel.PortRange doutPortRange;
	private funnel.PortRange buttonPortRange;

	private final static Integer CONFIGURATION_1[] = { PORT_AIN, PORT_AIN,
			PORT_AIN, PORT_AIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN,
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_DOUT, PORT_DOUT,
			PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DIN };
	private final static Integer CONFIGURATION_2[] = { PORT_AIN, PORT_AIN,
			PORT_AIN, PORT_AIN, PORT_AIN, PORT_AIN, PORT_AIN, PORT_AIN,
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_DOUT, PORT_DOUT,
			PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DIN };
	private final static Integer CONFIGURATION_3[] = { PORT_AIN, PORT_AIN,
			PORT_AIN, PORT_AIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN,
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT, PORT_AOUT, PORT_DOUT, PORT_DIN };
	private final static Integer CONFIGURATION_4[] = { PORT_AIN, PORT_AIN,
			PORT_AIN, PORT_AIN, PORT_AIN, PORT_AIN, PORT_AIN, PORT_AIN,
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT, PORT_AOUT, PORT_DOUT, PORT_DIN };
	private final static Integer CONFIGURATION_5[] = { PORT_DIN, PORT_DIN,
			PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN,
			PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN,
			PORT_DIN, PORT_DIN, };
	private final static Integer CONFIGURATION_6[] = { PORT_DOUT, PORT_DOUT,
			PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT,
			PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT,
			PORT_DOUT, PORT_DOUT, };
	private final static Integer CONFIGURATION_7[] = {
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 0]
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 1]
			PORT_AOUT, PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 2]
			PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 3]
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 4]
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 5]
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT,
			PORT_AOUT, // [0..7, 6]
			PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT, PORT_AOUT,
			PORT_AOUT, PORT_AOUT, // [0..7, 7]
	};
	private final static Integer CONFIGURATION_8[] = { PORT_DIN, PORT_DIN,
			PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN, PORT_DIN,
			PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT, PORT_DOUT,
			PORT_DOUT, PORT_DOUT, };

	private int configuration = 0;
	private float[] inputs;

	byte buffer[] = new byte[64];
	int bufferIndex;
	int bufferLast;
	int bufferSize = 64;

	private final static Integer LED_PORT = new Integer(16);
	private final static Float FLOAT_ZERO = new Float(0.0f);
	private int inputPortCounts = 0;

	public GainerIO(FunnelServer server, String serialPortName) {

		this.parent = server;
		parent.printMessage("Starting the Gainer I/O module...");

		try {
			Enumeration portList = CommPortIdentifier.getPortIdentifiers();

			while (portList.hasMoreElements()) {
				CommPortIdentifier portId = (CommPortIdentifier) portList
						.nextElement();

				if (portId.getPortType() == CommPortIdentifier.PORT_SERIAL) {
					if (portId.getName().equals(serialPortName)) {
						port = (SerialPort) portId.open("serial gainer", 2000);
						input = port.getInputStream();
						output = port.getOutputStream();
						port.setSerialPortParams(rate, databits, stopbits,
								parity);
						port.addEventListener(this);
						port.notifyOnDataAvailable(true);

						parent.printMessage("Gainer started on port "
								+ serialPortName);
					}
				}
			}
			if (port == null)
				printMessage("specified port was not found...");

		} catch (Exception e) {
			printMessage("connection error inside Serial. closing serialport...");
			e.printStackTrace();
			port = null;
			input = null;
			output = null;
		}
		rebootCommandQueue = new funnel.BlockingQueue();
		endCommandQueue = new funnel.BlockingQueue();
		versionCommandQueue = new funnel.BlockingQueue();
		ledCommandQueue = new funnel.BlockingQueue();
		configCommandQueue = new funnel.BlockingQueue();
		aoutCommandQueue = new funnel.BlockingQueue();
		doutCommandQueue = new funnel.BlockingQueue();
		ainPortRange = new funnel.PortRange();
		dinPortRange = new funnel.PortRange();
		aoutPortRange = new funnel.PortRange();
		doutPortRange = new funnel.PortRange();
		buttonPortRange = new funnel.PortRange();
	}

	public void dispose() {
		port.removeEventListener();
		printMessage("Disposing communication with the Gainer I/O module...");
		try {
			if (input != null)
				input.close();
			if (output != null)
				output.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
		input = null;
		output = null;

		try {
			if (port != null)
				port.close();
		} catch (Exception e) {
			e.printStackTrace();
		}
		port = null;
	}

	public Object[] getInputs(String address, Object[] arguments)
			throws IllegalArgumentException {
		int from = 0;
		int counts = inputs.length;

		if (address.equals("/in")) {
			from = (Integer) arguments[0];
			counts = (Integer) arguments[1];
		} else if (address.equals("/in/*")) {
			from = 0;
			counts = inputs.length;
		} else if (address.startsWith("/in/[")) {
			from = Integer
					.parseInt(address.substring(5, address.indexOf("..")));
			counts = Integer.parseInt(address.substring(
					address.indexOf("..") + 2, address.length() - 1))
					- from;
		}

		if ((from + counts) > inputs.length) {
			counts = inputs.length - from;
		}

		if ((from >= inputs.length) || (counts <= 0)) {
			throw new IllegalArgumentException("");
		}

		Object[] results = new Object[1 + counts];
		results[0] = new Integer(from);
		for (int i = 0; i < counts; i++) {
			results[1 + i] = new Float(inputs[from + i]);
		}
		return results;
	}

	public OSCBundle getAllInputsAsBundle() {
		if (inputs == null || !this.isPolling || this.inputPortCounts < 1) {
			return null;
		} else {
			OSCBundle bundle = new OSCBundle();

			if (ainPortRange.getCounts() > 0) {
				Object[] ainArguments = new Object[1 + ainPortRange.getCounts()];
				ainArguments[0] = new Integer(ainPortRange.getMin());
				for (int i = 0; i < ainPortRange.getCounts(); i++) {
					ainArguments[1 + i] = new Float(inputs[ainPortRange
							.getMin()
							+ i]);
				}
				bundle.addPacket(new OSCMessage("/in", ainArguments));
			}

			if (dinPortRange.getCounts() > 0) {
				Object[] dinArguments = new Object[1 + dinPortRange.getCounts()];
				dinArguments[0] = new Integer(dinPortRange.getMin());
				for (int i = 0; i < dinPortRange.getCounts(); i++) {
					dinArguments[1 + i] = new Float(inputs[dinPortRange
							.getMin()
							+ i]);
				}
				bundle.addPacket(new OSCMessage("/in", dinArguments));
			}

			if (buttonPortRange.getCounts() > 0) {
				Object[] buttonArguments = new Object[2];
				buttonArguments[0] = new Integer(buttonPortRange.getMin());
				buttonArguments[1] = new Float(inputs[buttonPortRange.getMin()]);
				bundle.addPacket(new OSCMessage("/in", buttonArguments));
			}

			return bundle;
		}
	}

	public void reboot() {
		write("Q*");
		rebootCommandQueue.pop(1000);
		rebootCommandQueue.sleep(100);
		write("?*");
		String versionString = (String) versionCommandQueue.pop(1000);
		printMessage("The I/O module rebooted successfully.");
		printMessage("Firmware version: " + versionString.substring(1, 9));
	}

	synchronized public void serialEvent(SerialPortEvent serialEvent) {
		if (serialEvent.getEventType() == SerialPortEvent.DATA_AVAILABLE) {
			try {
				while (input.available() > 0) {
					synchronized (buffer) {
						if (bufferLast == buffer.length) {
							byte temp[] = new byte[bufferLast << 1];
							System.arraycopy(buffer, 0, temp, 0, bufferLast);
							buffer = temp;
						}
						buffer[bufferLast++] = (byte) input.read();

						if (buffer[bufferLast - 1] == '*') {
							String command = readStringUntil('*');
							dispatch(command);
							clear();
						} else {
							continue;
						}
					}
				}
			} catch (IOException e) {

			}

		}
	}

	public void setConfiguration(Object[] arguments) {
		inputs = null;
		if (java.util.Arrays.equals(CONFIGURATION_1, arguments)) {
			configuration = 1;
			ainPortRange.setRange(0, 3);
			dinPortRange.setRange(4, 7);
			aoutPortRange.setRange(8, 11);
			doutPortRange.setRange(12, 15);
			buttonPortRange.setRange(17, 17);
			inputs = new float[18];
			inputPortCounts = ainPortRange.getCounts()
					+ dinPortRange.getCounts() + buttonPortRange.getCounts();
		} else if (java.util.Arrays.equals(CONFIGURATION_2, arguments)) {
			configuration = 2;
			ainPortRange.setRange(0, 7);
			dinPortRange.setRange(-1, -1);
			aoutPortRange.setRange(8, 11);
			doutPortRange.setRange(12, 15);
			buttonPortRange.setRange(17, 17);
			inputs = new float[18];
			inputPortCounts = ainPortRange.getCounts()
					+ dinPortRange.getCounts() + buttonPortRange.getCounts();
		} else if (java.util.Arrays.equals(CONFIGURATION_3, arguments)) {
			configuration = 3;
			ainPortRange.setRange(0, 3);
			dinPortRange.setRange(4, 7);
			aoutPortRange.setRange(8, 15);
			doutPortRange.setRange(-1, -1);
			buttonPortRange.setRange(17, 17);
			inputs = new float[18];
			inputPortCounts = ainPortRange.getCounts()
					+ dinPortRange.getCounts() + buttonPortRange.getCounts();
		} else if (java.util.Arrays.equals(CONFIGURATION_4, arguments)) {
			configuration = 4;
			ainPortRange.setRange(0, 7);
			dinPortRange.setRange(-1, -1);
			aoutPortRange.setRange(8, 15);
			doutPortRange.setRange(-1, -1);
			buttonPortRange.setRange(17, 17);
			inputs = new float[18];
			inputPortCounts = ainPortRange.getCounts()
					+ dinPortRange.getCounts() + buttonPortRange.getCounts();
		} else if (java.util.Arrays.equals(CONFIGURATION_5, arguments)) {
			configuration = 5;
			ainPortRange.setRange(-1, -1);
			dinPortRange.setRange(0, 15);
			aoutPortRange.setRange(-1, -1);
			doutPortRange.setRange(-1, -1);
			buttonPortRange.setRange(-1, -1);
			inputs = new float[16];
			inputPortCounts = dinPortRange.getCounts();
		} else if (java.util.Arrays.equals(CONFIGURATION_6, arguments)) {
			configuration = 6;
			ainPortRange.setRange(-1, -1);
			dinPortRange.setRange(-1, -1);
			aoutPortRange.setRange(-1, -1);
			doutPortRange.setRange(0, 15);
			buttonPortRange.setRange(-1, -1);
			inputs = new float[16];
			inputPortCounts = 0;
		} else if (java.util.Arrays.equals(CONFIGURATION_7, arguments)) {
			configuration = 7;
			ainPortRange.setRange(0, 63);
			dinPortRange.setRange(-1, -1);
			aoutPortRange.setRange(-1, -1);
			doutPortRange.setRange(-1, -1);
			buttonPortRange.setRange(-1, -1);
			inputs = new float[64];
			inputPortCounts = 0;
		} else if (java.util.Arrays.equals(CONFIGURATION_8, arguments)) {
			configuration = 8;
			ainPortRange.setRange(-1, -1);
			dinPortRange.setRange(0, 7);
			aoutPortRange.setRange(-1, -1);
			doutPortRange.setRange(8, 15);
			buttonPortRange.setRange(-1, -1);
			inputs = new float[16];
			inputPortCounts = dinPortRange.getCounts();
		} else {
			throw new IllegalArgumentException(
					"Can't find such a configuration");
		}
		write("KONFIGURATION_" + configuration + "*");
		String configurationString = (String) configCommandQueue.pop(1000);
		printMessage("configuration: " + configurationString);
		configCommandQueue.sleep(100);
	}

	public void setOutput(Object[] arguments) {
		// printMessage("arguments: " + arguments[0] + ", " + arguments[1]);
		int start = (Integer) arguments[0];
		for (int i = 0; i < (arguments.length - 1); i++) {
			int port = start + i;
			int index = 1 + i;
			if (doutPortRange.contains(port)) {
				if (arguments[index] != null
						&& arguments[index] instanceof Float) {
					if (FLOAT_ZERO.equals(arguments[index])) {
						setDigitalOutputLow(port);
					} else {
						setDigitalOutputHigh(port);
					}
				}
			} else if (aoutPortRange.contains(port)) {
				if (arguments[index] != null
						&& arguments[index] instanceof Float) {
					setAnalogOutput(port,
							(int) ((Float) arguments[index] * 255.0f));
				}
			} else if (LED_PORT.equals(port)) {
				if (FLOAT_ZERO.equals(arguments[index])) {
					write("l*");
					ledCommandQueue.pop(1000);
				} else {
					write("h*");
					ledCommandQueue.pop(1000);
				}
			}
		}
	}

	public void setPolling(Object[] arguments) {
		if (arguments[0] instanceof Integer) {
			if (new Integer(1).equals(arguments[0])) {
				startPolling();
			} else {
				stopPolling();
			}
		} else {
			throw new IllegalArgumentException(
					"The first argument of /polling is not an integer value");
		}
	}

	public void startPolling() {
		if (port == null) {
			return;
		}

		if (ainPortRange.getCounts() > 0) {
			printMessage("polling started: ain");
			write("i*");
		}
		configCommandQueue.sleep(100);
		if (dinPortRange.getCounts() > 0) {
			printMessage("polling started: din");
			write("r*");
		}
		this.isPolling = true;
	}

	public void stopPolling() {
		if (port == null) {
			return;
		}

		this.isPolling = false;
		printMessage("polling stopped");
		write("E*");
		endCommandQueue.pop(1000);
	}

	// バッファを空にする
	private void clear() {
		bufferLast = 0;
		bufferIndex = 0;
	}

	private void dispatch(String command) {
		if (command.equals("Q*")) {
			rebootCommandQueue.push(new Integer(0));
		} else if (command.equals("E*")) {
			endCommandQueue.push(new Integer(0));
		} else if (command.startsWith("?")) {
			versionCommandQueue.push(command);
		} else if (command.startsWith("KONFIGURATION_")) {
			configCommandQueue.push(command);
		} else if (command.equals("h*") || command.equals("l*")) {
			ledCommandQueue.push(command);
		} else if (command.startsWith("a") || command.startsWith("A")) {
			aoutCommandQueue.push(command);
		} else if (command.startsWith("H") || command.startsWith("L")
				|| command.startsWith("D")) {
			doutCommandQueue.push(command);
		} else if (command.startsWith("i") || command.startsWith("I")) {
			String value;
			for (int i = 0; i < ainPortRange.getCounts(); i++) {
				value = command.substring(2 * i + 1, 2 * (i + 1) + 1);
				inputs[ainPortRange.getMin() + i] = (float) Integer.parseInt(
						value, 16) / 255.0f;
			}
		} else if (command.startsWith("r") || command.startsWith("R")) {
			int value = Integer.parseInt(command.substring(1, 5), 16);
			for (int i = 0; i < dinPortRange.getCounts(); i++) {
				int c = 1 & (value >> i);
				if (c == 1) {
					inputs[dinPortRange.getMin() + i] = 1.0f;
				} else {
					inputs[dinPortRange.getMin() + i] = 0.0f;
				}
			}
		} else if (command.equals("F*") || command.equals("N*")) {
			inputs[buttonPortRange.getMin()] = command.equals("N*") ? 1.0f
					: 0.0f;
		} else {
			System.out.print("unknown: " + command);
		}
	}

	// 指定した文字までバッファを読みバイト列で返す
	private byte[] readBytesUntil(int interesting) {
		if (bufferIndex == bufferLast)
			return null;
		byte what = (byte) interesting;

		synchronized (buffer) {
			int found = -1;
			for (int k = bufferIndex; k < bufferLast; k++) {
				if (buffer[k] == what) {
					found = k;
					break;
				}
			}
			if (found == -1)
				return null;

			int length = found - bufferIndex + 1;
			byte outgoing[] = new byte[length];
			System.arraycopy(buffer, bufferIndex, outgoing, 0, length);

			bufferIndex = 0; // rewind
			bufferLast = 0;
			return outgoing;
		}
	}

	// 指定した文字までバッファを読み文字列で返す
	private String readStringUntil(int interesting) {
		byte b[] = readBytesUntil(interesting);
		if (b == null)
			return null;
		return new String(b);
	}

	private void setAnalogOutput(int ch, int value) {
		if (aoutPortRange.contains(ch)) {
			String s = "a" + Integer.toHexString(ch).toUpperCase();
			value = value < 0 ? 0 : value;
			value = value > 255 ? 255 : value;

			String sv = value < 16 ? "0" : "";
			sv += Integer.toHexString(value).toUpperCase();
			s += sv;
			s += "*";
			write(s);
			aoutCommandQueue.pop(1000);
		} else {
			throw new IndexOutOfBoundsException(
					"Gainer error!! out of bounds analog out");
		}
	}

	private void setAnalogOutput(int[] values) {
		String s = "A";
		String sv = "";
		if (aoutPortRange.getCounts() == values.length) {
			for (int i = 0; i < values.length; i++) {
				values[i] = values[i] < 0 ? 0 : values[i];
				values[i] = values[i] > 255 ? 255 : values[i];
				sv = values[i] < 16 ? "0" : "";
				sv += Integer.toHexString(values[i]).toUpperCase();
				s += sv;
			}
			s += "*";
		} else {
			throw new IndexOutOfBoundsException(
					"Gainer error!! - number of analog outputs are wrong");
		}
		write(s);
		aoutCommandQueue.pop(1000);
	}

	private void setDigitalOutput(boolean[] values) {
		int chs = 0;
		if (doutPortRange.getCounts() == values.length) {
			for (int i = 0; i < values.length; i++) {
				if (values[i]) {
					chs |= (1 << i);
				}
			}
		} else {
			throw new IndexOutOfBoundsException("Out of bounds: dout");
		}
		String val = Integer.toHexString(chs).toUpperCase();
		String sv = "";
		for (int i = 0; i < doutPortRange.getCounts() - val.length(); i++) {
			sv += "0";
		}
		sv += val;

		String s = "D" + sv + "*";
		write(s);
		doutCommandQueue.pop(1000);
	}

	private void setDigitalOutput(int chs) {
		if (chs <= 0xFFFF) {
			String val = Integer.toHexString(chs).toUpperCase();
			String sv = "";
			// ïKÇ∏4åÖ
			for (int i = 0; i < 4 - val.length(); i++) {
				sv += "0";
			}
			sv += val;

			String s = "D" + sv + "*";
			write(s);
			doutCommandQueue.pop(1000);
		} else {
			throw new IndexOutOfBoundsException("Out of bounds: dout");
		}
	}

	private void setDigitalOutputHigh(int ch) {
		if (doutPortRange.contains(ch)) {
			String s = "H" + Integer.toHexString(ch).toUpperCase() + "*";
			write(s);
			doutCommandQueue.pop(1000);
		} else {
			throw new IndexOutOfBoundsException(
					"Gainer error!! out of bounds digital out");
		}
	}

	private void setDigitalOutputLow(int ch) {
		if (doutPortRange.contains(ch)) {
			String s = "L" + Integer.toHexString(ch).toUpperCase() + "*";
			write(s);
			doutCommandQueue.pop(1000);
		} else {
			throw new IndexOutOfBoundsException(
					"Gainer error!! out of bounds digital out");
		}
	}

	private void write(String what) {
		try {
			output.write(what.getBytes());
			output.flush();
		} catch (Exception e) {
			e.printStackTrace();
		}
	}
}
