module dcgen.main;

import defines;
import tango.io.device.FileConduit;
import tango.io.Stdout;
import clazz;


void main()
{
	char[] raw_text;
	
	auto fc = new FileConduit( "out2.xml" );
	raw_text.length = fc.length;
	fc.read( raw_text );
	
	auto doc = new Doc;
	doc.parse( raw_text );
	
	auto cppOut = new FileConduit ( "test.cpp", FileConduit.WriteCreate );
	auto dOut = new FileConduit ( "test.d", FileConduit.WriteCreate );
	
	foreach( node; doc.trunk.query[ "Class" ] )
	{
		Clazz clazz = new Clazz( node );
		cppOut.write( clazz.cClassDfn() );
		dOut.write( clazz.dClassDfn() );
	}
}