module dcgen.defines;

import tango.text.xml.Document;
import tango.io.Stdout;

alias Document!(char) Doc;
alias Doc.Node Node;

const overrideAttribute = `gccxml(override)`;
const inheritAttribute = `gccxml(inherit)`;

struct Config {
	bool expandVirtuals = false;
}

alias bool delegate( Node node ) filterDelegate;

class FilterByID
{
	char[] id;
	
	this( char[] id )
	{
		this.id = id;
	}
	
	public bool filter( Node node )
	{
		if ( !hasAttributeAndEqualTo( node, "id", id ) )
			return false;
		return true;
	}
}

filterDelegate filterByID( char[] id ) {
	auto filterClass = new FilterByID( id );
	return &filterClass.filter;
}

char[] typeNodeToString( in Node node )
{
	switch( node.name )
	{
	case "FundamentalType":
	case "Struct":
	case "Class":
		return node.getAttribute( "name" ).value;
		break;
	
	case "PointerType":
		auto fundamentalNode = getNodeByID( node.document, node.getAttribute( "type" ).value );
		return typeNodeToString( fundamentalNode ) ~ "*";
		break;
		
	default:
		assert( false, "Unrecognized tag: " ~ node.name );
		break;
	}
}

Node getNodeByID( Doc doc, char[] id )
{
	return doc.query.child.child.filter( filterByID( id ) ).nodes[0];
}

char[] getNodeAttribute( Node node, char[] attribute )
{
	// TODO, error checking
	return node.getAttribute( attribute ).value;
}

bool hasAttributeAndEqualTo( Node node, char[] attribute, char[] desired )
{
	if ( node.hasAttribute( attribute ) && getNodeAttribute( node, attribute ) == desired )
		return true;
		
	return false;
}
