module dcgen.dcgvartype;

import defines;
import Util = tango.text.Util;

// This has to be global due to a bug in the compiler
private enum ReferenceType {
	CONST,
	REFERENCE,
	POINTER
}

class DCGVarType
{
	private const Node arg_node;
	private const Config config;
	
	char[] fundamental_type;
	bool is_primitive;
	private ReferenceType reference_type[]; // Multiple reference types since we can have pointer to pointer, etc
	
	static char[][] REFERENCE_TYPE_LOOKUP;
	
	static this() 
	{
		REFERENCE_TYPE_LOOKUP = cast( char[][] ) new char[ 8 ][ 3 ]; // TODO: A better way to do this?
		REFERENCE_TYPE_LOOKUP[ ReferenceType.CONST ]     = "const";
		REFERENCE_TYPE_LOOKUP[ ReferenceType.REFERENCE ] = "&";
		REFERENCE_TYPE_LOOKUP[ ReferenceType.POINTER ]   = "*";
	}
	
	this( in Node arg_node, in Config config )
	in {
		assert( arg_node != null );
	}
	body {
		this.arg_node = arg_node;
		this.config = config;
		
		parse( arg_node );
	}
	
	char[] layoutCPP()
	{
		char[] str = fundamental_type;
		
		foreach ( type; reference_type ) {
			str ~= REFERENCE_TYPE_LOOKUP[ type ];			
		}
		
		return str;
	}
	
	char[] layoutC()
	{
		auto d_type = fundamental_type;
		if ( !is_primitive )
			d_type = "C" ~ d_type; // In D, all C interface stuff is prefixed with "C"
		
		char[] str = d_type;
		
		bool pointer_ignored = false;
		foreach ( type; reference_type ) {
			// C has no concept of a reference
			if ( type == ReferenceType.REFERENCE )
				type = ReferenceType.POINTER;
			
			// If it's not a primitive, we have the first pointer taken care of by way of alias
			if ( type == ReferenceType.POINTER && !is_primitive && !pointer_ignored ) {
				pointer_ignored = true;
				continue;
			}
			
			str ~= REFERENCE_TYPE_LOOKUP[ type ]; 
		}
		
		// TODO: hack
		str = Util.substitute( str, "const ", cast (char[]) null );
		
		return str;
	}
	
	char[] layoutD()
	{
		auto d_type = fundamental_type;
		if ( !is_primitive )
			d_type = "C" ~ d_type; // In D, all C interface stuff is prefixed with "C"
		
		char[] str = d_type;
		
		foreach ( type; reference_type ) {
			char[] reference_str;
			
			if ( type == ReferenceType.REFERENCE )
				{} // TODO: Do we ignore this? My brain hurts
			else
				assert( false, "TODO" );
			
			str ~= reference_str; 
		}
		
		// TODO: hack
		str = Util.substitute( str, "const ", cast (char[]) null );
		
		return str;
	}
	
	private void parse( in Node node )
	in {
		assert( node != null );
	}
	body {
		switch( node.name )
		{
		case "Struct":
		case "Class":
			is_primitive = false;
			fundamental_type ~= getNodeAttribute( node, "name" );
			break;
			
		case "FundamentalType":
			is_primitive = true;
			fundamental_type ~= getNodeAttribute( node, "name" );
			break;
		
		case "PointerType":
			scope fundamental_node = getFundamentalTypeNode( node );
			assert( fundamental_node != null );
			reference_type ~= ReferenceType.POINTER;
			parse( fundamental_node );
			break;
			
		case "ReferenceType":
			scope fundamental_node = getFundamentalTypeNode( node );
			assert( fundamental_node != null );
			reference_type ~= ReferenceType.REFERENCE;
			parse( fundamental_node );
			break;
			
		case "CvQualifiedType":
			// I think this might be for more than just const'ness, so let's verify that this node is for const
			assert( hasAttributeAndEqualTo( node, "const", "1" ), "I don't know how to handle anything but this!" );
			
			scope fundamental_node = getFundamentalTypeNode( node );
			assert( fundamental_node != null );
			// TODO: Hack
			fundamental_type ~= "const ";
			// End hack
			parse( fundamental_node );
			break;
			
		default:
			assert( false, "Unrecognized variable type: " ~ node.name ~ ". Id is " ~ getNodeAttribute( node, "id" ) );
			break;
		}
	}
	
	private Node getFundamentalTypeNode( in Node node )
	{
		return getNodeByID( node.document, node.getAttribute( "type" ).value );
	}
}