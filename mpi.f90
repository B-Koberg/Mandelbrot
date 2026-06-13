program send_recv_test
    use mpi_f08
    implicit none

    integer :: rank, size
    integer :: n
    real, allocatable :: x(:), y(:), r(:)
    integer :: count = 0
    integer :: count_comp = 0
    integer :: count_temp = 0
    real :: pi
    real(8) :: pi_real = 3.1415926535897932384626433832795
    integer :: i

    call MPI_Init()

    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

    if (rank == 0) then
        print *, "Enter the number of random points per process (probably crashes at 1000000000) "
        read *, n
    end if

    do i = 1, size - 1
        call MPI_Bcast(n, 1, MPI_INTEGER, 0, MPI_COMM_WORLD)
    end do

    allocate(x(n), y(n), r(n))
    call random_seed()
    call random_number(x)
    call random_number(y)

    r = sqrt(x**2 + y**2)

    do i = 1, n
        if (r(i) < 1.0) then
            count = count + 1
        end if
    end do

    if (rank /= 0) then
        call MPI_Send(count, 1, MPI_INTEGER, 0, rank, MPI_COMM_WORLD)
    else
        print *, "Count from rank ", rank, ": ", count
        count_comp = count

        do i = 1, size - 1
            call MPI_Recv(count_temp, 1, MPI_INTEGER, i, i, MPI_COMM_WORLD, MPI_STATUS_IGNORE)
            print *, "Count from rank ", i, ": ", count_temp
            count_comp = count_comp + count_temp
        end do

        print *, "Total count: ", count_comp, " out of ", n * size

        ! V_kreisviertel / V_rechteck = 1/4 pi r**2 / 1 = count_comp / n * size,  r = 1
        pi = 4.0 * real(count_comp) / real(n * size)
        print *, "Estimated pi: ", pi, " (Error: abs", abs(pi - pi_real), "Error in %: ", abs(pi - pi_real) / pi_real * 100.0, "%)"
    end if

    call MPI_Finalize()
end program send_recv_test
