#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>


void greyScaleConvert(const uint8_t *data, size_t width, size_t height, float constA, float constB, float constC, uint8_t *output)
{
    uint32_t iCounter = 0;
    uint32_t oCounter = 0;

    for (uint16_t x = 0; x <= width; x++)
        *(output + oCounter++) = 0;
    for (uint16_t y = 0; y < height; y++)
    {
        *(output + oCounter++) = 0;
        for (uint16_t x = 0; x < width; x++)
        {
            *(output + oCounter++) = (uint8_t)((constA * *(data + iCounter) + constB * *(data + iCounter + 1) + constC * *(data + iCounter + 2)) / (constA + constB + constC));
            iCounter += 3;
        }
    }
    for (uint16_t x = 0; x <= width; x++)
        *(output + oCounter++) = 0;
    *(output + oCounter) = 0;
}

void laplaceFilter(uint8_t *input, size_t width, size_t height, uint8_t *output)
{
    int counter = width + 2;
    for (uint16_t y = 0; y < height; y++)
    {
        for (uint16_t x = 0; x < width; x++)
        {
            uint8_t down = *(input + counter - width - 1);
            uint8_t up = *(input + counter + width + 1);
            uint8_t left = *(input + counter - 1);
            uint8_t right = *(input + counter + 1);

            uint16_t checkRight = up + down + left + right;
            uint16_t checkLeft = 4 * *(input + counter);
            if (checkLeft > checkRight)
                *(output + counter++) = checkLeft - checkRight;
            else
                *(output + counter++) = checkRight - checkLeft;
        }
        counter++;
    }
}

void softFocus(uint8_t *input, size_t width, size_t height, uint8_t *output)
{
    uint32_t counter = width + 2;
    for (uint16_t y = 0; y < height; y++)
    {
        for (uint16_t x = 0; x < width; x++)
        {
            uint8_t down = *(input + counter - width - 1);
            uint8_t up = *(input + counter + width + 1);
            uint8_t left = *(input + counter - 1);
            uint8_t right = *(input + counter + 1);

            uint8_t downLeft = *(input + counter - width - 2);
            uint8_t upLeft = *(input + counter + width);
            uint8_t downRight = *(input + counter - width);
            uint8_t upRight = *(input + counter + width + 2);

            *(output + counter) = (2 * (up + down + left + right) + downLeft + upLeft + downRight + upRight + 4 * *(input + counter)) / 16;
            counter++;
        }
        counter++;
    }
}

void denoise(const uint8_t *img, size_t width, size_t height, float a, float b, float c, uint8_t *tmp1, uint8_t *tmp2, uint8_t *tmp3, uint8_t *result)
{
    greyScaleConvert(img, width, height, a, b, c, tmp1);
    laplaceFilter(tmp1, width, height, tmp2);
    softFocus(tmp1, width, height, tmp3);

    uint32_t iCounter = width + 2;
    uint32_t oCounter = 0;

    for (uint16_t y = 0; y < height; y++)
    {
        for (uint16_t x = 0; x < width; x++)
        {
            *(result + oCounter++) = (*(tmp2 + iCounter) * (*(tmp1 + iCounter) - *(tmp3 + iCounter))) / 1020 + *(tmp3 + iCounter);
            iCounter++;
        }
        iCounter++;
    }
}