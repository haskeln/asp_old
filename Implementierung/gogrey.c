#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>
#include <string.h>
#include <time.h>

#include "calculation.c"
#include "oldCalculation.c"
#include "ppmConverter.c"
#include "constants.h"

void denoise_SIMD(const uint8_t *img, size_t width, size_t height, float a, float b, float c, uint8_t *tmp1, uint8_t *tmp2, uint8_t *tmp3, uint8_t *result);
void denoise_S(const uint8_t *img, size_t width, size_t height, float a, float b, float c, uint8_t *tmp1, uint8_t *tmp2, uint8_t *tmp3, uint8_t *result);

double currentTime(void)
{
    struct timespec t;
    clock_gettime(CLOCK_MONOTONIC, &t);
    return (double)t.tv_sec + t.tv_nsec * 1e-9;
}

void pixelToArray(PPMImage *img, uint8_t *output)
{
    for (int i = 0; i < img->x * img->y; i++)
    {
        *(output + 3 * i) = img->data[i].red;
        *(output + 3 * i + 1) = img->data[i].green;
        *(output + 3 * i + 2) = img->data[i].blue;
    }
}

void calculate(int implementation, int perf_measure, char *input, char *output)
{
    PPMImage *img = readPPM(input);
    PGMImage *result = (PGMImage *)malloc(sizeof(PGMImage));

    uint8_t *tempData1 = malloc((img->x * img->y + 2 * img->x + img->y + 3) * sizeof(uint8_t));
    uint8_t *tempData2 = malloc((img->x * img->y + 2 * img->x + img->y + 3) * sizeof(uint8_t));
    uint8_t *tempData3 = malloc((img->x * img->y + 2 * img->x + img->y + 3) * sizeof(uint8_t));
    uint8_t *newData = malloc(img->x * img->y * sizeof(uint8_t));
    uint8_t *oldData = malloc(img->x * img->y * 3 * sizeof(uint8_t));

    if (tempData1 == NULL || tempData2 == NULL || tempData3 == NULL || newData == NULL || oldData == NULL)
    {
        printf("Allocation failed! Please try again!\n");
        exit(1);
    }

    if (img)
    {
        pixelToArray(img, oldData);
        double a, b, c = 0;
        int ite = perf_measure == 0 ? 1 : perf_measure;
        for (int i = 0; i < ite; i++)
        {

            switch (implementation)
            {
            case 0:
                // ASM SIMD
                a = currentTime();
                denoise_SIMD(oldData, img->x, img->y, .2126, .7152, .0722, tempData1, tempData2, tempData3, newData);
                b = currentTime();
                break;
            case 1:
                // ASM Padded Normal
                a = currentTime();
                denoise_S(oldData, img->x, img->y, .2126, .7152, .0722, tempData1, tempData2, tempData3, newData);
                b = currentTime();
                break;
            case 2:
                // C padded
                a = currentTime();
                denoise(oldData, img->x, img->y, .2126, .7152, .0722, tempData1, tempData2, tempData3, newData);
                b = currentTime();
                break;
            case 3:
                // C Normal
                a = currentTime();
                denoise_nopadding(oldData, img->x, img->y, .2126, .7152, .0722, tempData1, tempData2, tempData3, newData);
                b = currentTime();
                break;
            default:
                // C ASM SIMD
                a = currentTime();
                denoise_SIMD(oldData, img->x, img->y, .2126, .7152, .0722, tempData1, tempData2, tempData3, newData);
                b = currentTime();
            }

            c += b - a;
        }
        if (perf_measure)
        {
            printf("-------------------------------\n");
            printf("Performance report:\n");
            printImplementationVersion(implementation);
            printf("The average time it takes to do %d iteration of greyscaling is: %f seconds\n", perf_measure, c / perf_measure);
            printf("-------------------------------\n");
        }
        result->x = img->x;
        result->y = img->y;
        result->data = newData;
        writePGM(output, result);
    }
    free(img->data);
    free(img);
    free(result);

    free(tempData1);
    free(tempData2);
    free(tempData3);
    free(newData);
    free(oldData);
}

void test_performance_mode()
{
    for (int i = 0; i < 4; i++)
    {
        calculate(i, 1000, DEFAULT_INPUT, defaultOutputFilename(i));
    }
}

