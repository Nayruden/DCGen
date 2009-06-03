#ifndef SIMPLE_H
#define SIMPLE_H

#include <stdio.h>
#include "../lib.h"

static const int MAX_LINE = 256;

static char *boolToString( bool b )
{
	if ( b )
		return "true";
	return "false";
}

class PassSimple
{
public:
	PassSimple( int x, float y, bool b, char str[] )
	{
		snprintf( buffer, MAX_LINE, "Class Pass constructed (x=%i,y=%f,b=%s,str=%s)", x, y, boolToString( b ), str );
		outputLine( buffer );
		this->x = x;
		this->y = y;
		this->b = b;
		this->str = str;
	}

	int setX( int x )
	{
		snprintf( buffer, MAX_LINE, "Previous value of x: %i, new value: %i", this->x, x );
		outputLine( buffer );
		int old_value = this->x;
		this->x = x;

		return old_value;
	}

	float setY( float y )
	{
		snprintf( buffer, MAX_LINE, "Previous value of y: %f, new value: %f", this->y, y );
		outputLine( buffer );
		float old_value = this->y;
		this->y = y;

		return old_value;
	}

	bool setB( bool b )
	{
		snprintf( buffer, MAX_LINE, "Previous value of b: %s, new value: %s", boolToString( this->b ), boolToString( b ) );
		outputLine( buffer );
		bool old_value = this->b;
		this->b = b;

		return old_value;
	}

	char *setStr( char str[] )
	{
		snprintf( buffer, MAX_LINE, "Previous value of str: %s, new value: %s", this->str, str );
		outputLine( buffer );
		char *old_value = this->str;
		this->str = str;

		return old_value;
	}

private:
	int x;
	float y;
	bool b;
	char *str;
	char buffer[ MAX_LINE ];
};

class PassPtr
{
public:
	PassPtr( int x, float y, int *z, const bool *const b, char **str ) : b( b )
	{
		snprintf( buffer, MAX_LINE, "Class Pass constructed (x=%i,y=%f,z=%i,b=%s,str=%s)", x, y, *z, boolToString( b ), *str );
		outputLine( buffer );
		this->x = x;
		this->y = y;
		this->z = z;
		this->str = str;
	}

	int setX( int x )
	{
		snprintf( buffer, MAX_LINE, "Previous value of x: %i, new value: %i", this->x, x );
		outputLine( buffer );
		int old_value = this->x;
		this->x = x;

		return old_value;
	}

	float setY( float y )
	{
		snprintf( buffer, MAX_LINE, "Previous value of y: %f, new value: %f", this->y, y );
		outputLine( buffer );
		float old_value = this->y;
		this->y = y;

		return old_value;
	}

	int *setZ( int *z )
	{
		snprintf( buffer, MAX_LINE, "Previous value of z: %i, new value: %i", *this->z, *z );
		outputLine( buffer );
		int *old_value = this->z;
		this->z = z;

		return old_value;
	}

	const bool *const getB()
	{
		return b;
	}

	char **setStr( char **str )
	{
		snprintf( buffer, MAX_LINE, "Previous value of str: %s, new value: %s", *this->str, *str );
		outputLine( buffer );
		char **old_value = this->str;
		this->str = str;

		return old_value;
	}

private:
	int x;
	float y;
	int *z;
	char **str;
	char buffer[ MAX_LINE ];
	const bool *const b;
};

#endif
