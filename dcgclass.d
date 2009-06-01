module dcgen.dcgclass;

import defines;
import dcgmethod;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.convert.Format;

class DCGClass
{
	Node class_node;
	DCGMethod[] methods;
	
	// Information gleaned from the xml
	char[] class_name; // The name of the C++ class
	char[] class_name_mangled; // The mangled C++ class name
	bool is_abstract; // This class contains virtual functions
	
	this( Node class_node, Config config )
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
				
			case "Constructor":
			case "Method":
				auto method = new DCGMethod( class_node, node, config );
				if ( method.access == Access.PRIVATE ) // Nothing we can do in regards to private
					break;
				// TODO: Remember only to output protected stuff to wrappers (and only if it's virtual)					
				
				methods ~= method;
				if ( method.is_virtual )
					is_abstract = true;
				break;
				
			default:
				assert( false, "I don't know what a '" ~ node.name ~ "' is! Id is " ~ 
						getNodeAttribute( node, "id" ) );
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
		
		if ( c_interface_definitions.length > 0 )
			c_interface_definitions = c_interface_definitions[ 0 .. $-2 ]; // Take off the last two newlines
		
		return Format( classLayoutC,
			class_name,
			c_interface_definitions
		 );
	}
	
	
//////////////////////////////cExpandedClassDfn///////////////////////

	// 0 = Unmangled class name
	// 1 = Generated list of expanded C interface definitions
	// 2 = Generated list of C function pointer setters
	// 3 = Generated list of C function pointer setter declarations
	private const expandedClassLayoutC =
`typedef void D_{0};
class {0}_wrapper;

{3}

class {0}_wrapper : public {0}
{{
private:
	D_{0} *implD;

public:
	{0}_wrapper( D_{0} *implD )
	{{
		this->implD = implD;
	}

protected:
{1}
};

{2}`;

	public char[] cExpandedClassDfn()
	{
		char[] c_expanded_interface_definitions;
		char[] c_expanded_interface_setters;
		char[] c_expanded_interface_setter_declarations;
		
		foreach( method; methods ) {
			if ( method.is_virtual ) {
				c_expanded_interface_definitions ~= method.cExpandedInterfaceDefinition ~ "\n\n";
				c_expanded_interface_setters ~= method.cExpandedInterfaceSetter ~ "\n\n";
				c_expanded_interface_setter_declarations ~= method.cExpandedInterfaceSetterDeclaration ~ "\n\n";
			}
		}
		
		if ( c_expanded_interface_definitions.length > 0 )
			c_expanded_interface_definitions = c_expanded_interface_definitions[ 0 .. $-2 ]; // Take off the last two newlines
			
		if ( c_expanded_interface_setters.length > 0 ) {
			c_expanded_interface_setters = c_expanded_interface_setters[ 0 .. $-2 ]; // Take off the last two newlines
			c_expanded_interface_setter_declarations = c_expanded_interface_setter_declarations[ 0 .. $-2 ]; // Take off the last two newlines
		}
		
		return Format( expandedClassLayoutC,
			class_name,
			c_expanded_interface_definitions,
			c_expanded_interface_setters,
			c_expanded_interface_setter_declarations
		 );
	}


//////////////////////////////dClassDfn///////////////////////////////
	
	// 0 = Unmangled class name
	// 1 = Generated list of C interface declarations
	// 2 = Generated list of D class functions
	// 3 = Generated list of C virtual function setters
	private const classLayoutD =
`typedef void* C{0};
private extern (C) 
{{
	C{0} {0}_create();
	void {0}_destroy( C{0} cPtr );
{1}

{3}
}

class {0}
{{
	package C{0} cPtr;

	this()
	{{
		cPtr = {0}_create();
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
		char[] d_virtual_wrappers;
		foreach( method; methods ) {
			c_interface_declarations ~= method.cInterfaceDeclaration ~ "\n";
			d_class_methods ~= method.dClassMethod ~ "\n\n";
			if ( method.is_virtual )
				d_virtual_wrappers ~= method.dVirtualFunctionWrapper ~ "\n\n";
		}
		
		if ( c_interface_declarations.length > 0 )
			c_interface_declarations = c_interface_declarations[ 0 .. $-1 ]; // Take off the last newline
		
		if ( d_class_methods.length > 0 )
			d_class_methods = d_class_methods[ 0 .. $-2 ]; // Take off the last two newlines
			
		if ( d_virtual_wrappers.length > 0 )
			d_virtual_wrappers = d_virtual_wrappers[ 0 .. $-2 ]; // Take off the last two newlines
		
		return Format( classLayoutD,
			class_name,                 // 0 = Unmangled class name
			c_interface_declarations,   // 1 = Generated list of C interface declarations
			d_class_methods,            // 2 = Generated list of D class functions
			d_virtual_wrappers          // 3 = Generated list of C virtual function setters
		);
	}
}
