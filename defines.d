module dcgen.defines;

import tango.text.xml.Document;
import tango.io.Stdout;

alias Document!(char) Doc;
alias Doc.Node Node;

const overrideAttribute = `gccxml(override)`;
const inheritAttribute = `gccxml(inherit)`;

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
		return node.getAttribute( "name" ).value;
		break;
	
	case "PointerType":
		auto fundamentalNode = getNodeByID( node.document, node.getAttribute( "type" ).value );
		return typeNodeToString( fundamentalNode ) ~ "*";
		break;
		
	default:
		assert( false, "Unrecognized tag" );
		break;
	}
}

Node getNodeByID( Doc doc, char[] id )
{
	return doc.query.child.child.filter( filterByID( id ) ).nodes[0];
}

bool hasAttributeAndEqualTo( Node node, char[] attribute, char[] desired )
{
	if ( node.hasAttribute( attribute ) && node.getAttribute( attribute ).value == desired )
		return true;
		
	return false;
}
