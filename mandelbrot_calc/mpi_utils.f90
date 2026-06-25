module mpi_utils
    use mpi_f08
    use parameters
    implicit none
    private
    public :: split_arrays, gather_2d, split_arrays_weighted, gather_2d_weighted
contains
    subroutine split_arrays(rank, size, y_pix, y_pix_local, local_ny)
        integer, intent(in) :: rank, size
        integer, intent(in) :: y_pix(ny)
        integer, intent(out), allocatable :: y_pix_local(:)
        integer, intent(out) :: local_ny

        integer :: starty, endy
        integer :: block

        block = ny / size
        starty = rank*block + 1
        endy   = (rank+1)*block
        if (rank == size-1) endy = ny

        if (starty > endy) then
            stop "Error: More processes than work items"
        else
            local_ny = endy - starty + 1
        end if

        allocate(y_pix_local(local_ny))
        y_pix_local = y_pix(starty:endy)
    end subroutine split_arrays

    subroutine split_arrays_weighted(rank, sizee, y_pix, y_pix_local, local_ny)
        integer, intent(in) :: rank, sizee !size needs to be different from function size() 
        integer, intent(in) :: y_pix(:)
        integer, intent(out), allocatable :: y_pix_local(:)
        integer, intent(out) :: local_ny

        integer :: total_weight, i, start_idx, end_idx
        real :: sum_weights, cumulative_weight
        real, allocatable :: weights(:)
        real :: weight_sum
        integer :: ny
        ny = size(y_pix)
        print *, ny, y_pix(1), y_pix(ny)
        
        allocate(weights(ny))
        
        ! Beispiel einer quadratischen Gewichtung, größere Werte an den Rändern
        do i = 1, ny
            weights(i) = (min(i-1, ny - i))**2 + 1.0
        end do
        
        weight_sum = sum(weights)
        
        ! Bestimme die Start- und Endindices anhand der gewichteten Verteilung
        sum_weights = 0.0
        start_idx = 1
        end_idx = ny
        
        ! Berechne die Anzahl der Pixel für den aktuellen Prozess
        local_ny = 0
        do i = 1, ny
            sum_weights = sum_weights + weights(i)
            if (sum_weights / weight_sum >= real(rank) / sizee) then
                start_idx = i + 1
                exit
            end if
        end do
        
        sum_weights = 0.0
        do i = 1, ny
            sum_weights = sum_weights + weights(i)
            if (sum_weights / weight_sum >= real(rank + 1) / sizee) then
                end_idx = i
                exit
            end if
        end do
        
        if (rank == 0) start_idx = 1
        if (rank == sizee - 1) end_idx = ny
        if (end_idx < start_idx) end_idx = start_idx
        
        local_ny = end_idx - start_idx + 1
        
        allocate(y_pix_local(local_ny))
        if (rank == sizee - 1) then
            y_pix_local = y_pix(start_idx:ny)
        else
            y_pix_local = y_pix(start_idx:end_idx)
        end if
    end subroutine split_arrays_weighted

    
    

    subroutine gather_2d(local_ny, rank, size, iter_array_local, iter_array, recvcounts, displs)
        integer, intent(in) :: local_ny, rank, size
        integer, intent(in) :: iter_array_local(nx, local_ny)
        integer, intent(out) :: iter_array(nx, ny)
        integer :: recvcounts(:), displs(:)

        integer :: p, tmp_start, tmp_end, block

        block = ny / size

        do p = 0, size-1
            tmp_start = p*block + 1
            tmp_end   = (p+1)*block
            if (p == size-1) tmp_end = ny

            recvcounts(p+1) = (tmp_end - tmp_start + 1) * nx
        end do

        displs(1) = 0
        do p = 2, size
            displs(p) = displs(p-1) + recvcounts(p-1)
        end do


        call MPI_Gatherv( &
            iter_array_local, nx*local_ny, MPI_INTEGER, &
            iter_array, recvcounts, displs, MPI_INTEGER, &
            0, MPI_COMM_WORLD)

        !MPI_Gatherv(
        !Was sende ich?,
        !Wie viele Elemente sende ich?,
        !Welcher Datentyp?,
        !Wohin wird gesammelt?,
        !Wie viel kommt von jedem Rank?,
        !Wo wird jedes Paket abgelegt?,
        !Welcher Datentyp wird empfangen?,
        !Wer sammelt?,
        !In welchem Communicator?
        !)
    end subroutine

    subroutine gather_2d_weighted(local_ny, rank, sizee, iter_array_local, iter_array, recvcounts, displs)
        integer, intent(in) :: local_ny, rank, sizee
        integer, intent(in) :: iter_array_local(nx, local_ny)
        integer, intent(out) :: iter_array(nx, ny)
        integer :: recvcounts(:), displs(:)

        integer :: p,i ,tmp_start, tmp_end
        real :: total_weight
        real :: sum_weights
        real, allocatable :: weights(:)
        integer :: ny

        ny = size(iter_array(1,:))
        allocate(weights(ny))

        ! Beispiel einer quadratischen Gewichtung, größere Werte an den Rändern
        do p = 1, ny
            weights(p) = (min(p-1, ny - p))**2 + 1.0
        end do

        total_weight = sum(weights)

        ! Berechne die Anzahl der Pixel für jeden Prozess basierend auf der Gewichtung
        sum_weights = 0.0
        do p = 0, sizee-1
            sum_weights = 0.0
            tmp_start = 1
            tmp_end = 0

            do i = 1, ny
                sum_weights = sum_weights + weights(i)
                if (sum_weights / total_weight >= real(p + 1) / sizee) then
                    tmp_end = i
                    exit
                end if
            end do

            if (p == sizee-1) tmp_end = ny

            recvcounts(p+1) = (tmp_end - tmp_start + 1) * nx

            if (p < sizee-1) then
                tmp_start = tmp_end + 1
            end if
        end do

        displs(1) = 0
        do p = 2, sizee
            displs(p) = displs(p-1) + recvcounts(p-1)
        end do

        call MPI_Gatherv( &
            iter_array_local, nx*local_ny, MPI_INTEGER, &
            iter_array, recvcounts, displs, MPI_INTEGER, &
            0, MPI_COMM_WORLD)
    end subroutine gather_2d_weighted

end module mpi_utils