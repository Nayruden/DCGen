module dcgen.dcgfile;

import defines;
import dcgclass;
import tango.io.FileConduit;
import tango.text.Ascii;
import tango.io.Stdout;
import tango.text.convert.Format;

class DCGFile
{
	protected Node class_node;
	protected DCGClass clazz;
	protected Config config;
	
	this( Node class_node, Config config )
	{
		this.class_node = class_node;
		this.config = config;
		clazz = new DCGClass( class_node, config );
	}
	
//////////////////////////////createDFile/////////////////////////////

	// 0 = Class name
	// 1 = D class def

	private const d_file_layout =
`// This file was generated by DCGen, do not edit by hand!

module dcgen.{0};

import tango.io.Stdout; // TODO: Remove this later

{1}
`;
	
	void createDFile()
	{
		auto buffer = Format( d_file_layout,
		                      clazz.class_name,
		                      clazz.dClassDfn );
		
		auto dOut = new FileConduit ( config.output_directory ~ "/" ~ toLower( clazz.class_name.dup ) ~ ".d", FileConduit.WriteCreate );
		dOut.write( buffer );
		dOut.close();
	}

//////////////////////////////createCFile/////////////////////////////

		// 0 = Expanded class wrapper output
		// 1 = Simple class wrapper output
	
	private const c_file_layout =
`// This file was generated by DCGen, do not edit by hand!

#include <assert.h>
// TODO: Add includes

{0}{1}
`;
	void createCFile()
	{
		char[] expanded_output;
		if ( true ) { // TODO: read config
			expanded_output = clazz.cExpandedClassDfn() ~ "\n\n\n";
		}
		
		auto buffer = Format( c_file_layout,
		                      expanded_output,
		                      clazz.cClassDfn );
		
		auto cppOut = new FileConduit ( config.output_directory ~ "/" ~ toLower( clazz.class_name.dup ) ~ ".cpp", FileConduit.WriteCreate );
		cppOut.write( buffer );
		cppOut.close();
	}
}
