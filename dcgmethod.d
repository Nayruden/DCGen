module dcgen.dcgmethod;

import defines;
import dcgvartype;
import tango.io.Stdout;
import tango.text.convert.Format;
import Util = tango.text.Util;
import Integer = tango.text.convert.Integer;

// This has to be global due to a bug in the compiler
private enum MethodType {
	NORMAL,
	CONSTRUCTOR,
	DESTRUCTOR
}

class DCGMethod
{
	private Node class_node, 
	        method_node,
			return_type_node;
	private Config config;
	
	char[] class_name,              // The name of the class this method belongs to
	       method_name,             // The name of this method
	       method_name_mangled;     // The mangled name of this method
	
	bool is_virtual = false;        // Virtual from the C++-side
	
	Access access;
	MethodType arg_type;
	
	this( Node class_node, Node method_node, Config config )
	{
		this.class_node = class_node;
		this.method_node = method_node;
		this.config = config;
		
		class_name = getNodeAttribute( class_node, "name" );
		method_name = getNodeAttribute( method_node, "name" );
		method_name_mangled = getNodeAttribute( method_node, "mangled" );
		method_name_mangled = Util.substitute( method_name_mangled, "*INTERNAL*", cast (char[]) null ); // TODO: Is there really a good reason for this?
		method_name_mangled = Util.trim( method_name_mangled );
		
		if ( method_node.name == "Constructor" )
			arg_type = MethodType.CONSTRUCTOR;
		else if ( method_node.name == "Destructor" ){
			arg_type = MethodType.DESTRUCTOR;
		}
		else {
			arg_type = MethodType.NORMAL;
			return_type_node = getNodeByID( method_node.document, getNodeAttribute( method_node, "returns" ) );
		}
		
		if ( hasAttributeAndEqualTo( method_node, "virtual", "1" ) ) {
			is_virtual = true;
		}
		
		auto access_name = getNodeAttribute( method_node, "access" );
		auto access_pointer = access_name in REVERSE_ACCESS;
		assert( access_pointer !is null, "Unknown access type: " ~ access_name );
		access = *access_pointer; // The value's good, reference it
	}
	
	private char[] prefixComma( char[] str )
	{
		if ( str != null )
			return ", " ~ str;
		
		return null;
	}
	
	private char[][] getArgNames()
	{
		char[][] arg_names;
		int arg_num = 0;
		foreach( child; method_node.children ) {
			if ( child == null || child.name == null )
				continue;
			arg_num++;

			if ( child.hasAttribute( "name" ) )
				arg_names ~= getNodeAttribute( child, "name" );
			else
				arg_names ~= "arg" ~ Integer.toString( arg_num );
		}
		
		return arg_names;
	}
	
	private char[][] getArgTypes( Language language )
	{
		char[][] arg_types;
		
		foreach( child; method_node.children ) {
			if ( child == null || child.name == null )
				continue;
				
			auto type_node = getNodeByID( method_node.document, getNodeAttribute( child, "type" ) ); // TODO: Move this to init
			auto arg_type = new DCGVarType( type_node, config );
			
			if ( language == Language.CPP )
				arg_types ~= arg_type.layoutCPP;
			else if ( language == Language.C )
				arg_types ~= arg_type.layoutC;
			else if ( language == Language.D )
				arg_types ~= arg_type.layoutD;
		}
		
		return arg_types;
	}
	
	private char[][] getArgNamesAndTypes( Language language )
	{
		char[][] arg_types = getArgTypes( language );
		char[][] arg_names = getArgNames();
		char[][] arg_names_and_types;
		
		int count = 0;
		foreach ( arg_type; arg_types ) {
			arg_names_and_types ~= arg_type ~ " " ~ arg_names[ count++ ];
		}
		
		return arg_names_and_types;
	}
	
	private char[] getReturnType( Language language )
	{
		if ( arg_type != MethodType.NORMAL ) // Constructor and destructor have no return
			return "";
		
		char[] return_type_str;
		
		scope return_type = new DCGVarType( return_type_node, config ); // TODO: Move this to init
		if ( language == Language.CPP )
			return_type_str = return_type.layoutCPP;
		else if ( language == Language.C )
			return_type_str = return_type.layoutC;
		else if ( language == Language.D )
			return_type_str = return_type.layoutD;
		
		return return_type_str;
	}
	
//////////////////////////////cppInterfaceDefinition//////////////////

	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Function name mangled
	// 3 = Return type
	// 4 = Arg names and types w/comma
	// 5 = Arg names and types w/o comma
	// 6 = Arg names
	// 7 = Return?
	private const c_interface_definition_layout = 
`extern "C" {3} dcgen_{2}( {0} *cPtr{4} )
{{
	assert( cPtr != NULL );
	{7}cPtr->{1}( {6} );
}`;
	
	private const c_interface_definition_layout_constructor = 
`extern "C" {0} *dcgen_{2}_create( {5} )
{{
	return new {0}( {6} );
}`;
	
