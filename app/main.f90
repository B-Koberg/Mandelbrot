program mandelbrot
    use mpi_f08
    use parameters
    use mandelbrot, only: mandelbrot_set
    use mpi_utils, only: split_arrays, gather_2d
    implicit none

    integer :: rank, size

    integer :: x_pix(nx), y_pix(ny), iter_array(nx, ny)
    integer, allocatable :: y_pix_local(:), iter_array_local(:,:)

    integer :: i, j

    integer :: local_ny


    x_pix = [(i, i = 1, nx)]
    y_pix = [(j, j = 1, ny)]

    call MPI_Init()
    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

    if (rank == 0) call print_time(rank, "Starting Mandelbrot set calculation; Splitting arrays...")

    call split_arrays(y_pix, y_pix_local, local_ny, rank, size)
    allocate(iter_array_local(nx, local_ny))

    if (rank == 0) call print_time(rank, "Begin calculation...")

    call mandelbrot_set(x_pix, y_pix_local, iter_array_local, local_ny, rank, size)

    if (rank == 0) call print_time(rank, "Combining results...")

    call gather_2d(iter_array, iter_array_local, local_ny, rank, size)

    call MPI_Finalize()

    
    if (rank == 0) then
        call print_time(rank, "Saving results...")
        call save_to_binary("output/mandelbrot_output.bin", iter_array)
    end if


contains
    subroutine save_to_binary(filename, iter_array)
        character(len=*), intent(in) :: filename
        integer, intent(in) :: iter_array(nx, ny)
        integer :: unit

        open(newunit=unit, file=filename, access="stream", form="unformatted", status="replace")

        !vielleicht hdf5 lite variablen mit namen, typsicher
        write(unit) real(nx,wp), real(ny,wp), real(max_iter,wp), &
                    real(x_min,wp), real(x_max,wp), real(y_min,wp), real(y_max,wp)

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