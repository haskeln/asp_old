#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

int getPixelAt(int width, int x, int y)
{
    return x + (width * y);
}

void greyScaleConvert_nopadding(const uint8_t *data, size_t width, size_t height, float constA, float constB, float constC, uint8_t *output)
{
    for (uint32_t i = 0; i < height * width; i++)
        *(output + i) = (constA * *(data + i * 3) + constB * *(data + i * 3 + 1) + constC * *(data + i * 3 + 2)) / (constA + constB + constC);
}

void laplaceFilter_nopadding(uint8_t *input, size_t width, size_t height, uint8_t *output)
{
    uint32_t counter = 0;
    for (uint16_t y = 0; y < height; y++)
        for (uint16_t x = 0; x < width; x++)
        {
            uint8_t down = (y == 0) ? 0 : *(input + getPixelAt(width, x, y - 1));
            uint8_t up = (y == height - 1) ? 0 : *(input + getPixelAt(width, x, y + 1));
            uint8_t left = (x == 0) ? 0 : *(input + getPixelAt(width, x - 1, y));
            uint8_t right = (x == width - 1) ? 0 : *(input + getPixelAt(width, x + 1, y));

            uint16_t checkRight = up + down + left + right;
            uint16_t checkLeft = 4 * *(input + getPixelAt(width, x, y));
            if (checkLeft > checkRight)
                *(output + counter++) = checkLeft - checkRight;
            else
                *(output + counter++) = checkRight - checkLeft;
        }
}

void softFocus_nopadding(uint8_t *input, size_t width, size_t height, uint8_t *output)
{
    uint32_t counter = 0;
    for (uint16_t y = 0; y < height; y++)
        for (uint16_t x = 0; x < width; x++)
        {
            uint8_t down = (y == 0) ? 0 : *(input + getPixelAt(width, x, y - 1));
            uint8_t up = (y == height - 1) ? 0 : *(input + getPixelAt(width, x, y + 1));
            uint8_t left = (x == 0) ? 0 : *(input + getPixelAt(width, x - 1, y));
            uint8_t right = (x == width - 1) ? 0 : *(input + getPixelAt(width, x + 1, y));

            uint8_t downLeft = (y == 0 || x == 0) ? 0 : *(input + getPixelAt(width, x - 1, y - 1));
            uint8_t upLeft = (y == height - 1 || x == 0) ? 0 : *(input + getPixelAt(width, x - 1, y + 1));
            uint8_t downRight = (y == 0 || x == width - 1) ? 0 : *(input + getPixelAt(width, x + 1, y - 1));
            uint8_t upRight = (y == height - 1 || x == width - 1) ? 0 : *(input + getPixelAt(width, x + 1, y + 1));

            *(output + counter++) = (2 * (up + down + left + right) + downLeft + upLeft + downRight + upRight + 4 * *(input + getPixelAt(width, x, y))) / 16;
        }
}

void denoise_nopadding(const uint8_t *img, size_t width, size_t height, float a, float b, float c, uint8_t *tmp1, uint8_t *tmp2, uint8_t *tmp3, uint8_t *result)
{
    greyScaleConvert_nopadding(img, width, height, a, b, c, tmp1);
    laplaceFilter_nopadding(tmp1, width, height, tmp2);
    softFocus_nopadding(tmp1, width, height, tmp3);
    for (uint32_t i = 0; i < height * width; i++)
        *(result + i) = (*(tmp2 + i) * (*(tmp1 + i) - *(tmp3 + i))) / 1020 + *(tmp3 + i);
}
