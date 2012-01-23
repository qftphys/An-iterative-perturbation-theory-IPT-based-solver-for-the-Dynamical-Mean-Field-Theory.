!########################################################
!     Program  : AHMIPT
!     TYPE     : Main program
!     PURPOSE  : Solve the Attractive Hubbard Model using IPT
!     AUTHORS  : Adriano Amaricci
!########################################################
program hmmpt_2dsquare_matsubara
  USE DMFT_IPT
  USE SQUARE_LATTICE
  USE IOTOOLS
  implicit none
  integer                         :: i,ik,esp,Lk
  logical                         :: converged
  complex(8)                      :: zeta,cdet
  real(8)                         :: n,delta,n0,delta0
  !
  complex(8),allocatable          :: fg(:,:),fg0(:,:),sigma(:,:),calG(:,:)
  real(8),allocatable             :: fgt(:,:),fg0t(:,:)
  complex(8),allocatable          :: det(:),sold(:,:)
  !
  real(8),allocatable             :: wm(:),tau(:),wt(:),epsik(:)

  call read_input("inputIPT.in")
  ! lm  = int(real(L,8)*beta/pi2)
  ! esp = nint(log(real(lm,8))/log(2.d0))
  ! lm  = 2**esp
  ! L=max(lm,L)
  ! write(*,"(A,I9,A)")"Using ",L," frequencies"

  allocate(wm(L),tau(0:L))
  wm     = pi/beta*real(2*arange(1,L)-1,8)
  tau(0:)= linspace(0.d0,beta,L+1,mesh=dtau)

  !build square lattice structure:
  Lk   = square_lattice_dimension(Nx)
  allocate(wt(Lk),epsik(Lk))
  wt   = square_lattice_structure(Lk,Nx)
  epsik= square_lattice_dispersion_array(Lk,ts)

  !allocate working arrays
  allocate(fg(2,L),fgt(2,0:L))
  allocate(fg0(2,L),fg0t(2,0:L))
  allocate(sigma(2,L),calG(2,L))
  allocate(det(L),Sold(2,L))


  n=0.5d0 ; delta=deltasc
  sigma(2,:)=-delta ; sigma(1,:)=zero
  sold=sigma
  iloop=0 ; converged=.false.
  do while (.not.converged)
     iloop=iloop+1
     write(*,"(A,i5)",advance="no")"DMFT-loop",iloop
     fg=zero
     do i=1,L
        zeta =  xi*wm(i) + xmu - sigma(1,i)
        do ik=1,Lk
           cdet = abs(zeta-epsik(ik))**2 + (sigma(2,i))**2
           fg(1,i)=fg(1,i) + wt(ik)*(conjg(zeta)-epsik(ik))/cdet
           fg(2,i)=fg(2,i) - wt(ik)*sigma(2,i)/cdet
        enddo
     enddo
     call fftgf_iw2tau(fg(1,:),fgt(1,0:L),beta)
     call fftgf_iw2tau(fg(2,:),fgt(2,0:L),beta,notail=.true.)
     n=-real(fgt(1,L),8) ; delta= -u*fgt(2,0)

     !calcola calG0^-1, calF0^-1 (WFs)
     det      =  abs(fg(1,:))**2 + fg(2,:)**2
     fg0(1,:) =  conjg(fg(1,:))/det + sigma(1,:) - u*(n-0.5d0)
     fg0(2,:) =  fg(2,:)/det       + sigma(2,:) +  delta
     det       =  abs(fg0(1,:))**2 + fg0(2,:)**2
     calG(1,:) =  conjg(fg0(1,:))/det
     calG(2,:) =  fg0(2,:)/det

     call fftgf_iw2tau(calG(1,:),fg0t(1,:),beta)
     call fftgf_iw2tau(calG(2,:),fg0t(2,:),beta,notail=.true.) !; fg0t(2,:)=-fg0t(2,:)
     n0=-real(fg0t(1,L)) ; delta0= -u*fg0t(2,0)

     write(*,"(4(f16.12))",advance="no")n,n0,delta,delta0

     sigma     =  solve_mpt_sc_matsubara(calG,n,n0,delta,delta0)
     sigma     =  weigth*sigma + (1.d0-weigth)*sold;sold=sigma
     converged = check_convergence(sigma(1,:)+sigma(2,:),eps=eps_error,N1=Nsuccess,N2=nloop)
     call splot("nVSiloop.ipt",iloop,n,append=TT)
     call splot("deltaVSiloop.ipt",iloop,delta,append=TT)
  enddo
  call close_file("nVSiloop.ipt")
  call close_file("deltaVSiloop.ipt")
  call splot("Sigma_iw.ipt",wm,sigma(1,:),append=printf)
  call splot("Self_iw.ipt",wm,sigma(2,:),append=printf)
  call splot("G_iw.ipt",wm,fg(1,:),append=printf)
  call splot("F_iw.ipt",wm,fg(2,:),append=printf)
  call splot("calG_iw.ipt",wm,calG(1,:),append=printf)
  call splot("calF_iw.ipt",wm,calG(2,:),append=printf)
  call splot("n.delta.ipt",n,delta,append=printf)

end program hmmpt_2dsquare_matsubara
