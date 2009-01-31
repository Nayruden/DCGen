module dcgen.clazz;

import defines;
import method;
import tango.io.Stdout;
import tango.text.Util;
import tango.text.convert.Format;

/*const base_str = `typedef void D{0};

class C{0} : public {0}
{
private:
	D{0} *implD;

public:
    C{0}( D{0} *implD )
    {
		this->implD = implD;
    }
};

extern "C" {0} *{0}_create( D{0} *implD )
{
	assert( implD != NULL );
	return new C{}( implD );
}

extern "C" void {0}_destroy( {0} *implC )
{
	assert( implC != NULL );
	delete implC;
}
`;*/

const classMethodsDfnC = 
`extern "C" {0} *{0}_create()
{{
	return new {0}();
}

extern "C" void {0}_destroy( {0} *cPtr )
{{
	assert( cPtr != NULL );
	delete cPtr;
}
`;

const classMethodsDeclD =
`typedef void* C{0};
extern ( C ) 
{{ // TODO: Can this be private?
	C{0} {0}_create();
	void {0}_destroy( C{0} cPtr );
`;

const classDfnDStart =
`class {0}
{{
	private C{0} cPtr;
	
	this()
	{{
		cPtr = {0}_create();
	}
	
	~this()
	{{
		{0}_destroy( cPtr );
	}
`;

const classDfnDEnd =
`}
`;

class Clazz
{
	Node classNode;
	Node[] memberNodes;
	
	this( Node classNode )
	{
		this.classNode = classNode;
		
		auto doc = classNode.document;
	
		auto members = classNode.getAttribute( "members" ).value;
		foreach( member; split( members, " " ) ) {
			if ( trim( member ) == "" )
				continue;
		
			auto set = doc.query.child.child.filter( filterByID( member.dup ) ).filter (
				delegate( Node node ) { 					
					if ( node.hasAttribute( "artificial" ) && node.getAttribute( "artificial" ).value == "1" )
						return false;
				
					return true;
				}
			);
			
			if ( set.nodes.length > 0 ) {
				memberNodes ~= set.nodes[ 0 ];
			}
		}		
	}
	
	public char[] cClassDfn()
	{
		char[] classDfn = format( classMethodsDfnC ) ~ "\n";
		
		foreach( memberNode; memberNodes ) {
			switch ( memberNode.name ) {
			case "Field":
				// Stdout.formatln( "This is a field!" );
				break;
				
			case "Method":
				auto method = new Method( classNode, memberNode );
				classDfn ~= method.cMethodDfn() ~ "\n";
				break;
				
			default:
				assert( false, "I don't know what this is!" );
				break;
			} 
		}
		
		return classDfn;
	}
	
	public char[] dClassDfn()
	{
		char[] classDfn = format( classMethodsDeclD ) ~ "\n";
		
		foreach( memberNode; memberNodes ) {
			// Stdout( member ~ "\n" );
			// Stdout.formatln( "{} {}", memberNode.name, memberNode.getAttribute( "name" ).value );
			switch ( memberNode.name ) {
			case "Field":
				// Stdout.formatln( "This is a field!" );
				break;
				
			case "Method":
				auto method = new Method( classNode, memberNode );
				classDfn ~= method.dMethodDecl() ~ "\n";
				break;
				
			default:
				assert( false, "I don't know what this is!" );
				break;
			}
		}
		
		classDfn ~= "}\n\n" ~ format( classDfnDStart );
		
		foreach( memberNode; memberNodes ) {
			// Stdout( member ~ "\n" );
			// Stdout.formatln( "{} {}", memberNode.name, memberNode.getAttribute( "name" ).value );
			switch ( memberNode.name ) {
			case "Field":
				// Stdout.formatln( "This is a field!" );
				break;
				
			case "Method":
				auto method = new Method( classNode, memberNode );
				classDfn ~= method.dMethodDfn();
				break;
				
			default:
				assert( false, "I don't know what this is!" );
				break;
			}
		}
		
		classDfn ~= format( classDfnDEnd );
		
		return classDfn;
	}
	
	private char[] format( char[] formatStr )
	{			
		return Format( formatStr,
			classNode.getAttribute( "name" ).value
		);
	}
}