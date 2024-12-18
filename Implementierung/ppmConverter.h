#include <stdio.h>
#include <stdlib.h>

#ifndef PPM_CONVERTER_H
#define PPM_CONVERTER_H

//Source: https://stackoverflow.com/questions/2693631/read-ppm-file-and-store-it-in-an-array-coded-with-c
//Original Author: RPFELGUEIRAS

typedef struct
{
    unsigned char red, green, blue;
} PPMPixel;

typedef struct
{
    uint16_t x, y;
    PPMPixel *data;
} PPMImage;

typedef struct
{
    uint16_t x, y;
    uint8_t *data;
} PGMImage;

#endif