int main(int argc, char *argv[])
{
    int option;
    int version = 0;
    int performance = 0;
    int perf_test_mode = 0;
    char *input_file = DEFAULT_INPUT;
    char output_file[55]={};
    char *remaining;

    float coeffs[3] = {.2126, .7152, .0722}; // default coefficients

    static struct option long_options[] = {
        {"coeffs", required_argument, NULL, 0},
        {"help", no_argument, NULL, 'h'},
        {NULL, 0, NULL, 0}};

    while ((option = getopt_long(argc, argv, "V:B:o:ht", long_options, NULL)) != -1)
    {
        switch (option)
        {
        case 'V':
            if (atoi(optarg) < 0 || atoi(optarg) > 3) {
                printf("Available version numbers are: 0, 1, 2, 3!\n");
                exit(EXIT_FAILURE);
            }
            version = strtol(optarg, &remaining, 10);
            break;
        case 'B':
            if (atoi(optarg) < 0) {
                printf("Iteration number must be positive!\n");
                exit(EXIT_FAILURE);
            }
            performance = strtol(optarg, &remaining, 10);
            break;
        case 't':
            perf_test_mode = 1;
            break;
        case 'o':
            if (strlen(optarg) > 50){
                printf("Max characters for output name is 50 characters!\n");
                exit(EXIT_FAILURE);

            }
            for(size_t k = 0; k < strlen(optarg); k++) {
                if(optarg[k] < 48 || (optarg[k] > 57 && optarg[k] < 65) || ( optarg[k] > 90 && optarg[k] < 97) || optarg[k] > 122){
                    printf("Invalid character for output name! Only numbers 0-9 and letters a-z or A-Z are allowed!\n");
                    exit(EXIT_FAILURE);
                }
            }
            strcpy(output_file, optarg);
            strcat(output_file, ".pgm");
            break;
        case 0:
            sscanf(optarg, "%f,%f,%f", &coeffs[0], &coeffs[1], &coeffs[2]);
            break;
        case 'h':
            // Print help message and exit
            printf("Usage: %s [options] <input_file>\n", argv[0]);
            printf("Options:\n");

            printf("-V <value> Implementatioin version\n");
            printf("\t0 : Main Implementation - Assembly with SIMD (default)\n\t1 : Assembly without SIMD\n\t2 : C with Padded Array\n\t3 : C Normal Implementation\n");

            printf("-B <value> Measure performance with <value>-iterations\n");
            printf("\t0           : Off (default)\n\tOther values: On with <value> as number of iterations\n");

            printf("-o <filename> Set output filename (default : result/result.ppm)\n");
            printf("\tOnly numbers 0-9 and letters a-z or A-Z are allowed. Max 50 characters.\n");
            printf("--coeffs <a,b,c> Set coefficients for grayscale conversion (default : 0.2126, 0.7152, 0.0722)\n");
            printf("\tOnly 3 first coeff inputs are taken. The rest are ignored.\n");
            printf("-h, --help     Display this help message\n\n");
            printf("In case of multiple similar options (ex: -V1 -V2), only last option is taken.\n\n");
            exit(EXIT_SUCCESS);
        default:
            // Invalid option
            fprintf(stderr, "Invalid option: %c\n", optopt);
            exit(EXIT_FAILURE);
        }
    }

    // Parse positional argument
    if (optind < argc)
    {
        input_file = argv[optind];
    }

    // Now you can use the parsed values as needed in your program
    // For example:

    if (perf_test_mode)
    {
        test_performance_mode();
    }
    else
    {
        if (strcmp(output_file, "") == 0)
        {
            strcpy(output_file, defaultOutputFilename(version));
        }
        calculate(version, performance, input_file, output_file);
        printf("Version: ");
        printImplementationVersion(version);

        printf("Performance Measurement: %s\n", performance ? "On" : "Off");
        printf("Input file: %s\n", input_file);
        printf("Output file: %s\n", output_file);
        printf("Coefficients: %f, %f, %f\n", coeffs[0], coeffs[1], coeffs[2]);
    }

    printf("Thank you for using gogrey!\n\n");
    return 0;
}
