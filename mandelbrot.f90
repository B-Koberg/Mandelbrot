program pi_calc
    use mpi_f08
    implicit none

    integer :: rank, size
    integer :: nx = 600, ny = 600
    integer :: x(600), y(600)


    call MPI_Init()

    call MPI_Comm_rank(MPI_COMM_WORLD, rank)
    call MPI_Comm_size(MPI_COMM_WORLD, size)

  
    call MPI_Finalize()

contains


end program pi_calc