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

    integer, allocatable :: recvcounts(:), displs(:)
    integer :: p, tmp_start, tmp_end

    x_pix = [(i, i = 1, nx)]
    y_pix = [(j, j = 1, ny)]

    call MPI_Init()
    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

    call split_arrays(rank, size, y_pix, y_pix_local, local_ny)
    allocate(iter_array_local(nx, local_ny))

    call mandelbrot_set(x_pix, y_pix_local, local_ny, iter_array_local)

    allocate(recvcounts(size), displs(size))
    call gather_2d(local_ny, rank, size, iter_array_local, iter_array, recvcounts, displs)


    call MPI_Finalize()

    if (rank == 0) then
        call save_to_txtfile("mandelbrot_output.txt", x_pix, y_pix, iter_array)
    end if

contains

    subroutine save_to_txtfile(filename, x_pix, y_pix, iter_array)
        character(len=*), intent(in) :: filename
        integer, intent(in) :: x_pix(nx), y_pix(ny)
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

end program mandelbrot