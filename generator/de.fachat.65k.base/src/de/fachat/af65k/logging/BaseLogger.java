package de.fachat.af65k.logging;

public abstract class BaseLogger {

	public void error(String msg) {
		System.err.println(msg);
	}

	public void info(String msg) {
		System.out.println(msg);
	}

}
