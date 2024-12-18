#ifndef CONSTANTS_H
#define CONSTANTS_H

#include <stdio.h>
#include <stdlib.h>

#define DEFAULT_INPUT "test.ppm"

#define MAIN_IMPLEMENTATION "Main Implementation - Assembly with SIMD"
#define ALTERNATIVE_IMPLEMENTATION_1 "Assembly without SIMD"
#define ALTERNATIVE_IMPLEMENTATION_2 "C with Padded Array"
#define ALTERNATIVE_IMPLEMENTATION_3 "C Normal Implementation"

void printImplementationVersion(int version)
{
    switch (version)
    {
    case 0:
        printf("%s\n", MAIN_IMPLEMENTATION);
        break;
    case 1:
        printf("%s\n", ALTERNATIVE_IMPLEMENTATION_1);
        break;
    case 2:
        printf("%s\n", ALTERNATIVE_IMPLEMENTATION_2);
        break;
    case 3:
        printf("%s\n", ALTERNATIVE_IMPLEMENTATION_3);
        break;
    default:
        printf("%s\n", MAIN_IMPLEMENTATION);
        break;
    }
}

char *defaultOutputFilename(int version)
{
    switch (version)
    {
    case 0:
        return "result/result_from_main_implementation.pgm";
    case 1:
        return "result/result_from_assembly_no_SIMD.pgm";
    case 2:
        return "result/result_from_C_padded.pgm";
    case 3:
        return "result/result_from_C_normal.pgm";
    default:
        return "result/result_from_main_implementation.pgm";
    }
}

#endif