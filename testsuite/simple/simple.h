#ifndef SIMPLE_H
#define SIMPLE_H

#include <stdio.h>
#include "../lib.h"

class Simple
{
public:
	Simple() {
		outputLine( "Class Simple constructed" );
	}

	void foobar() {
		outputLine( "Foobar called" );
	}
};

#endif
