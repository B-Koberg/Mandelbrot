module parameters
    implicit none
    public :: nx, ny, max_iter, x_min, x_max, y_min, y_max

    !integer, parameter :: nx = 7680, ny = 4320
    integer, parameter :: nx = 4*7680, ny = 4*4320
    integer, parameter :: max_iter = 500
    real(8), parameter :: x_min = -2.0d0, x_max = 1.0d0
    real(8), parameter :: y_min = -1.5d0, y_max = 1.5d0

end module parameters