!########################################################
!     Program  : PAMMPT
!     TYPE     : Main program
!     PURPOSE  : Solve the PAM using DMFT away from half-filling
! with modified itertive perturbation scheme (MPT)  
!     AUTHORS  : Adriano Amaricci
!########################################################
module COMMON
  USE BROYDEN
  USE COMMON_VARS
  implicit none
  !Put here vars in common with the BROYDN function
  real(8)                :: xmu0,n,n0
  complex(8),allocatable :: sigma(:),fg(:),fg0(:),gamma(:)
  complex(8),allocatable :: sigmap(:),fgp(:),fg0p(:)
  real(8),allocatable    :: wr(:)
end module COMMON

function funcv(x)
  USE COMMON
  USE DMFT_IPT
  implicit none
  real(8),dimension(:),intent(in)  ::  x
  real(8),dimension(size(x))       ::  funcv
  real(8)                          ::  zn0
  xmu0=x(1)
  fg0 = one/(cmplx(wr,eps) + xmu0 - ed0 - gamma -U*(n-0.5d0))
  n0=sum(fermi(wr,beta)*aimag(fg0))/sum(aimag(fg0))
  funcv(1)=n-n0
  write(*,"(3(f13.9))")n,n0,xmu0
end function funcv


program pammpt
  USE DMFT_IPT
  USE COMMON
  USE IOTOOLS
  implicit none
  integer                :: i,iloop
  real(8)                :: x(1)
  logical                :: check,converged
  complex(8)             :: zeta,alpha
  real(8)                :: np,gzero,gmu,ntot,shift
  complex(8),allocatable :: sold(:)

  call read_input("inputIPT.in")

  allocate(fg(1:L),sigma(1:L),fg0(1:L),gamma(1:L))
  allocate(fgp(1:L),fg0p(1:L),sigmap(1:L))
  allocate(sold(1:L))
  allocate(wr(1:L))
  ! wm  = pi/beta*real(2*arange(1,L)-1,8)
  ! tau = linspace(0.d0,beta,L+1,mesh=dtau)
  gmu=xmu  ; gzero=0.d0
  if((ed0-ep0) > 0.d0)gzero=0.5*(ep0+ed0+sqrt((ep0-ed0)**2 + 4*Vpd**2))
  if((ed0-ep0) < 0.d0)gzero=0.5*(ep0+ed0-sqrt((ep0-ed0)**2 + 4*Vpd**2))
  if((ed0-ep0) /=0.d0)xmu=gmu+gzero !true ED chemical potential
  write(*,*)'shift mu to (from) = ',xmu,'(',gmu,')'
  write(*,*)'shift is           = ',gzero

  wr = linspace(-wmax,wmax,L,mesh=fmesh)
  sigma=zero  ; xmu0=xmu ; D=2.d0*ts
  iloop=0 ; converged=.false. ; sold=sigma
  do while (.not.converged)
     iloop=iloop+1
     write(*,"(A,i5)")"DMFT-loop",iloop

     do i=1,L
        alpha     = cmplx(wr(i),eps)  +xmu -ed0 - sigma(i)
        sigmap(i) = Vpd**2/alpha
        zeta      = cmplx(wr(i),eps)  +xmu -ep0 - sigmap(i)
        fgp(i)    = gfbether(wr(i),zeta,D)
        fg(i)     = one/alpha + Vpd**2/alpha**2*fgp(i)
     enddo
     n  = sum(fermi(wr,beta)*aimag(fg))/sum(aimag(fg))
     np = 2.d0*sum(aimag(fgp(:))*fermi(wr(:),beta))/sum(aimag(fgp(:)))
     ntot = np+2.d0*n

     !Get the hybridization functions: \Gamma(w+xmu)
     gamma= cmplx(wr,eps) + xmu - ed0 - sigma - one/fg

     !Fix the xmu0 w/ condition n0=n
     x(1)=xmu
     call broydn(x,check)       !this changes n0,xmu0
     xmu0=x(1)

     sigma= solve_mpt_sopt(fg0,wr,n,n0,xmu0)
     sigma=weight*sigma + (1.d0-weight)*sold
     sold=sigma
     converged=check_convergence(sigma,eps_error,Nsuccess,Nloop)
     call splot("ndVSiloop.ipt",iloop,2.d0*n,append=TT)
     call splot("npVSiloop.ipt",iloop,np,append=TT)
     call splot("ntotVSiloop.ipt",iloop,ntot,append=TT)
  enddo
  call splot("nd.np.ntot.ipt",n,np,ntot,append=TT)
  call splot("DOS.ipt",wr,-aimag(fg)/pi,-aimag(fgp)/pi,append=printf)
  call splot("Sigma_realw.ipt",wr,sigma,append=printf)
  call splot("Sigmap_realw.ipt",wr,sigmap,append=printf)
  call splot("G_realw.ipt",wr,fg,append=printf)
  call splot("Gp_realw.ipt",wr,fgp,append=printf)


  !   Lk=(Nx+1)**2
  !   call pam_getenergy_spt(Lk)

  ! contains
  !   !+-------------------------------------------------------------------+
  !   !PROGRAM  : 
  !   !TYPE     : Subroutine
  !   !PURPOSE  : 
  !   !COMMENT  : 
  !   !+-------------------------------------------------------------------+
  !   subroutine pam_getenergy_spt(Lk)    
  !     integer   :: Lk,Lm
  !     real(8)   :: nd,np,docc,Etot,Ekin,Epot,Ehyb,Eepsi,Emu,nk(Lk),npk(Lk)
  !     real(8)   :: epsi,de
  !     complex(8),allocatable :: gf(:),sf(:),gff(:)
  !     complex(8),allocatable :: gp(:),sp(:),gpp(:)
  !     real(8),allocatable    :: gtau(:),gptau(:)
  !     complex(8) :: gamma,alpha

  !     Lm=int(L*beta/pi);if(beta<1)Lm=L;if(Lm<L)Lm=L
  !     Lm=2**14
  !     allocate(gf(Lm),sf(Lm),gtau(0:L),gff(L))
  !     allocate(gp(Lm),sp(Lm),gptau(0:L),gpp(L))

  !     call getGmats(wr,fg,gf,beta)
  !     call getGmats(wr,fgp,gp,beta)
  !     call getGmats(wr,sigma,sf,beta)
  !     call getGmats(wr,sigmap,sp,beta)
  !     call splot("Giw.ipt",(/(pi/beta*dble(2*i-1),i=1,Lm)/),gf)
  !     call splot("Gpiw.ipt",(/(pi/beta*dble(2*i-1),i=1,Lm)/),gp)

  !     call cfft_iw2tau(gf,gtau,beta)
  !     call cfft_iw2tau(gp,gptau,beta)
  !     call splot("Gtau.ipt",(/(dble(i)*beta/dble(L),i=0,L)/),gtau(0:L))
  !     call splot("Gptau.ipt",(/(dble(i)*beta/dble(L),i=0,L)/),gptau(0:L))

  !     nd=-2.d0*gtau(L)
  !     np=-2.d0*gptau(L)

  !     !Energy && k-dispersed quantities
  !     Ekin=0.d0
  !     de=2.d0*D/dble(Lk)
  !     do ik=1,Lk
  !        epsi=-D + de*dble(ik)
  !        do i=1,L
  !           w=pi/beta*dble(2*i-1)
  !           gamma=xi*w+xmu-ed0-sf(i)
  !           alpha=xi*w+xmu-ep0-epsi
  !           gff(i)=one/(gamma - vpd**2/alpha)
  !           gpp(i)=one/(alpha-sp(i))
  !        enddo
  !        call cfft_iw2tau(gff,gtau,beta)
  !        call cfft_iw2tau(gpp,gptau,beta)
  !        nk(ik)=-gtau(L)
  !        npk(ik)=-gptau(L)
  !        Ekin=Ekin + nk(ik)*epsi/dble(Lk)
  !     enddo

  !     Epot=dot_product(conjg(sf(:)),gf(:))
  !     Ehyb=4.d0*dot_product(conjg(sp(:)),gp(:))


  !     Ehyb=2.d0*Ehyb/beta
  !     Epot=2.d0*Epot/beta

  !     docc=0.5*nd  - 0.25d0
  !     if(u>=1.d-2)docc = Epot/U + 0.5*nd - 0.25d0

  !     Eepsi=ed0*(nd-1.d0) + ep0*(np-1.d0)
  !     Emu=-xmu*(ntot-2.d0)

  !     Etot=Ekin+Epot+Ehyb+Eepsi+Emu

  !     write(*,"(A,f13.9)")"docc   =",docc
  !     write(*,"(A,f13.9)")"nd     =",nd
  !     write(*,"(A,f13.9)")"np     =",np
  !     write(*,"(A,f13.9)")"ntot   =",np+nd
  !     write(*,"(A,f13.9)")"Etot   =",Etot
  !     write(*,"(A,f13.9)")"Ekin   =",Ekin
  !     write(*,"(A,f13.9)")"Epot   =",Epot
  !     write(*,"(A,f13.9)")"Ehyb   =",Ehyb
  !     write(*,"(A,f13.9)")"Eepsi  =",Eepsi
  !     write(*,"(A,f13.9)")"Emu    =",Emu

  !     call splot("nkVSepsik.ipt",(/(-D + de*dble(ik),ik=1,Lk )/),nk(1:Lk),npk(1:Lk))
  !     call splot("EtotVS"//trim(extension),xout,Ekin+Epot,append=TT)
  !     call splot("EkinVS"//trim(extension),xout,Ekin,append=TT)
  !     call splot("EpotVS"//trim(extension),xout,Epot,append=TT)
  !     call splot("EhybVS"//trim(extension),xout,Ehyb,append=TT)
  !     call splot("EmuVS"//trim(extension),xout,Emu,append=TT)
  !     call splot("EepsiVS"//trim(extension),xout,Eepsi,append=TT)
  !     call splot("doccVS"//trim(extension),xout,docc,append=TT)
  !     deallocate(gf,sf,gtau,gff)
  !     deallocate(gp,sp,gptau,gpp)
  !   end subroutine pam_getenergy_spt
  !   !*******************************************************************
  !   !*******************************************************************
  !   !*******************************************************************

end program pammpt






