#ifndef SIMPLE_H
#define SIMPLE_H

#include <stdio.h>
#include "../lib.h"

const int MAX_LINE = 64;

class Pass
{
public:
	Pass( int x, float y )
	{
		snprintf( buffer, MAX_LINE, "Class Pass constructed (x=%i,x=%f)", x, y );
		outputLine( buffer );
		this->x = x;
		this->y = y;
	}

	Pass()
	{
		x = y = 0;
	}

	int setX( int x ) {
		snprintf( buffer, MAX_LINE, "Previous value of x: %i, new value: %i", this->x, x );
		outputLine( buffer );
		int old_value = this->x;
		this->x = x;

		return old_value;
	}

	float setY( float y ) {
		snprintf( buffer, MAX_LINE, "Previous value of y: %f, new value: %f", this->y, y );
		outputLine( buffer );
		float old_value = this->y;
		this->y = y;

		return old_value;
	}

private:
	int x;
	float y;
	char buffer[ MAX_LINE ];
};

#endif
