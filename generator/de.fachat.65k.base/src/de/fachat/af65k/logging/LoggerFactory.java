package de.fachat.af65k.logging;

public class LoggerFactory {

	public static Logger getLogger(Class clazz) {
		return new LoggerImpl();
	}
}
