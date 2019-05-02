package de.fachat.af65k.logging;

import java.text.FieldPosition;
import java.text.Format;
import java.text.MessageFormat;
import java.text.ParsePosition;
import java.util.logging.SimpleFormatter;

public class LoggerImpl extends BaseLogger implements Logger {

	@Override
	public void error(String fmt, Object... args) {
		
		super.error(MessageFormat.format(fmt, args));		
	}

	@Override
	public void info(String fmt, Object... args) {
		
		super.info(MessageFormat.format(fmt, args));		
	}

	
}
