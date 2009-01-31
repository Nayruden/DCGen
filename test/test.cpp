#include "test.h"

extern "C" A *A_create()
{
	return new A();
}

extern "C" void A_destroy( A *cPtr )
{
	assert( cPtr != NULL );
	delete cPtr;
}

extern "C" bool dcgen_1A( A *cPtr, int i )
{
	assert( cPtr != NULL );
	return cPtr->odd( i );
}

