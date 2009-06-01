module dcgen.testsuite.main;

import tango.io.Stdout;
import tango.io.device.File;
import Util = tango.text.Util;
import tango.io.FilePath;

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
		file.seek( 0 ); // Rewind
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
	}
}

void outputLine( char[] str = "" )
{
	// We need to seek and flush because we're writing to this file from two languages
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

static ~this()
{
	FilePath( FILE_PATH ).remove(); // Delete our output file
}