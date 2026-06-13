program pi_calc
    use mpi_f08
    implicit none

    integer :: rank, size
    integer :: n
    real, allocatable :: x(:), y(:)
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
        if (n == 0) n = 100000000
    end if

    call MPI_Bcast(n, 1, MPI_INTEGER, 0, MPI_COMM_WORLD)

    allocate(x(n), y(n))
    call random_seed()
    call random_number(x)
    call random_number(y)

    do i = 1, n
        if (r(x(i), y(i)) < 1.0) count = count + 1
    end do

    call MPI_Reduce(count, count_comp, 1, MPI_INTEGER, MPI_SUM, 0, MPI_COMM_WORLD)

    if (rank == 0) then
        pi = pi(count_comp, n, size)
        print *, "Estimated pi:", pi
        print *, "Error:", abs(pi - pi_real)
    end if

    call MPI_Finalize()

contains

    real function r(x, y)
        real, intent(in) :: x, y
        r = x**2 + y**2
    end function r

    real function pi(count , n, size)
        integer, intent(in) :: count, n, size
        pi = 4.0 * real(count) / real(n * size)
    end function pi

end program pi_calc