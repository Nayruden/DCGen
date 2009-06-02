module dcgen.testsuite.pass;

import tango.io.Stdout;
import Pass;
import testsuite.main;

bool runTests()
{
	outputLine( "Creating Pass class..." );
	Pass pass = new Pass( 1, 2.3456 );
	outputLine( "Calling setX..." );
	pass.setX( 41 );
	outputLine( "Calling setY..." );
	pass.setY( 41.41 );
	outputLine( "Calling setX..." );
	pass.setX( 42 );
	outputLine( "Calling setY..." );
	pass.setY( 42.42 );
	outputLine( "Cleaning up..." );
	
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
	registerTest( &runTests, expected_output );
}