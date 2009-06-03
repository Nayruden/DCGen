module dcgen.dcgmethod;

import defines;
import dcgvartype;
import tango.io.Stdout;
import tango.text.convert.Format;
import Util = tango.text.Util;
import Integer = tango.text.convert.Integer;
import dcgpreprocess;

// This has to be global due to a bug in the compiler
private enum MethodType {
	NORMAL,
	CONSTRUCTOR,
	DESTRUCTOR
}

class DCGMethod
{
	private Node class_node, 
	        method_node;
	
	private DCGVarType return_type;
	private DCGVarType[] arg_types;
	
	private Config config;
	
	char[] class_name,              // The name of the class this method belongs to
	       method_name,             // The name of this method
	       method_name_mangled;     // The mangled name of this method
	
	bool is_virtual = false;        // Virtual from the C++-side
	
	Access access;
	MethodType method_type;
	
	this( Node class_node, Node method_node, Config config )
	{
		this.class_node = class_node;
		this.method_node = method_node;
		this.config = config;
		
		class_name = getNodeAttribute( class_node, "name" );
		method_name = getNodeAttribute( method_node, "name" );
		method_name_mangled = getNodeAttribute( method_node, "mangled" );
		// TODO: Is there really a good reason for this being marked INTERNAL?
		method_name_mangled = Util.substitute( method_name_mangled, "*INTERNAL*", cast (char[]) null );
		method_name_mangled = Util.trim( method_name_mangled );
		
		if ( method_node.name == "Constructor" )
			method_type = MethodType.CONSTRUCTOR;
		else if ( method_node.name == "Destructor" ){
			method_type = MethodType.DESTRUCTOR;
		}
		else {
			method_type = MethodType.NORMAL;
			scope return_type_node = getNodeByID( method_node.document, getNodeAttribute( method_node, "returns" ) );
			return_type = new DCGVarType( return_type_node, config );
		}
		
		foreach ( child; method_node.children ) {
			if ( child == null || child.name == null )
				continue;
				
			scope type_node = getNodeByID( method_node.document, getNodeAttribute( child, "type" ) );
			auto method_type = new DCGVarType( type_node, config );
			
			arg_types ~= method_type;
		}
		
		
		
		if ( hasAttributeAndEqualTo( method_node, "virtual", "1" ) ) {
			is_virtual = true;
		}
		
		// What type of access are we? Private, Public, or Protected?
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
	
	private char[] prefixNewlineAndTab( char[] str, int num_tabs )
	{
		if ( str != null ) {
			char[][] newlines;
			foreach ( line; Util.lines( str ) ) {
				newlines ~= Util.repeat( "\t", num_tabs ) ~ line;
			}
			return "\n" ~ Util.join( newlines, "\n" );
		}
		
		return null;
	}
	
	private char[][] getArgNames()
	{
		char[][] processed_arg_names_arr;
		int arg_num = 0;
		foreach( child; method_node.children ) {
			if ( child == null || child.name == null )
				continue;
			arg_num++;

			if ( child.hasAttribute( "name" ) )
				processed_arg_names_arr ~= getNodeAttribute( child, "name" );
			else
				processed_arg_names_arr ~= "arg" ~ Integer.toString( arg_num );
		}
		
		return processed_arg_names_arr;
	}
	
	private char[][] getArgTypes( Language language, DCGVarType[] arg_types=null )
	{
		if ( arg_types == null )
			arg_types = this.arg_types; // TODO: Better naming
		
		char[][] arg_types_str;
		
		foreach( method_type; arg_types ) {			
			arg_types_str ~= method_type.layout( language );
		}
		
		return arg_types_str;
	}
	
	private char[][] getArgNamesAndTypes( Language language, DCGVarType[] types=null )
	{
		if ( types == null )
			types = this.arg_types; // TODO: Better naming
		
		char[][] arg_types = getArgTypes( language, types );
		char[][] arg_names = getArgNames();

		return combineArgNamesAndTypes( arg_types, arg_names );
	}
	
	private char[][] combineArgNamesAndTypes( char[][] arg_types, char[][] arg_names )
	{
		char[][] arg_names_and_types;

		for ( int i = 0; i < arg_types.length; i++ ) {
			arg_names_and_types ~= arg_types[ i ] ~ arg_names[ i ];
		}
		
		return arg_names_and_types;
	}
	
	private char[] getReturnType( Language language )
	{
		if ( method_type != MethodType.NORMAL ) // Constructor and destructor have no return
			return "";
		
		return return_type.layout( language );
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
	private const cpp_interface_definition = 
`extern "C" {3}dcgen_{2}( {0} *cPtr{4} )
{{
	assert( cPtr != NULL );
	{7}cPtr->{1}( {6} );
}`;
	
	private const cpp_interface_definition_constructor = 
`extern "C" {0} *dcgen_{2}_create( {5} )
{{
	return new {0}( {6} );
}`;
	
	private const cpp_interface_definition_destructor = 
`extern "C" void dcgen_{2}_destroy( {0} *cPtr )
{{
	assert( cPtr != NULL );
	delete cPtr;
}`;

	
	public char[] interfaceDefinition( Language language = Language.CPP )
	{
		assert( language == Language.CPP, "I don't know how to create interface definitions for anything but CPP" );
		
		scope processed_arg_names_arr = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( language ), ", " );
		scope unprocessed_return_type = getReturnType( language );
		
		scope char[] format = cpp_interface_definition;
		if ( method_type == MethodType.CONSTRUCTOR )
			format = cpp_interface_definition_constructor;
		else if ( method_type == MethodType.DESTRUCTOR )
			format = cpp_interface_definition_destructor;

		return Format( format,
			class_name,
			method_name,
			method_name_mangled,
			unprocessed_return_type,
			prefixComma( arg_names_and_types ),
			arg_names_and_types,
			processed_arg_names_arr,
			unprocessed_return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////interfaceDeclaration///////////////////
	
	// 0 = Class name
	// 1 = Function name mangled
	// 2 = Return type
	// 3 = Arg names and types w/comma
	// 4 = Arg names and types w/o comma
	private const c_interface_declaration = 
`	{2}dcgen_{1}( C{0} cPtr{3} );`;
	
	private const c_interface_declaration_constructor =
`	C{0} dcgen_{1}_create( {4} );`;
	
	private const c_interface_declaration_destructor =
`	void dcgen_{1}_destroy( C{0} cPtr );`;
	
	char[] interfaceDeclaration( Language language = Language.C )
	{
		assert( language == Language.C, "I don't know how to create interface declarations for anything but C" );
		
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( language ), ", " );
		
		scope char[] format = c_interface_declaration;
		if ( method_type == MethodType.CONSTRUCTOR )
			format = c_interface_declaration_constructor;
		else if ( method_type == MethodType.DESTRUCTOR )
			format = c_interface_declaration_destructor;
		
		return Format( format,
			class_name,
			method_name_mangled,
			getReturnType( language ),
			prefixComma( arg_names_and_types ),
			arg_names_and_types
		);
	}
	
//////////////////////////////dClassMethod////////////////////////////

	// 0 = Function name unmangled
	// 1 = Function name mangled
	// 2 = Return type
	// 3 = Unprocessed arg names and processed types w/o comma
	// 4 = Processed arg names w/comma
	// 5 = Processed arg names w/o comma
	// 6 = Return?
	// 7 = Preconditions
	// 8 = Preprocessing
	private const d_class_method = 
`	{2}{0}( {3} )
    in {{
		assert( cPtr != null );{7}
	}
	body {{{8}
		{6}dcgen_{1}( cPtr{4} );
	}`;
	
	private const d_class_method_constructor =
`	this( {3} )
	out {{
		assert( cPtr != null );
	}
	body {{{8}
		cPtr = dcgen_{1}_create( {5} );
	}`;
	
	private const d_class_method_destructor =
`	~this()
	in {{
		assert( cPtr != null );
	}
	body {{{8}
		dcgen_{1}_destroy( cPtr );
		cPtr = null;
	}`;
	
	char[] classMethod( Language language = Language.D )
	{
		assert( language == Language.D, "I don't know how to create class methods for anything but D" );
		
		// Setup vars for processing
		scope processed_arg_names_arr = getArgNames();
		scope processed_arg_types_arr = arg_types.dup;
		scope char[] preconditions, preprocessing;
		
		// Do proccessing
		for ( int i=0; i < processed_arg_types_arr.length; i++ )
			preprocessing ~= DCGPreprocess.convert( language, Language.C, processed_arg_types_arr[ i ], processed_arg_names_arr[ i ] );
		
		// Determine format
		scope char[] format = d_class_method;
		if ( method_type == MethodType.CONSTRUCTOR )
			format = d_class_method_constructor;
		else if ( method_type == MethodType.DESTRUCTOR )
			format = d_class_method_destructor;
		
		// Setup final processed vars
		scope processed_arg_types = getArgTypes( language, processed_arg_types_arr );
		scope args_for_header = Util.join( combineArgNamesAndTypes( processed_arg_types, getArgNames() ), ", " );
		scope processed_arg_names_str = Util.join( processed_arg_names_arr, ", " );
		scope unprocessed_return_type = getReturnType( language ); // TODO: Return processing
		
		return Format( format,
			method_name,
			method_name_mangled,
			unprocessed_return_type,
			args_for_header,
			prefixComma( processed_arg_names_str ),
			processed_arg_names_str,
			unprocessed_return_type == "void" ? "" : "return ",
			prefixNewlineAndTab( preconditions, 2 ),
			prefixNewlineAndTab( preprocessing, 2 )
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


	char[] cExpandedInterfaceDefinition()
	{
		scope processed_arg_names_arr = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.CPP ), ", " );
		scope unprocessed_return_type = getReturnType( Language.CPP );

		return Format( c_expanded_interface_definition_layout,
			class_name,
			method_name,
			unprocessed_return_type,
			arg_names_and_types,
			prefixComma( processed_arg_names_arr ),
			unprocessed_return_type == "void" ? "" : "return "
		 );
	}
	
//////////////////////////////cExpandedInterfaceSetterDeclaration/////


	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	// 3 = Arg names w/comma
	private const c_expanded_interface_setter_declaration_layout =
`typedef {2}(*D_{1}_functype)( D_{0} *{3} );
extern "C" {2}{0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr );`;

	public char[] cExpandedInterfaceSetterDeclaration()
	{
		scope processed_arg_names_arr = Util.join( getArgNames(), ", " );
			
		return Format( c_expanded_interface_setter_declaration_layout,
			class_name,
			method_name,
			getReturnType( Language.C ),
			prefixComma( processed_arg_names_arr )
		 );
	}
	
//////////////////////////////cExpandedInterfaceSetter////////////////
	
	// 0 = Class name
	// 1 = Function name unmangled
	// 2 = Return type
	private const c_expanded_interface_setter_layout =
`extern "C" {2}{0}_set_{1}( {0}_wrapper *wrapperPtr, D_{1}_functype funcPtr )
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
		scope processed_arg_names_arr = Util.join( getArgNames(), ", " );
		scope arg_names_and_types = Util.join( getArgNamesAndTypes( Language.CPP ), ", " );
		scope unprocessed_return_type = getReturnType( Language.CPP );

		return Format( d_virtual_wrapper_layout,
			class_name,
			prefixComma( arg_names_and_types ),
			processed_arg_names_arr,
			method_name,
			unprocessed_return_type,
			unprocessed_return_type == "void" ? "" : "return "
		 );
	}
}
