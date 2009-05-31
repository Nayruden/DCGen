module dcgen.testsuite.main;

import tango.io.Stdout;
import tango.io.device.File;
import Util = tango.text.Util;

const char FILE_PATH[] = "./output.txt";
File file;
alias bool function() callbacktype;

struct TestInfo {
	callbacktype callback;
	char[] expected_output;
}

TestInfo[] tests;

void main()
{
	foreach( test; tests ) {
		auto succeeded = test.callback();
		file.seek( 0 );
		auto file_content = Util.trim( cast (char[]) file.load );
		
		if ( !succeeded )
			Stdout( "-- Test failed --" ).newline;
		else if ( test.expected_output != file_content ) {
			Stdout( "-- Test failed, did not get expected output (listed below) --" ).newline;
			Stdout( test.expected_output );
			Stdout( "-- Test failed --" ).newline;
		}
		else {
			Stdout( "-- Test passed -- " ).newline;
		}
		
		// Delete file
	}
}

void outputLine( char[] str = "" )
{
	file.seek( 0, File.Anchor.End );
	file.write( "[D] " ~ str ~ "\n" );
	file.flush();
	Stdout( "[D] " ~ str ).newline;
}

void registerTest( callbacktype callback, char[] expected_output )
{
	TestInfo test;
	test.callback = callback;
	test.expected_output = Util.trim( expected_output );
	
	tests ~= test;
}

static this()
{
	file = new File( FILE_PATH, File.ReadWriteCreate );
}