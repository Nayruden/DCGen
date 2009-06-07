module dcgen.dcgvartype;

import defines;
import Util = tango.text.Util;

// This has to be global due to a bug in the compiler
enum ReferenceType {
	CONST,
	REFERENCE,
	POINTER,
	ARRAY // TODO: do this
}

class DCGVarType
{
//	private const Config config;
	
	char[] fundamental_type;
	bool is_primitive;
	private ReferenceType[] reference_type; // Multiple reference types since we can have pointer to pointer, etc
	
	this( in Node arg_node, in Config config )
	in {
		assert( arg_node != null );
	}
	body {
//		this.config = config;
		parse( arg_node );
	}
	
	this( in ReferenceType[] reference_type, in char[] fundamental_type, bool is_primitive ) // TODO: Add config or remove entirely
	{
		this.reference_type = reference_type;
		this.fundamental_type = fundamental_type;
		this.is_primitive = is_primitive;
	}
	
	ReferenceType[] referenceType()
	{
		return reference_type.dup; // No touchy
	}
	
	char[] fundamentalType()
	{
		return fundamental_type.dup; // No touchy
	}
	
	// NOTE: Remember that C is used as the glue between C++ and D, it's always put as externs inside a D file
	char[] layout ( in Language language )
	{
		char[] typ = fundamental_type;
		if ( language != Language.CPP && !is_primitive )
			typ = "C" ~ typ; // In D (and since it resides in the same file, C), all C interface stuff is prefixed with "C"
		
		char[] qualifier;
		bool pointer_ignored = false;
		foreach ( i, type; reference_type ) {
			switch (type) {
				case ReferenceType.CONST:
					if ( language != Language.CPP ) // C Ignores const
						break; // TODO: Can we const well in D?
					
					if ( i == reference_type.length - 1 ) // If the last qualifying type is const, it means the fundamental type is const
						typ = "const " ~ typ;
					else
						qualifier = "const " ~ qualifier;
				break;
				
				case ReferenceType.REFERENCE:
					if ( language != Language.CPP ) { // Treat it like a pointer (C doesn't support Refs)
						// If it's not a primitive, we have the first pointer taken care of by way of alias
						if ( !is_primitive && !pointer_ignored ) {
							pointer_ignored = true;
							break;
						}
						qualifier = "*" ~ qualifier; // TODO: Check to make sure refs are not null in contract?
					}
					else
						qualifier = "&" ~ qualifier;
				break;
				
				case ReferenceType.POINTER:
					// If it's not a primitive, we have the first pointer taken care of by way of alias
					if ( language != Language.CPP && !is_primitive && !pointer_ignored ) {
						pointer_ignored = true;
						break;
					}
					qualifier = "*" ~ qualifier;
				break;
				
				case ReferenceType.ARRAY: // TODO: Think this through better
					qualifier = "[]" ~ qualifier;
				break;
				
				default:
					assert( false, "Should never get here!" );
				break;
			}
		}
		
		if ( language != Language.D ) // I'm a stickler about how I like my formatting in different languages
			return typ ~ " " ~ qualifier;
		else
			return typ ~ qualifier ~ " ";
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
				fundamental_type = getNodeAttribute( node, "name" );
			break;
				
			case "FundamentalType":
				is_primitive = true;
				fundamental_type = getNodeAttribute( node, "name" );
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
				// I think this XML node might be for more than just const'ness, so let's verify that this node is for const
				assert( hasAttributeAndEqualTo( node, "const", "1" ), "I don't know how to handle anything but const here!" );
				
				scope fundamental_node = getFundamentalTypeNode( node );
				assert( fundamental_node != null );
				reference_type ~= ReferenceType.CONST;
				parse( fundamental_node );
			break;
				
			case "Typedef":
				// TODO: Obey this in the future
				scope fundamental_node = getFundamentalTypeNode( node );
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