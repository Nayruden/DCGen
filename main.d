module dcgen.main;

import defines;
import tango.io.FileConduit;
import Path = tango.io.Path;
import tango.io.Stdout;
import tango.util.Arguments;
import dcgfile;


int main( char[][] commandLine )
{
	Config config;
	auto success = parseAndValidateParams( config, commandLine[ 1 .. $ ] );
	if ( !success )
		return 1;
	
	char[] raw_text;		
	auto fc = new FileConduit( config.input_filepath );
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
	Stderr( "Usage: dcgen [options] <input-file>\n\n"
	        "The following options are available:\n"
	        "  --outdir=<output-directory>         Set the output directory" ).newline;
}

bool parseAndValidateParams( ref Config config, in char[][] params )
{	
	auto args = new Arguments();
	args.define( "outdir" ).parameters( 1 ).defaults( ["."] );
	args.parse( params );
	
	config.input_filepath = args[ null ];
	if ( config.input_filepath.length == 0 ) {
		printHelp();
		return false;
	}
	
	config.output_directory = args[ "outdir" ];
	if ( !Path.exists( config.output_directory ) ) {
		Stderr( "Specified output directory does not exist" ).newline;
		return false;
	}
	
	return true;
}