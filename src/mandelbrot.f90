module mandelbrot
    use parameters
    implicit none
    private
    public :: mandelbrot_set

contains

    function pix_to_coord(pix, min_coord, max_coord, n_pix) result(coord)
        integer, intent(in) :: pix
        real(wp), intent(in) :: min_coord, max_coord
        integer, intent(in) :: n_pix
        real(wp) :: coord
    
        coord = min_coord + (max_coord - min_coord) * real(pix-1, wp) / real(n_pix-1, wp)
    end function pix_to_coord

    function iter_calc(x_pix, y_pix) result(iter)
        integer, intent(in) :: x_pix, y_pix
        
        real(wp) :: x, y
        real(wp) :: zx, zy, zx2, zy2
        integer :: iter 

        x = pix_to_coord(x_pix, x_min, x_max, nx)
        y = pix_to_coord(y_pix, y_min, y_max, ny)
    
        zx = 0.0_wp
        zy = 0.0_wp
        zx2 = 0.0_wp
        zy2 = 0.0_wp
        iter = 0
    
        do while (iter < max_iter .and. zx2 + zy2 <= 4.0_wp) !folge divergiert sobald |z|>2
            zx2 = zx * zx
            zy2 = zy * zy
            zy = 2.0_wp * zx * zy + y
            zx = zx2 - zy2 + x
            iter = iter + 1
        end do
    
    end function iter_calc

    subroutine mandelbrot_set(x_pix_array, y_pix_array, local_ny, iter_array, rank, sizee)

        use mpi_f08
        implicit none

        integer, intent(in) :: x_pix_array(:), y_pix_array(:)
        integer, intent(in) :: local_ny, rank, sizee
        integer, intent(out) :: iter_array(nx, local_ny)

        integer :: i, j
        integer :: progress
        integer :: next_print = 10
        integer :: time(8)

        integer ::middle 
        middle = int(sizee/2)


        do i = 1, size(y_pix_array)

            do j = 1, size(x_pix_array)
                iter_array(j,i) = iter_calc(x_pix_array(j), y_pix_array(i))
            end do

            if (rank == middle) then
                progress = int(100.0 * i / local_ny)
                if (progress >= next_print) then
                    call date_and_time(values=time)
                    write(*,'("[",I1.1,"](",I2.2,":",I2.2,":",I2.2,") Progress: ",I0,"%")') &
                        rank, time(5), time(6), time(7), progress

                    next_print = next_print + 10
                end if
            end if

        end do

    end subroutine mandelbrot_set

end module mandelbrot