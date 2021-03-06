! !Solve a self-consistent problem using different 
! !iteration mixing schemes.
! MODULE MIXING
!   USE CONSTANTS
!   USE MATRIX
!   implicit none
!   private

!   interface simple_mix
!      module procedure simple_mix_s,simple_mix_v
!   end interface simple_mix

!   public :: simple_mix
!   public :: broyden_mix
!   public :: broyden_mix_scalar
! contains

!   subroutine simple_mix_s(vout,vin,alpha)
!     real(8),intent(inout) :: vout
!     real(8),intent(in)    :: vin
!     real(8),intent(in)    :: alpha
!     real(8)               :: f,vout_(1),vin_(1)
!     vout_(1)=vout;vin_(1)=vin
!     call simple_mix_v(vout_,vin_,alpha)
!     vout=vout_(1)
!   end subroutine simple_mix_s

!   subroutine simple_mix_v(vout,vin,alpha)
!     real(8),intent(inout) :: vout(:)
!     real(8),intent(in)    :: vin(size(vout))
!     real(8),intent(in)    :: alpha
!     real(8)               :: f(size(vout))
!     F=vout-vin
!     vout=vin+alpha*F
!   end subroutine simple_mix_v


!   subroutine broyden_mix_scalar(vout,vin,alpha,M,w0)
!     real(8),intent(inout)                   :: vout
!     real(8),intent(in)                      :: vin
!     real(8),intent(in)                      :: alpha
!     real(8)                                 :: amix
!     integer,intent(in)                      :: M
!     real(8),optional                        :: w0
!     real(8),save                            :: w0_
!     real(8),dimension(1) :: vout_,vin_
!     integer  :: N
!     w0_=0.01d0;if(present(w0))w0_=w0
!     N=1
!     vout_(1)=vout;vin_(1)=vin
!     call broyden_mix(N,vout_,vin_,alpha,M,w0_)
!     vout=vout_(1)
!   end subroutine broyden_mix_scalar

!   subroutine broyden_mix(N,vout,vin,alpha,M,w0)
!     integer,intent(in)                      :: N
!     ! real(8),intent(inout)                   :: vout(N)
!     ! real(8),intent(in)                      :: vin(N)
!     real(8)                   :: vout(N)
!     real(8)                      :: vin(N)
!     real(8),intent(in)                      :: alpha
!     real(8)                                 :: amix
!     integer,intent(in)                      :: M
!     real(8),optional                        :: w0
!     real(8),save                            :: w0_
!     integer,save                            :: iter=1
!     integer                                 :: iter_used,ipos,inext
!     real(8),allocatable,dimension(:,:),save :: Df,Dv,Beta
!     real(8),allocatable,dimension(:),save   :: Curv,work
!     real(8)                                 :: norm,gamma,curvature
!     integer                                 :: i,j
!     !Save alpha mixing:
!     amix=alpha
!     !Get f=vout-vin
!     vout = vout-vin
!     !linear mixing if M=0 or first iteration
!     if(iter==1.OR.M==0)then
!        vout=vin+amix*vout
!        return
!     endif
!     !Get broyden mixing pointer
!     iter_used=min(iter-1,M)
!     ipos     = iter-1-((iter-2)/M)*M
!     inext    = iter-((iter-1)/M)*M
!     !allocate aux arrays and define the 
!     !DeltaF^(n) = F^(n+1)-F^(n)/|F^(n+1)-F^(n)| 
!     !DeltaV^(n) = V^(n+1)-V^(n)/|F^(n+1)-F^(n)| 
!     if(iter==1)then
!        w0_=0.01d0;if(present(w0))w0_=w0
!        if(allocated(Df))deallocate(Df)
!        if(allocated(Dv))deallocate(Dv)
!        if(allocated(beta))deallocate(beta)
!        if(allocated(curv))deallocate(curv)
!        if(allocated(work))deallocate(work)
!        allocate(Df(M,N),Dv(M,N),Beta(M,M),Curv(N),work(M))
!     else
!        Df(ipos,:) = Vout - Df(ipos,:)
!        Dv(ipos,:) = Vin  - Dv(ipos,:)
!        norm = 1.d0/sqrt(dot_product(Df(ipos,:),Df(ipos,:)))
!        Df(ipos,:)=Df(ipos,:)/norm
!        Dv(ipos,:)=Dv(ipos,:)/norm
!     endif
!     !Build 
!     !we are assuming w(i)=w(j)=1
!     !beta = [w(0)*w(0)*delta(i,j) + w(i)*w(j)*a(i,j)]^-1
!     do i=1,iter_used
!        do j=1+1,iter_used
!           beta(i,j) = dot_product(Df(i,:),Df(j,:))
!        enddo
!        beta(i,i) = 1.d0+w0_*w0_!ACTHUNG I SUSPECT AN ERROR HERE!!!
!     enddo
!     call matrix_inverse(beta)
!     !vector(2) = vold + amix*f - sum_i sum_j cm(j)*b(j,i)*w(j)*u(i)*w(i)
!     do i=1,iter_used
!        do j=i+1,iter_used
!           beta(j,i)=beta(i,j)
!        enddo
!        work(i) = dot_product(Df(i,:),vout)
!     enddo
!     curv = amix*vout
!     do i=1,iter_used
!        gamma=0.d0
!        do j=i+1,iter_used
!           gamma = gamma+beta(j,i)*work(j)
!        enddo
!        curv(:) = curv(:) - gamma*(Dv(i,:)+amix*Df(i,:))
!     enddo
!     Df(inext,:)=vout
!     Dv(inext,:)=vin
!     curvature=dot_product(vout,curv)
!     if(curvature>-1.d0)then
!        vout = vin + curv
!     else
!        vout = vin + amix*0.5d0*vout
!     endif
!   end subroutine broyden_mix

! END MODULE MIXING
