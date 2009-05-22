#ifndef SIMPLE_H
#define SIMPLE_H

#include <stdio.h>

class Simple
{
public:
	Simple() {
		printf( "[C++] Class Simple constructed\n" );
	}
	
	void foobar() {
		printf( "[C++] Foobar called\n" );
	}
};

#endif