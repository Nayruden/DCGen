module main;

import test;
import tango.io.Stdout;

void main()
{
	auto a = new A();
	Stdout.formatln( "{} {}", a.odd( 0 ), a.odd( 1 ) );
}