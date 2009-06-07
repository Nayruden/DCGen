module dcgen.functiontype;

import defines;
import dcgvartype;
import Integer = tango.text.convert.Integer;

class FunctionType
{
	protected Node function_node;
	protected DCGVarType[] arg_types;
	protected DCGVarType return_type;
	
	this( Node function_node )
	{
		this.function_node = function_node;
		
		foreach ( child; function_node.children ) {
			if ( child == null || child.name == null )
				continue;
				
			scope type_node = getNodeByID( function_node.document, getNodeAttribute( child, "type" ) ); // Get the type pointed to by each child
			auto arg_type = new DCGVarType( type_node );
			
			arg_types ~= arg_type;
		}
		
		if ( function_node.hasAttribute( "returns" ) ) {
			scope return_type_node = getNodeByID( function_node.document, getNodeAttribute( function_node, "returns" ) );
			return_type = new DCGVarType( return_type_node );
		}
	}
	
	public char[][] getArgNames()
	{
		char[][] processed_arg_names_arr;
		int arg_num = 0;
		foreach( child; function_node.children ) {
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
	
	public char[][] getArgTypes( Language language, DCGVarType[] arg_types=null )
	{
		if ( arg_types == null )
			arg_types = this.arg_types; // TODO: Better naming
		
		char[][] arg_types_str;
		
		foreach( method_type; arg_types ) {			
			arg_types_str ~= method_type.layout( language );
		}
		
		return arg_types_str;
	}
	
	public char[][] getArgNamesAndTypes( Language language, DCGVarType[] types=null )
	{
		if ( types == null )
			types = this.arg_types; // TODO: Better naming
		
		char[][] arg_types = getArgTypes( language, types );
		char[][] arg_names = getArgNames();

		return combineArgNamesAndTypes( arg_types, arg_names );
	}
	
	public char[][] combineArgNamesAndTypes( char[][] arg_types, char[][] arg_names )
	{
		char[][] arg_names_and_types;

		for ( int i = 0; i < arg_types.length; i++ ) {
			arg_names_and_types ~= arg_types[ i ] ~ arg_names[ i ];
		}
		
		return arg_names_and_types;
	}
	
	public char[] getReturnType( Language language, DCGVarType typ=null )
	{
		if ( typ is null && return_type is null ) // Constructor and destructor have no return
			return "";
		
		if ( typ is null )
			typ = return_type;
		
		return typ.layout( language );
	}
}