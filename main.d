module dcgen.main;

import defines;
import io.device.File;
import Path = tango.io.Path;
import Array = tango.core.Array;
import Util = tango.text.Util;
import Ascii = tango.text.Ascii;
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
	auto fc = new File( config.input_filepath );
	raw_text.length = fc.length;
	fc.read( raw_text );
	
	auto doc = new Doc;
	doc.parse( raw_text );
	
	// auto set = doc.trunk.query[ "Class" ].dup;
	auto set = doc.query.child[ "Class" ].dup;
	foreach( class_node; set )
	{
		scope class_name = getNodeAttribute( class_node, "name" );
		if ( config.include_classes.length > 0 && !Array.contains( config.include_classes, class_name ) )
			continue;
		
		class_name = Ascii.toLower( class_name.dup );
		scope fileLayout = new DCGFile( class_node, class_name, config );
		
		scope dOut = new File( config.output_directory ~ "/" ~ class_name ~ ".d", File.WriteCreate );
		dOut.write( fileLayout.layout( Language.D ) );
		dOut.close();
		
		scope cppOut = new File( config.output_directory ~ "/" ~ class_name ~ ".cpp", File.WriteCreate );
		cppOut.write( fileLayout.layout( Language.CPP ) );
		cppOut.close();
	}
	
	// Time to get globals!
	if ( config.include_globals ) {
		Node[] function_nodes;
		set = doc.query.child[ "Function" ].dup;
		foreach( function_node; set )
		{
			scope function_name = getNodeAttribute( function_node, "name" );
			const prefix_filter = "__builtin";
			if ( function_name.length >= prefix_filter.length && function_name[ 0 .. prefix_filter.length ] == prefix_filter )
				continue;
			// TODO: A config for further filtering
			
			function_nodes ~= function_node;
		}
		
		scope fileLayout = new DCGFile( function_nodes, "globals", config );
		scope dOut = new File( config.output_directory ~ "/" ~ "globals" ~ ".d", File.WriteCreate );
		dOut.write( fileLayout.layout( Language.D ) );
		dOut.close();
	}
	
	return 0;
}

void printHelp()
{
	Stderr( "Usage: dcgen [options] <input-file>\n\n"
	        "The following options are available:\n"
			"  -m (--mode)=<mode>                  Valid modes are C or CPP, defaults to CPP (CPP generates C code 'glue', C implies --globals)"
			"  -w (--wrappers)                     Create wrappers for extending virtual functions\n"
	        "  -o (--outdir)=<output-directory>    Set the output directory\n"
			"  --classes=<comma-separated-list>    List of classes to include in output, defaults to include all\n"
			"  -g (--globals)                      Include global functions in output, default behavior is to NOT include globals" ).newline;
}

bool parseAndValidateParams( ref Config config, in char[][] params )
{	
	auto args = new Arguments();
	args.define( "mode" ).aliases( [ "m" ] ).parameters( 1 ).defaults( [ "CPP" ] );
	args.define( "outdir" ).aliases( [ "o" ] ).parameters( 1 ).defaults( ["."] );
	args.define( "classes" ).parameters( 1 );
	args.define( "wrappers" ).aliases( ["w"] );
	args.define( "globals" ).aliases( ["g"] );
	args.parse( params );
	
	config.input_filepath = args[ null ]; // Null returns any args that don't belong to anything else
	if ( config.input_filepath.length == 0 ) {
		printHelp();
		return false;
	}
	
	switch (Ascii.toUpper( args[ "mode" ] )) {
		case "CPP":
			config.mode = Language.CPP;
		break;
			
		case "C":
			config.mode = Language.C;
		break;
		
		default:
			Stderr( "Unknown parameter passed to mode switch" ).newline;
			return false;
		break;
	}
	
	config.output_directory = args[ "outdir" ];
	if ( !Path.exists( config.output_directory ) ) {
		Stderr( "Specified output directory does not exist" ).newline;
		return false;
	}
	
	if ( args[ "classes" ] !is null )
		config.include_classes = Util.delimit( args[ "classes" ], "," );
	
	if ( args.contains( "wrappers" ) )
		config.generate_wrappers = true;
	else
		config.generate_wrappers = false;
	
	if ( args.contains( "globals" ) || config.mode == Language.C )
		config.include_globals = true;
	else
		config.include_globals = false;
	
	return true;
}