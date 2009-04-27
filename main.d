module dcgen.main;

import defines;
import tango.io.FileConduit;
import tango.io.Stdout;
import tango.util.Arguments;
import dcgfile;


int main( char[][] commandLine )
{
	Config config;
    
	auto args = new Arguments();
	args.parse( commandLine[ 1 .. $ ] );
	auto filepath = args[ null ];
	
	if ( filepath.length == 0 ) {
		printHelp();
		return 1;
	}
	
	char[] raw_text;		
	auto fc = new FileConduit( filepath );
	raw_text.length = fc.length;
	fc.read( raw_text );
	
	auto doc = new Doc;
	doc.parse( raw_text );
	
	// auto set = doc.trunk.query[ "Class" ].dup;
	auto set = doc.query.child[ "Class" ].dup;
	foreach( class_node; set )
	{
		auto file = new DCGFile( class_node, config );
		file.createDFile();
		file.createCFile();
	}
	
	return 0;
}

void printHelp()
{
	Stdout( "Usage: dcgen <filepath>" ).newline;
}