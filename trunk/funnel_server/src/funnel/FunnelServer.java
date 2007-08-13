package funnel;

/**
 * FunnelServer
 *
 * @author Funnel Development Team
 * @version 0.0.7
 */

import java.awt.Font;
import java.awt.Frame;
import java.awt.Insets;
import java.awt.TextArea;
import java.awt.event.WindowAdapter;
import java.awt.event.WindowEvent;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileReader;
import java.util.Locale;
import java.util.Map;

import org.jvyaml.YAML;

public class FunnelServer extends Frame {

	private CommandPortServer commandPortServer;
	private NotificationPortServer notificationPortServer;
	private IOModule ioModule = null;
	private TextArea loggingArea;
	private boolean logEnable = false;
	private final int width = 480;
	private final int height = 270;

	public FunnelServer() {
		super();

		// Close the I/O module when the window is closed
		addWindowListener(new WindowAdapter() {
			public void windowClosing(WindowEvent evt) {
				ioModule.stopPolling();
				System.exit(0);
			}
		});

		// Create the GUI elements
		setTitle("FunnelServer");
		setSize(width, height);
		show();
		setLayout(null);
		setResizable(false);
		loggingArea = new TextArea("FunnelServer\n", 5, 10,
				TextArea.SCROLLBARS_VERTICAL_ONLY);
		Insets insets = this.getInsets();
		loggingArea.setBounds(insets.left, insets.top, width
				- (insets.left + insets.right), height
				- (insets.top + insets.bottom));
		loggingArea.setEditable(false);
		loggingArea.setFont(new Font("Monospaced", Font.PLAIN, 12));
		this.add(loggingArea);

		printMessage("Funnel is developed by the Funnel development team, and");
		printMessage("distributed under the New BSD License.");
		printMessage("");

		printMessage("Acknowledgements:");
		printMessage("Funnel is supported by Exploratory Software Project 2007 of IPA");
		printMessage("Funnelは未踏ソフトウェア創造事業の支援を受けました");
		printMessage("");

		String type = "";
		String commandPort = "9000";
		String notificationPort = "9001";
		String serialPort = "";

		try {
			Map settings = (Map) YAML.load(new FileReader("settings.yaml"));
			printMessage("Settings:");

			Map serverSettings = (Map) settings.get("server");
			if (serverSettings.get("command port") == null) {
				commandPort = "9000";
			} else {
				commandPort = serverSettings.get("command port").toString();
				printMessage("command port:" + commandPort);
			}
			if (serverSettings.get("notification port") == null) {
				notificationPort = "9001";
			} else {
				notificationPort = serverSettings.get("notification port")
						.toString();
				printMessage("notification port:" + notificationPort);
			}

			Map modules = (Map) settings.get("io");
			printMessage("type:" + modules.get("type"));
			printMessage("com:" + modules.get("com"));
			printMessage("");

			if (modules.get("type") == null) {
				printMessage("Since a type is not specified, use the default type (i.e. Gainer).");
				type = "Gainer";
			} else {
				type = modules.get("type").toString();
			}

			if (modules.get("com") == null) {
				printMessage("Since a serial port is not specified, use an automatically detected port.");
				serialPort = IOModule.getSerialPortName();
			} else {
				serialPort = modules.get("com").toString();
			}
		} catch (FileNotFoundException e) {
			printMessage("Since no settings file was found, use default settings instead.");
			commandPort = "9000";
			notificationPort = "9001";
			serialPort = IOModule.getSerialPortName();
		}

		// Dump read setting from the settings file
		printMessage("command server port: " + commandPort);
		printMessage("notification server port: " + notificationPort);
		printMessage("serial port: " + serialPort);
		commandPortServer = new CommandPortServer(this, Integer
				.parseInt(commandPort));
		commandPortServer.start();
		notificationPortServer = new NotificationPortServer(this, Integer
				.parseInt(notificationPort));
		notificationPortServer.start();
		if (type.equalsIgnoreCase("Gainer")) {
			ioModule = new GainerIO(this, serialPort);
			ioModule.reboot();
		} else if (type.equalsIgnoreCase("Arduino")) {
			ioModule = new ArduinoIO(this, serialPort);
			ioModule.reboot();
		}
	}

	public IOModule getIOModule() {
		return ioModule;
	}

	// Print a message on the logging console
	public void printMessage(String msg) {
		loggingArea.append(msg + "\n");
	}

	// This is the start point of this application
	public static void main(String[] args) {
		String libPath = System.getProperty("java.library.path");
		System.out.println("library path: " + libPath);
		String classPath = System.getProperty("java.class.path");
		System.out.println("class path: " + classPath);
		System.out.println("current directory: "
				+ new File(".").getAbsolutePath());

		Locale locale = Locale.getDefault();
		System.out.println("国：" + locale.getDisplayCountry());
		System.out.println("国／地域コード：" + locale.getCountry());
		System.out.println("言語：" + locale.getDisplayLanguage());
		System.out.println("言語コード：" + locale.getLanguage());
		System.out.println("ロケールの名前：" + locale.getDisplayName());
		System.out.println("プログラム上の名前：" + locale.toString());

		new FunnelServer();
	}
}
