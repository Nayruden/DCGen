module dcgen.testsuite.pass;

import tango.io.Stdout;
import passsimple;
import testsuite.main;
import Util = tango.text.Util;
import Integer = tango.text.convert.Integer;
import tango.stdc.stringz;

const int REPEAT_NUM = 10;

bool testSimple()
{
	char[ REPEAT_NUM ] str = Util.repeat( ".", REPEAT_NUM ); // Make it a non-const string
	bool null_terminated = *(str.ptr + str.length) == '\0';
	outputLine( "Verifying that we have a string that's not null terminated: " ~ (null_terminated ? "Null terminated value!" : "Okay!") );
	
	outputLine( "Creating PassSimple class..." );
	auto pass = new PassSimple( 1, 2.3456, true, "Const strings are null-terminated" );
	outputLine( "Calling setX..." );
	int x = pass.setX( 41 );
	outputLine( "setX returned: " ~ Integer.toString( x ) );
	outputLine( "Calling setY..." );
	float y = pass.setY( 41.41 );
	outputLine( "setY returned: " ~ Integer.toString( cast (long)y ) );
	outputLine( "Calling setB..." );
	bool b = pass.setB( false );
	outputLine( "setB returned: " ~ (b ? "true" : "false") );
	outputLine( "Calling setStr..." );
	char[] str_ret = pass.setStr( str );
	outputLine( "setStr returned: " ~ str_ret );
	outputLine( "Calling setX..." );
	x = pass.setX( 42 );
	outputLine( "setX returned: " ~ Integer.toString( x ) );
	outputLine( "Calling setY..." );
	y = pass.setY( 42.41 );
	outputLine( "setY returned: " ~ Integer.toString( cast (long)y ) );
	
	return true;
}

const expected_output =
`[D] Verifying that we have a string that's not null terminated: Null terminated value!
[D] Creating PassSimple class...
[C++] Class Pass constructed (x=1,y=2.345600,b=true,str=Const strings are null-terminated)
[D] Calling setX...
[C++] Previous value of x: 1, new value: 41
[D] setX returned: 1
[D] Calling setY...
[C++] Previous value of y: 2.345600, new value: 41.410000
[D] setY returned: 2
[D] Calling setB...
[C++] Previous value of b: true, new value: false
[D] setB returned: true
[D] Calling setStr...
[C++] Previous value of str: Const strings are null-terminated, new value: ..........
[D] setStr returned: Const strings are null-terminated
[D] Calling setX...
[C++] Previous value of x: 41, new value: 42
[D] setX returned: 41
[D] Calling setY...
[C++] Previous value of y: 41.410000, new value: 42.410000
[D] setY returned: 41`;

static this() {
	registerTest( &testSimple, expected_output );
}