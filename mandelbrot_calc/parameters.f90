module parameters
    implicit none
    public :: nx, ny, max_iter, x_min, x_max, y_min, y_max

    integer, parameter :: ratio_x = 2, ratio_y = 2
    integer, parameter :: base_size = 1500
    integer, parameter :: nx = ratio_x * base_size, ny = ratio_y * base_size
    integer, parameter :: max_iter = 150
    real(8), parameter :: x_min = -2.0d0, x_max = 2.0d0
    real(8), parameter :: y_min = -(x_max - x_min) * (real(ny) / real(nx)) / 2.0d0, y_max = -y_min

end module parameters