	private const c_interface_definition_layout_destructor = 
`extern "C" void dcgen_{2}_destroy( {0} *cPtr )
{{
	assert( cPtr != NULL );
	delete cPtr;
}`;

	
	public char[] cppInterfaceDefinition()
	{
		scope arg_names = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.CPP ), ", " );
		scope return_type = getReturnType( Language.CPP );
		
		scope char[] format = c_interface_definition_layout;
		if ( arg_type == MethodType.CONSTRUCTOR )
			format = c_interface_definition_layout_constructor;
		else if ( arg_type == MethodType.DESTRUCTOR )
			format = c_interface_definition_layout_destructor;

		return Format( format,
			class_name,
			method_name,
			method_name_mangled,
			return_type,
			prefixComma( arg_names_and_types ),
			arg_names_and_types,
			arg_names,
			return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////cExpandedInterfaceDefinition////////////

	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	// 3 = Arg names and types w/o comma
	// 4 = Arg names w/comma
	// 5 = Return?
	private const c_expanded_interface_definition_layout = 
`	D_{1}_functype D_{1};

	virtual {2} {1}( {3} )
	{{
		if ( D_{1} == NULL )
			return;

		assert( implD != NULL );
		{5}(*D_{1})( implD{4} );
	}
	friend {2} {0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr );`;


	public char[] cExpandedInterfaceDefinition()
	{
		scope arg_names = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.CPP ), ", " );
		scope return_type = getReturnType( Language.CPP );

		return Format( c_expanded_interface_definition_layout,
			class_name,
			method_name,
			return_type,
			arg_names_and_types,
			prefixComma( arg_names ),
			return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////cExpandedInterfaceSetterDeclaration/////


	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	// 3 = Arg names w/comma
	private const c_expanded_interface_setter_declaration_layout =
`typedef {2} (*D_{1}_functype)( D_{0} *{3} );
extern "C" {2} {0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr );`;

	public char[] cExpandedInterfaceSetterDeclaration()
	{
		scope arg_names = Util.join( getArgNames(), ", " );
			
		return Format( c_expanded_interface_setter_declaration_layout,
			class_name,
			method_name,
			getReturnType( Language.C ),
			prefixComma( arg_names )
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
			getReturnType( Language.CPP )
		 );
	}

//////////////////////////////cInterfaceDeclaration///////////////////
	
	// 0 = Class name
	// 1 = Function name mangled
	// 2 = Return type
	// 3 = Arg names and types w/comma
	// 4 = Arg names and types w/o comma
	private const c_interface_declaration_layout = 
`	{2} dcgen_{1}( C{0} cPtr{3} );`;
	
	private const c_interface_declaration_layout_constructor =
`	C{0} dcgen_{1}_create( {4} );`;
	
	private const c_interface_declaration_layout_destructor =
`	void dcgen_{1}_destroy( C{0} cPtr );`;
	
	public char[] cInterfaceDeclaration()
	{
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.C ), ", " );
		
		scope char[] format = c_interface_declaration_layout;
		if ( arg_type == MethodType.CONSTRUCTOR )
			format = c_interface_declaration_layout_constructor;
		else if ( arg_type == MethodType.DESTRUCTOR )
			format = c_interface_declaration_layout_destructor;
		
		return Format( format,
			class_name,
			method_name_mangled,
			getReturnType( Language.C ),
			prefixComma( arg_names_and_types ),
			arg_names_and_types
		);
	}
	
//////////////////////////////dClassMethod////////////////////////////

	// 0 = Function name unmangled
	// 1 = Function name mangled
	// 2 = Return type
	// 3 = Arg names and types w/o comma
	// 4 = Arg names w/comma
	// 5 = Arg names w/o comma
	// 6 = Return?	
	private const d_class_method_layout = 
`	{2} {0}( {3} )
	{{
		assert( cPtr != null );
		{6}dcgen_{1}( cPtr{4} );
	}`;
	
	private const d_class_method_layout_constructor =
`	this( {3} )
	{{
		cPtr = dcgen_{1}_create( {5} );
	}`;
	
	private const d_class_method_layout_destructor =
`	~this()
	{{
		dcgen_{1}_destroy( cPtr );
		cPtr = null;
	}`;
	
	public char[] dClassMethod()
	{
		scope arg_names = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.D ), ", " ); // TODO: Change to D
		scope return_type = getReturnType( Language.D );
		
		scope char[] format = d_class_method_layout;
		if ( arg_type == MethodType.CONSTRUCTOR )
			format = d_class_method_layout_constructor;
		else if ( arg_type == MethodType.DESTRUCTOR )
			format = d_class_method_layout_destructor;
			
		return Format( format,
			method_name,
			method_name_mangled,
			return_type,
			arg_names_and_types,
			prefixComma( arg_names ),
			arg_names,
			return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////dVirtualFunctionWrapper/////////////////

		// 0 = Class name
		// 1 = Arg names and types w/comma
		// 2 = Arg names w/o comma
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
		scope arg_names = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.CPP ), ", " );
		scope return_type = getReturnType( Language.CPP );

		return Format( d_virtual_wrapper_layout,
			class_name,
			prefixComma( arg_names_and_types ),
			arg_names,
			method_name,
			return_type,
			return_type == "void" ? "" : "return "
		 );
	}
}
