.Silent.:

# Makefile: globales Logging in build.log (überschreibt bei jedem Lauf)
LOG ?= build.log

SHELL := /bin/bash
.ONESHELL:

FC = mpifort
FFLAGS =
SRCS = parameters.f90 mpi_utils.f90 mandelbrot.f90 main.f90
OBJS = $(SRCS:.f90=.o)
EXE = mandelbrot
PICT = mandelbrot_150.png

.PHONY: all build run py clean clean_all open

all:
	@rm -f "$(LOG)" 
    # Leite alles an tee weiter (append). Für Überschreiben: ersetze -a durch >
	exec > >(tee -a "$(LOG)") 2>&1
	echo "==== Build started: $$(date) ===="
	$(MAKE) build
	$(MAKE) run
	$(MAKE) clean
	$(MAKE) py
	$(MAKE) open
	echo "==== Build finished: $$(date) ===="

build: $(EXE)

$(EXE): $(OBJS)
	$(FC) $(OBJS) -o $(EXE)

%.o: %.f90
	$(FC) $(FFLAGS) -c $< -o $@

run: $(EXE)
	mpirun --oversubscribe -np $(or $(NP),4) ./$(EXE)

py:
	python3 $(or $(SCRIPT),plot.py) $(or $(ARGS),)

clean:
	rm -f $(OBJS) *.mod

clean_all:
	rm -f $(OBJS) $(EXE) *.mod *.txt *.bin

open:
	@if command -v xdg-open >/dev/null 2>&1; then \
	    for f in $(PICT); do \
	        xdg-open $$f; \
	    done; \
	elif command -v explorer.exe >/dev/null 2>&1; then \
	    for f in $(PICT); do \
	        explorer.exe $$f; \
	    done; \
	else \
	    echo "Weder xdg-open noch explorer.exe gefunden."; \
	fi
