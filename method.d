module dcgen.method;

import defines;
import tango.io.Stdout;
import tango.text.convert.Format;

// 0 = Class name
// 1 = Function name unmangled
// 2 = Function name mangled
// 3 = Return type
// 4 = Args
// 5 = Pass to func
// 6 = Return?
const methodDfnC = 
`extern "C" {3} dcgen_{2}( C{0} cPtr{4} )
{{
	assert( cPtr != NULL );
	{6}cPtr->{1}( {5} );
}
`;

const methodDeclD = 
`	{3} dcgen_{2}( {0} *cPtr{4} );
`;

const methodDfnD = 
`	{3} {1}( {4} )
	{{
		assert( cPtr != null );
		{6}dcgen_{2}( cPtr, {5} );
	}
`;

class Method
{
	Node classNode, methodNode;
	
	char[] returnType,
	       argStr,  // The arguments, IE "int i, char c, Foo bar"
	       passStr; // The pass string, IE "i, c, bar"
	
	this( Node classNode, Node methodNode )
	{
		this.classNode = classNode;
		this.methodNode = methodNode;
		
		auto returnNode = getNodeByID( methodNode.document, methodNode.getAttribute( "returns" ).value );
		returnType = typeNodeToString( returnNode );
		argStr = argString( methodNode );
		passStr = passString( methodNode );
	}
	
	public char[] cMethodDfn()
	{		
		return format( methodDfnC );
	}
	
	public char[] dMethodDecl()
	{
		return format( methodDeclD );
	}
	
	public char[] dMethodDfn()
	{
		return format( methodDfnD, false );
	}
	
	private char[] format( char[] formatStr, bool commaOnArgs=true )
	{
		auto args = argStr;
		if ( commaOnArgs )
			args = ", " ~ args;
			
		return Format( formatStr,
			classNode.getAttribute( "name" ).value,        // 0 = Class name
			methodNode.getAttribute( "name" ).value,       // 1 = Function name unmangled
			classNode.getAttribute( "mangled" ).value,     // 2 = Function name mangled
			returnType,                                    // 3 = Return type
			args,                                          // 4 = Args
			passStr,                                       // 5 = Pass to func
			returnType == "void" ? "" : "return "          // 6 = Return?
		);
	}
	
	private char[] argString( Node methodNode )
	{
		if ( !methodNode.hasChildren )
			return null;
			
		char[] str;
			
		foreach( child; methodNode.children ) {
			if ( child.name == null )
				continue;
				
			auto typeNode = getNodeByID( methodNode.document, child.getAttribute( "type" ).value );
			auto type = typeNodeToString( typeNode );
			auto name = child.getAttribute( "name" ).value;
			str ~= type ~ " " ~ name ~ ", ";
		}
		return str[ 0 .. $-2 ];
	}
	
	char[] passString( Node methodNode )
	{
		if ( !methodNode.hasChildren )
			return null;
			
		char[] str;
			
		foreach( child; methodNode.children ) {
			if ( child.name == null )
				continue;
				
			auto name = child.getAttribute( "name" ).value;
			str ~= name ~ ", ";
		}
		return str[ 0 .. $-2 ]; // Cut off the ", " at the end
	}
}
