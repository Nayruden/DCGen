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
private extern ( C ) 
{{
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
	Method[] methods;
	bool needsReflection = false;
	
	this( Node classNode )
	{
		this.classNode = classNode;
		
		auto doc = classNode.document;
		
		Node[] memberNodes;
	
		auto members = classNode.getAttribute( "members" ).value;
		foreach( member; split( members, " " ) ) {
			if ( trim( member ) == "" )
				continue;
		
			auto set = doc.query.child.child.filter( filterByID( member ) );
			
			auto node = set.nodes[ 0 ];
			if ( !hasAttributeAndEqualTo( node, "artificial", "1" ) ) // Not interested in compiler generated functions (yet, TODO)
				memberNodes ~= set.nodes[ 0 ];
		}
		
		
		foreach( memberNode; memberNodes ) {
			switch ( memberNode.name ) {
			case "Field":
				// TODO
				break;
				
			case "Method":
				if ( hasAttributeAndEqualTo( memberNode, "access", "private" ) ) // Can't do any wrapping here
					break;
					
				auto method = new Method( classNode, memberNode );
				if ( method.needsReflection == true )
					needsReflection = true;
				methods ~= method;
				break;
				
			default:
				assert( false, "I don't know what this is!" );
				break;
			} 
		}		
	}
	
	public char[] cClassDfn()
	{
		char[] classDfn = format( classMethodsDfnC ) ~ "\n";
		
		foreach( method; methods ) {
			classDfn ~= method.cMethodDfn() ~ "\n";
		}
		
		return classDfn;
	}
	
	public char[] dClassDfn()
	{
		char[] classDfn = format( classMethodsDeclD );
		
		foreach( method; methods ) {
			classDfn ~= method.dMethodDecl();
		}
		
		classDfn ~= "}\n\n" ~ format( classDfnDStart ) ~ "\n";
		
		foreach( method; methods ) {
			classDfn ~= method.dMethodDfn() ~ "\n";
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