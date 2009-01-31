module test;

typedef void* CA;
extern ( C ) 
{ // TODO: Can this be private?
	CA A_create();
	void A_destroy( CA cPtr );

	bool dcgen_1A( CA cPtr, int i );

}

class A
{
	private CA cPtr;
	
	this()
	{
		cPtr = A_create();
	}
	
	~this()
	{
		A_destroy( cPtr );
	}
	bool odd( int i )
	{
		assert( cPtr != null );
		return dcgen_1A( cPtr, i );
	}
}
