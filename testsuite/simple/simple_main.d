module dcgen.testsuite.simple;

import tango.io.Stdout;
import Simple;

void main()
{
	Stdout( "[D] Creating Simple class..." ).newline;
	Simple simple = new Simple;
	Stdout( "[D] Calling foobar..." ).newline;
	simple.foobar();
	Stdout( "[D] Cleaning up..." ).newline;
}