module dcgen.testsuite.pass;

import tango.io.Stdout;
import passsimple;
import testsuite.main;
import Util = tango.text.Util;
import tango.stdc.stringz;

const int REPEAT_NUM = 10;

bool testSimple()
{
	int i = 54;
	bool b = true;
	char[] const_str = "Const strings are null-terminated";
	char[ REPEAT_NUM ] str = Util.repeat( ".", REPEAT_NUM ); // Make it a non-const string
	bool null_terminated = *(str.ptr + str.length) == '\0';
	outputLine( "Verifying that we have a string that's not null terminated: " ~ (null_terminated ? "Null terminated value!" : "Okay!") );
	
	outputLine( "Creating PassSimple class..." );
	auto pass = new PassSimple( 1, 2.3456, b, const_str.ptr );
	outputLine( "Calling setX..." );
	pass.setX( 41 );
	outputLine( "Calling setY..." );
	pass.setY( 41.41 );
	outputLine( "Calling setStr..." );
	pass.setStr( str );
	outputLine( "Calling setX..." );
	pass.setX( 42 );
	outputLine( "Calling setY..." );
	pass.setY( 42.42 );
	
	return true;
}

const expected_output =
`[D] Creating Pass class...
[C++] Class Pass constructed (x=1,x=2.345600)
[D] Calling setX...
[C++] Previous value of x: 1, new value: 41
[D] Calling setY...
[C++] Previous value of y: 2.345600, new value: 41.410000
[D] Calling setX...
[C++] Previous value of x: 41, new value: 42
[D] Calling setY...
[C++] Previous value of y: 41.410000, new value: 42.419998
[D] Cleaning up...`;

static this() {
	registerTest( &testSimple, expected_output );
}