
all:
	@echo Please use target win32 or unix...

win32: runperl.exe
unix: runperl

SRCS += runperl.cpp
SRCS += utils.cpp
SRCS += array.cpp

runperl.exe: $(SRCS)
	cl /ML /O2 /Fe$@ $^
	rm -f *.obj

runperl: $(SRCS)
	gcc -Wall -o $@ -O2 $^
	strip runperl

clean:
	rm -f *.o runperl
	rm -f *.obj runperl.exe

utils.cpp: utils.h porting.h
array.cpp: array.h utils.h
runperl.cpp:  utils.h array.h porting.h
