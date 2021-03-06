module dcgen.defines;

import tango.text.xml.Document;
import tango.io.Stdout;

alias Document!(char) Doc;
alias Doc.Node Node;

const overrideAttribute = `gccxml(override)`;
const inheritAttribute = `gccxml(inherit)`;

enum Language {
	CPP,
	C,
	D
}

struct Config {
	char[]   input_filepath;
	Language mode;
	char[]   output_directory;
	char[][] include_classes;   // Array of strings specifying what classes to include
	bool     include_globals;
	bool     generate_wrappers; // Generate wrappers for virtual functions?
}

enum Access {
	PUBLIC,
	PROTECTED,
	PRIVATE
}

Access[ char[] ] REVERSE_ACCESS;

static this() {
	REVERSE_ACCESS[ "public" ] = Access.PUBLIC;
	REVERSE_ACCESS[ "protected" ] = Access.PROTECTED;
	REVERSE_ACCESS[ "private" ] = Access.PRIVATE;
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

Node getNodeByID( Doc doc, char[] id )
{
	return doc.query.child.child.filter( filterByID( id ) ).nodes[0];
}

char[] getNodeAttribute( Node node, char[] attribute )
{
	// TODO, error checking
	assert( node.hasAttribute( attribute ), "Cannot retreive attribute: " ~ attribute ~ " -- " ~ node.name ); // TODO: Remove for performance?
	return node.getAttribute( attribute ).value;
}

bool hasAttributeAndEqualTo( Node node, char[] attribute, char[] desired )
{
	if ( node.hasAttribute( attribute ) && getNodeAttribute( node, attribute ) == desired )
		return true;
		
	return false;
}
