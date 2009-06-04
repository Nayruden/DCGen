module dcgen.dcgprocess;

import dcgvartype;
import defines;

private alias char[] function( ref DCGVarType, ref char[] ) conversionFunctionType;
private struct Conversion
{
	Language from_language;
	Language to_language;
	conversionFunctionType conversion_function;
}
Conversion[] conversions;

class DCGProcess
{
	static char[] convert( Language from_language, Language to_language, ref DCGVarType typ, ref char[] name )
	{
		char[] str;
		
		foreach ( conversion; conversions ) {
			if ( from_language == conversion.from_language && to_language == conversion.to_language ) {
				str ~= conversion.conversion_function( typ, name );
			}
		}
		
		if ( str.length > 0 ) // There's been changes, let's run it through the grinder again
			str ~= convert( from_language, to_language, typ, name );
		
		return str;
	}
}

static this()
{
	Conversion conversion;
	
	////////////////////
	// Convert D-style strings to C-style
	////////////////////
	conversion.from_language = Language.D;
	conversion.to_language = Language.C;
	conversion.conversion_function = 
	function char[] ( ref DCGVarType typ, ref char[] name ) {
		char[] str;
		char[] fundamental_type = typ.fundamentalType;
		ReferenceType[] reference_type = typ.referenceType;
		
		if ( fundamental_type == "char" && reference_type == [ ReferenceType.POINTER ] ) {
			typ = new DCGVarType( [ ReferenceType.ARRAY ], "char", true );
			char[] new_name = name ~ "_new"; // TODO: better naming
			scope old_name = name;
			name = new_name;
			str ~= "scope " ~ new_name ~ " = toStringz( " ~ old_name ~ " );\n";
		}
		
		return str;
	};
	
	conversions ~= conversion;
	
	////////////////////
	// Convert C-style strings to D-style
	////////////////////
	conversion.from_language = Language.C;
	conversion.to_language = Language.D;
	conversion.conversion_function = 
	function char[] ( ref DCGVarType typ, ref char[] name ) {
		char[] str;
		char[] fundamental_type = typ.fundamentalType;
		ReferenceType[] reference_type = typ.referenceType;
		
		if ( fundamental_type == "char" && reference_type == [ ReferenceType.POINTER ] ) {
			typ = new DCGVarType( [ ReferenceType.ARRAY ], "char", true );
			char[] new_name = name ~ "_new"; // TODO: better naming
			scope old_name = name;
			name = new_name;
			str ~= "auto " ~ new_name ~ " = fromStringz( " ~ old_name ~ " );\n";
		}
		
		return str;
	};
	
	conversions ~= conversion;
}
