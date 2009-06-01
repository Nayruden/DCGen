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

module dcgen.{0}; // TODO: make prefix a config

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
		// 2 = Header file for this class
	
	private const c_file_layout =
`// This file was generated by DCGen, do not edit by hand!

#include <assert.h>
#include "{2}"

{0}{1}
`;
	void createCFile()
	{
		char[] expanded_output;
		if ( config.generate_wrappers && clazz.is_abstract ) { // If they want wrappers and there's something to wrap...
			expanded_output = clazz.cExpandedClassDfn() ~ "\n\n\n";
		}
		
		char[] class_header_file_id = getNodeAttribute( class_node, "file" );
		auto class_header_file_node = class_node.document.query.child.child.filter( filterByID( class_header_file_id ) ).nodes[ 0 ];
		char[] class_header_file = getNodeAttribute( class_header_file_node, "name" );
		
		auto buffer = Format( c_file_layout,
		                      expanded_output,
		                      clazz.cClassDfn,
		                      class_header_file );
		
		auto cppOut = new FileConduit ( config.output_directory ~ "/" ~ toLower( clazz.class_name.dup ) ~ ".cpp", FileConduit.WriteCreate );
		cppOut.write( buffer );
		cppOut.close();
	}
}
