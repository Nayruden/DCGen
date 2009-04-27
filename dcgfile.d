module dcgen.dcgfile;

import defines;
import dcgclass;
import tango.io.FileConduit;
import tango.text.Ascii;
import tango.io.Stdout;

class DCGFile
{
	protected Node class_node;
	protected DCGClass clazz;
	
	this( Node class_node, Config config )
	{
		this.class_node = class_node;
		clazz = new DCGClass( class_node, config );
	}
	
	void createDFile()
	{
		auto dOut = new FileConduit ( toLower( clazz.class_name.dup ) ~ ".d", FileConduit.WriteCreate );
		dOut.write( clazz.dClassDfn() );
		dOut.close();
	}
	
	void createCFile()
	{
		auto cppOut = new FileConduit ( toLower( clazz.class_name.dup ) ~ ".cpp", FileConduit.WriteCreate );
		if ( true ) { // TODO: read config
			cppOut.write( clazz.cExpandedClassDfn() ~ "\n\n\n" ); // Do this separation properly?
		}
		cppOut.write( clazz.cClassDfn() );
		cppOut.close();
	}
}
