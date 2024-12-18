all: gogrey.exe

gogrey.exe: gogrey.c calculation.c oldCalculation.c ppmConverter.c constants.h
	 gcc -o gogrey.exe gogrey.c greyScale.S greyScaleSIMD.S -O3 -g -Wall -Wextra
     
clean:
	 rm gogrey.exe