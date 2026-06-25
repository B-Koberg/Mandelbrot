program mandelbrot
    use mpi_f08
    use parameters
    use mandelbrot, only: mandelbrot_set
    use mpi_utils, only: split_arrays, gather_2d, split_arrays_weighted, gather_2d_weighted
    implicit none

    integer :: rank, size

    integer :: x_pix(nx), y_pix(ny), iter_array(nx, ny)
    integer, allocatable :: y_pix_local(:), iter_array_local(:,:)

    integer :: i, j

    integer :: local_ny

    integer, allocatable :: recvcounts(:), displs(:)
    integer :: p, tmp_start, tmp_end

    x_pix = [(i, i = 1, nx)]
    y_pix = [(j, j = 1, ny)]

    call MPI_Init()
    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

    if (rank == 0) call print_time(rank, "Starting Mandelbrot set calculation; Splitting arrays...")

    call split_arrays(rank, size, y_pix, y_pix_local, local_ny)
    print *, "Rank ", rank, " has ", local_ny, " rows. From", y_pix_local(1), "to", y_pix_local(local_ny)
    allocate(iter_array_local(nx, local_ny))

    if (rank == 0) call print_time(rank, "Begin calculation...")

    call mandelbrot_set(x_pix, y_pix_local, local_ny, iter_array_local, rank, size)

    if (rank == 0) call print_time(rank, "Combining results...")

    allocate(recvcounts(size), displs(size))
    call gather_2d(local_ny, rank, size, iter_array_local, iter_array, recvcounts, displs)

    call MPI_Finalize()

    
    if (rank == 0) then
        call print_time(rank, "Saving results...")
        call save_to_binary("mandelbrot_output.bin", iter_array)
    end if


contains

    subroutine save_to_txtfile(filename, iter_array)
        character(len=*), intent(in) :: filename
        integer, intent(in) :: iter_array(nx, ny)

        integer :: i, j

        open(unit=10, file=filename, status='replace')

        write(10,*) nx, ny, max_iter, x_min, x_max, y_min, y_max
        ! Jede Zeile der Datei entspricht einer y-Koordinate
        do j = 1, ny
            do i = 1, nx
                write(10,'(I8,1X)', advance='no') iter_array(i,j)
            end do
            write(10,*)
        end do

        close(10)
    end subroutine save_to_txtfile

    subroutine save_to_binary(filename, iter_array)
        character(len=*), intent(in) :: filename
        integer, intent(in) :: iter_array(nx, ny)
        integer :: unit

        open(newunit=unit, file=filename, access="stream", form="unformatted", status="replace")

        ! Header IMMER als REAL(8) schreiben
        !vielleicht hdf5 lite variablen mit namen, typsicher
        write(unit) real(nx,8), real(ny,8), real(max_iter,8), &
                    real(x_min,8), real(x_max,8), real(y_min,8), real(y_max,8)
        !!!!! use iso-fontran_env und und only real64, integer parameter:: wp = real64, auch für mpi_wp

        ! Array als INTEGER(4)
        write(unit) iter_array

        close(unit)
    end subroutine save_to_binary

    subroutine print_time(rank, message)
        integer, intent(in) :: rank
        character(len=*), intent(in) :: message
        integer :: time(8)

        call date_and_time(values=time)
        write(*,'("[",I1.1,"](",I2.2,":",I2.2,":",I2.2,") ",A)') &
            rank, time(5), time(6), time(7), message
    end subroutine print_time


end program mandelbrot