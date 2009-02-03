module dcgen.clazz;

import defines;
import method;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.convert.Format;

// const r_classMethodsDfnC = 
// `typedef void* D{0};
// extern "C" {0}_R *{0}_create_r( D{0} dPtr )
// {{
// 	assert( dPtr != NULL );
// 	return new {0}_R( dPtr );
// }
// `;
// 
// const r_classMethodsDeclD =
// `typedef void* C{0}_R;
// private extern ( C ) 
// {{
// 	C{0}_R {0}_create_r();
// `;
// 
// const r_classDfnDStart =
// `class {0}_R : {0}
// {{
// 	this()
// 	{{
// 		cPtr = {0}_create_r( &this );
// 		Stdout( "Created dPtr\n" )();
// 	}
// }
// `;
// 
// const r_classDfnDEnd =
// `}
// `;

class Clazz
{
	Node class_node;
	Method[] methods;
	bool needs_inheritance = false; // Do we need to allow inheritance of this class on the D side?
	
	// Information gleaned from the xml
	char[] class_name; // The name of the C++ class
	char[] class_name_mangled; // The mangled C++ class name
	
	this( Node class_node )
	{
		this.class_node = class_node;
		class_name = getNodeAttribute( class_node, "name" );
		class_name_mangled = getNodeAttribute( class_node, "mangled" );
		
		auto doc = class_node.document;		
		
		auto member_ids = getNodeAttribute( class_node, "members" );
		foreach( member; split( member_ids, " " ) ) {
			if ( trim( member ) == "" )
				continue;
		
			auto set = doc.query.child.child.filter( filterByID( member ) );
			
			auto node = set.nodes[ 0 ];
			if ( hasAttributeAndEqualTo( node, "artificial", "1" ) ) // Not interested in compiler generated functions (yet, TODO)
				continue;

			// Now let's figure out what type of member this is
			switch ( node.name ) {
			case "Field":
				// TODO
				break;
				
			case "Method":
				if ( hasAttributeAndEqualTo( node, "access", "private" ) ) // Can't do any wrapping here
					break;
					
				auto method = new Method( class_node, node );
				if ( method.needs_inheritance == true )
					needs_inheritance = true;
				methods ~= method;
				break;
				
			default:
				assert( false, "I don't know what this is!" );
				break;
			}
		}		
	}
	

//////////////////////////////cClassDfn///////////////////////////////
	
	// 0 = Unmangled class name
	// 1 = Generated list of C interface definitions
	private const classLayoutC = 
`extern "C" {0} *{0}_create()
{{
	return new {0}();
}

extern "C" void {0}_destroy( {0} *cPtr )
{{
	assert( cPtr != NULL );
	delete cPtr;
}

{1}`;
	
	public char[] cClassDfn()
	{
		char[] c_interface_definitions;
		foreach( method; methods ) {
			c_interface_definitions ~= method.cInterfaceDefinition ~ "\n\n";
		}
		c_interface_definitions = c_interface_definitions[ 0 .. $-2 ]; // Take off the last two newlines
		
		return Format( classLayoutC,
			class_name,
			c_interface_definitions
		 );
	}


//////////////////////////////dClassDfn///////////////////////////////
	
	// 0 = Unmangled class name
	// 1 = Generated list of C interface declarations
	// 2 = Generated list of D class functions
	private const classLayoutD =
`typedef void* C{0};
private extern ( C ) 
{{
	C{0} {0}_create();
	void {0}_destroy( C{0} cPtr );
{1}
}

class {0}
{{
	package C{0} cPtr;

	this()
	{{
		cPtr = {0}_create();
		Stdout( "Created cPtr\n" )();
	}

	~this()
	{{
		{0}_destroy( cPtr );
		cPtr = null;
	}

{2}
}`;
	
	public char[] dClassDfn()
	{
		char[] c_interface_declarations;
		char[] d_class_methods;
		foreach( method; methods ) {
			c_interface_declarations ~= method.cInterfaceDeclaration ~ "\n";
			d_class_methods ~= method.dClassMethod ~ "\n\n";
		}
		c_interface_declarations = c_interface_declarations[ 0 .. $-1 ]; // Take off the last newline
		d_class_methods = d_class_methods[ 0 .. $-2 ]; // Take off the last two newlines
		
		return Format( classLayoutD,
			class_name,                 // 0 = Unmangled class name
			c_interface_declarations,   // 1 = Generated list of C interface declarations
			d_class_methods             // 2 = Generated list of D class functions
		);
	}
}
