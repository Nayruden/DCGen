module dcgen.testsuite.simple;

import tango.io.Stdout;
import Simple;
import testsuite.main;

bool runTests()
{
	outputLine( "Creating Simple class..." );
	Simple simple = new Simple;
	outputLine( "Calling foobar..." );
	simple.foobar();
	outputLine( "Cleaning up..." );
	
	return true;
}

const expected_output =
`[D] Creating Simple class...
[C++] Class Simple constructed
[D] Calling foobar...
[C++] Foobar called
[D] Cleaning up...
`;

static this() {
	registerTest( &runTests, expected_output );
}