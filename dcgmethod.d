module dcgen.dcgmethod;

import defines;
import tango.io.Stdout;
import tango.text.convert.Format;
import tango.text.Util;

class DCGMethod
{
	Node class_node, 
	     method_node;
	
	char[] return_type,             // The return type of the method, IE "void"
	       func_args_and_types,     // The arguments, IE "int i, char c, Foo bar"
	       func_args,               // The pass string, IE "i, c, bar"
	       class_name,              // The name of the class this method belongs to
	       method_name,             // The name of this method
	       method_name_mangled;     // The mangled name of this method
	
	bool is_virtual = false,        // Virtual from the C++-side
	     is_constructor = false;    // Is this method a constructor?
	
	Access access;
	
	this( Node class_node, Node method_node, Config config )
	{
		this.class_node = class_node;
		this.method_node = method_node;
		this.is_constructor = is_constructor;
		
		if ( method_node.name == "Constructor" )
			is_constructor = true;
		else {
			scope return_type_node = getNodeByID( method_node.document, getNodeAttribute( method_node, "returns" ) );
			return_type = typeNodeToString( return_type_node );
		}
		
		generateArgsAndTypes(); // Creates our func_args* strings
		
		class_name = getNodeAttribute( class_node, "name" );
		method_name = getNodeAttribute( method_node, "name" );
		method_name_mangled = getNodeAttribute( method_node, "mangled" );
		
		if ( hasAttributeAndEqualTo( method_node, "virtual", "1" ) ) {
			is_virtual = true;
		}
		
		auto access_name = getNodeAttribute( method_node, "access" );
		auto access_pointer = access_name in REVERSE_ACCESS;
		assert( access_pointer !is null, "Unknown access type: " ~ access_name );
		access = *access_pointer; // The value's good, reference it
	}
	
//////////////////////////////generateArgsAndTypes////////////////////
	
	private void generateArgsAndTypes()
	{
		if ( !method_node.hasChildren )
			return;
			
		func_args_and_types = "";
		func_args = "";
			
		foreach( child; method_node.children ) {
			if ( child.name == null )
				continue;
				
			auto type_node = getNodeByID( method_node.document, getNodeAttribute( child, "type" ) );
			auto type = typeNodeToString( type_node );
			auto name = getNodeAttribute( child, "name" );
			
			func_args_and_types ~= type ~ " " ~ name ~ ", ";
			func_args ~= name ~ ", ";
		}
		
		// Cut off the ", " at the end of both
		func_args_and_types = func_args_and_types[ 0 .. $-2 ]; 
		func_args = func_args[ 0 .. $-2 ];
	}
	
//////////////////////////////cInterfaceDefinition////////////////////

	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Function name mangled
	// 3 = Return type
	// 4 = Args w/comma
	// 5 = Pass to func
	// 6 = Return?
	private const c_interface_defintion_layout = 
`extern "C" {3} dcgen_{2}( {0} *cPtr{4} )
{{
	assert( cPtr != NULL );
	{6}cPtr->{1}( {5} );
}`;

	
	public char[] cInterfaceDefinition()
	{
		auto args = func_args_and_types;
		if ( args != null )
			args = ", " ~ func_args_and_types.dup;

		return Format( c_interface_defintion_layout,
			class_name,
			method_name,
			method_name_mangled,
			return_type,
			args,
			func_args,
			return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////cExpandedInterfaceDefinition////////////

	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	// 3 = Args w/comma
	// 4 = Args w/o comma
	// 5 = Pass to func w/comma
	// 6 = Return?
	private const c_expanded_interface_definition_layout = 
`	D_{1}_functype D_{1};

	virtual {2} {1}( {4} )
	{{
		if ( D_{1} == NULL )
			return;

		assert( implD != NULL );
		{6}(*D_{1})( implD{5} );
	}
	friend {2} {0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr );`;


	public char[] cExpandedInterfaceDefinition()
	{
		auto args = func_args_and_types;
		if ( args != null )
			args = ", " ~ func_args_and_types.dup;

		return Format( c_expanded_interface_definition_layout,
			class_name,
			method_name,
			return_type,
			args,
			func_args_and_types,
			func_args,
			return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////cExpandedInterfaceSetterDeclaration/////


	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	// 3 = Args w/comma
	private const c_expanded_interface_setter_declaration_layout =
`typedef {2} (*D_{1}_functype)( D_{0} *{3} );
extern "C" {2} {0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr );`;

	public char[] cExpandedInterfaceSetterDeclaration()
	{
		auto args = func_args_and_types;
		if ( args != null )
			args = ", " ~ func_args_and_types.dup;
			
		return Format( c_expanded_interface_setter_declaration_layout,
			class_name,
			method_name,
			return_type,
			args
		 );
	}
	
//////////////////////////////cExpandedInterfaceSetter////////////////
	
	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	private const c_expanded_interface_setter_layout =
`extern "C" {2} {0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr )
{{
	assert( wrapperPtr != NULL );
	assert( funcPtr != NULL );
	wrapperPtr->D_{1} = funcPtr;
}`;

	public char[] cExpandedInterfaceSetter()
	{
		return Format( c_expanded_interface_setter_layout,
			class_name,
			method_name,
			return_type
		 );
	}

//////////////////////////////cInterfaceDeclaration///////////////////
	
	// 0 = Class name
	// 1 = Function name mangled
	// 2 = Return type
	// 3 = Args
	private const c_interface_declaration_layout = `	{2} dcgen_{1}( C{0} cPtr{3} );`;
	
	public char[] cInterfaceDeclaration()
	{
		auto args = func_args_and_types;
		if ( args != null )
			args = ", " ~ func_args_and_types.dup;
		
		return Format( c_interface_declaration_layout,
			class_name,
			method_name_mangled,
			return_type,
			args
		);
	}
	
//////////////////////////////dClassMethod////////////////////////////

	// 0 = Function name unmangled
	// 1 = Function name mangled
	// 2 = Return type
	// 3 = Args
	// 4 = Pass to func
	// 5 = Return?	
	private const d_class_method_layout = 
`	{2} {0}( {3} )
	{{
		assert( cPtr != null );
		{5}dcgen_{1}( cPtr{4} );
	}`;
	
	public char[] dClassMethod()
	{
		auto pass = func_args;
		if ( pass != null )
			pass = ", " ~ func_args.dup;
			
		return Format( d_class_method_layout,
			method_name,
			method_name_mangled,
			return_type,
			func_args_and_types,
			pass,
			return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////dVirtualFunctionWrapper/////////////////

		// 0 = Class name
		// 1 = Args w/comma and w/types
		// 2 = Args w/o comma
		// 3 = Function name unmangled
		// 4 = Return type
		// 5 = Return?	
		private const d_virtual_wrapper_layout = 
`	// Virtual function wrapper stuff for method {3}
	alias void function( {0}*{1} ) D_{3}_functype;
	{4} {0}_set_{3}( {0}_wrapper *wrapperPtr, D_{3}_functype funcPtr );
	{4} {0}_{3}Wrapper( {0} *dPtr{1} )
	{{
		{5}dPtr.{3}( {2} );
	}`;

		public char[] dVirtualFunctionWrapper()
		{
			auto args = func_args_and_types;
			if ( args != null )
				args = ", " ~ func_args_and_types.dup;

			return Format( d_virtual_wrapper_layout,
				class_name,
				args,
				func_args,
				method_name,
				return_type,
				return_type == "void" ? "" : "return "
			 );
		}
}
