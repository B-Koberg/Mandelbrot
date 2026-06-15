FC = mpifort
FFLAGS = 
SRCS = parameters.f90 mpi_utils.f90 mandelbrot.f90 main.f90 
OBJS = $(SRCS:.f90=.o)
EXE = mandelbrot

.PHONY: all build run py clean

all: build run clean py open

build: $(EXE)

$(EXE): $(OBJS)
	$(FC) $(OBJS) -o $(EXE)

%.o: %.f90
	$(FC) $(FFLAGS) -c $< -o $@

run: $(EXE)
	mpirun --oversubscribe -np $(or $(NP),8) ./$(EXE)

py:
	python3 $(or $(SCRIPT),plot.py) $(or $(ARGS),)

clean:
	rm -f $(OBJS)  *.mod 

clean_all:
	rm -f $(OBJS) $(EXE) *.mod *.txt *.bin

open:
	feh -F mandelbrot_color.png
