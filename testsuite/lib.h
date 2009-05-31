#ifndef DCGEN_TEST_LIB_H
#define DCGEN_TEST_LIB_H

#include <stdio.h>

const char FILE_PATH[] = "./output.txt";
const int MAX_LINE_LENGTH = 256;

class Output {
public:
	static void outputLine( char str[] )
	{
		int str_len = snprintf( buffer, MAX_LINE_LENGTH, "[C++] %s\n", str );
		printf( buffer );
		fseek( file, 0, SEEK_END );
		fwrite( buffer, sizeof (char), str_len, file );
		fflush( file );
	}

private:
	static FILE *file;
	static char buffer[ MAX_LINE_LENGTH ];
	static const Output output; // Self-register

	Output()
	{
		file = fopen( FILE_PATH, "a" );
	}

	~Output()
	{
		fclose( file );
		file = NULL;
	}
};

FILE *Output::file;
char Output::buffer[ MAX_LINE_LENGTH ];
const Output Output::output;

// Convenience function
void outputLine( char str[] )
{
	Output::outputLine( str );
}

#endif
