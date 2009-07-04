c  KOREL08 -- Code for spectra disentangling and line-photometry of binary
c stars, (c) P. Hadrava  12. 12. 2008 version P for pulsations
c Version for LINUX (f77); requires to include files 'korelpar.f'
c (labels used up to 30)
c$LARGE: sp,fsp,fsv
CMS      INCLUDE 'FGRAPH.FI'
      implicit real*8 (a-h,o-z)
CMS      INCLUDE 'FGRAPH.FD'
      include 'korelpar.f'
      dimension x0(10),x(10),dx(10),pp(110),cont(nsp),erv(5)
      complex*16 c0,c1,c2
      character*1 cnp,csp,cvp,cwp,cer,cpp,cop
      logical*1 lnp,lsp,lvp,lwp,ler,lpp,lop
      equivalence (inp,lnp),(cnp,lnp),(isp,lsp),(csp,lsp),(ivp,lvp)
     /,(cvp,lvp),(iwp,lwp),(cwp,lwp),(ier,ler),(cer,ler),(cop,lop)
     /,(iop,lop)
      common f(npx2),si(npx2,5),fout(npx,5)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/er/er(3,4,15)
      common/param/param(5,7),kodp(5)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      common/sum/lsum
      common/kpr/kpr
      common/eqwi/ew(5),eww(5),ews(5,5)
      common/tmpl/tmplp(mtmp,4),tmpl(mtmp,npx2),ntmp
      DATA PI/3.14159265358979D0/spsep/.12d0/ifer/0/
      data csp/'s'/cvp/'v'/cwp/'w'/cer/'e'/cpp/'p'/cop/'o'/
      write(*,500)nsp,npx
c      ndf=npx2
c      ndf1=ndf-1
c      ndf2=ndf/2
c Input of parameters:
c   ks=Nr. of input spectra,
c   ns=Nr. of components,
c   me=Nr. of elements to be converged
c   nu=Nr. of spectral regions (pocet useku)
c   kr=Code of graphics output
c   ifil=Nr. of filtered Fourier modes
c   kpr=Key of output prints (+10*Nr. of component for O-C)
CMS      open(1,file='korel.par',status='old')
      open(1,file='korel.par')
      open(2,file='korel.res')
      write(2,500)nsp,npx
      open(9,file='korel.tmp')
c      open(10,file='korel.aux')
c   Main control keys:
   99 read(1,*,end=105)(key(j),j=1,5),k0,ifil,kr,kpr
      write(2,*)(key(j),j=1,5),k0,ifil,kr,kpr
c Input of data:
      if(k0.ne.0)ks=min0(nsp,iabs(k0))
      if(k0.gt.0) call vstup
      ndf1=ndf-1
      ndf2=ndf/2
      kdif=kpr/10
      kpr=kpr-10*kdif
      if(kdif.gt.0)open(4,file='korel.o-c')
      lsum=0
      ns=0
c      write(*,*)' chpt 1',s(5,2)
c  loop over component stars:
      do 10 j=1,5
      if(key(j).le.0) goto 10
c   component spectrum is present
      ns=ns+1
      kodpn=key(j)/100
c      kodp(ns)=kodpn
      key(j)=key(j)-100*kodpn
      key(10+j)=ns
      ivj(j)=1
      if(key(j).gt.10)then
c      component velocity is free
       ivj(j)=0
       key(j)=key(j)-10
      endif
      key(5+ns)=j
   10 continue
c      write(2,*)' kodp:',kodp
c      write(10,*)ivj
c      write(10,*)key
      me=0
      niter=0
      inp=0
c Input of elements:
   13 READ(1,*)cnp,J1,J2,K1,LE,LD,E0,D0
      write(2,510)cnp,j1,j2,k1,le,ld,e0,d0
      niter=max0(niter,k1)
c      IF(J.GT.150) CALL HELP(1)
c      IF(J.GT.150) WRITE(*,505)
c      IF(J.GT.100) GOTO 21
      if(inp.eq.isp)goto 21
      if(inp.eq.ivp)goto 23
      if(inp.eq.iwp)goto 24
      if(inp.eq.ier)goto 30
      if(j1.eq.0.and.j2.eq.0) goto 14
      if(inp.ne.iop.or.j1.gt.3.or.j2.gt.11) goto 13
c      j=10*j1+j2
c      j1=j/10
c      j2=j-10*j1
      j1=j1+1
      if(le.gt.0) el(j1,j2)=e0
      if(ld.gt.0) del(j1,j2)=d0
      if(j2.eq.4.and.le.gt.0)el(j1,j2)=e0*PI/180.d0
      if(j2.eq.4.and.ld.gt.0)del(j1,j2)=d0*PI/180.d0
      if(j2.eq.7.and.le.gt.0)el(j1,j2)=e0*PI/180.d0
      if(j2.eq.7.and.ld.gt.0)del(j1,j2)=d0*PI/180.d0
      IF(K1.LE.0.or.me.ge.10) GOTO 13
      me=me+1
      ix(1,me)=1
      ix(2,me)=j1
      ix(3,me)=j2
      GOTO 13
   21 continue
c      if(j.ge.1000)goto 23
c      if(j.ge.600)goto 13
c      strengths for individual exposures
c      j1=j/1000
c      j2=j-1000*j1
c      j=1000*j1+j2
      if(j2.le.0.or.j2.gt.nsp)goto 13
      IF(LE.GT.0) s(j1,j2)=E0
      IF(LD.GT.0) ds(j1,j2)=D0
c      write(*,*)j1,j2,s(j1,j2)
      IF(K1.LE.0.or.me.ge.10) GOTO 13
      me=me+1
      ix(1,me)=2
      ix(2,me)=j1
      ix(3,me)=j2
      goto 13
   23 continue
      if(j.ge.6000)goto 13
c      RVs for individual exposures
c      j1=j/1000
c      j2=j-1000*j1
c      j=1000*j1+j2
      if(j2.le.0.or.j2.gt.nsp)goto 13
      rvpb=us(2,iu(j2))
      IF(LE.GT.0) vr(key(10+j1),j2)=E0/rvpb
      IF(LD.GT.0) dvr(key(10+j1),j2)=D0/rvpb
c      write(*,*)j1,j2,vr(key(10+j1),j2),dvr(key(10+j1),j2)
      IF(K1.LE.0.or.me.ge.10) GOTO 13
      me=me+1
c      ix(me)=J
      ix(1,me)=3
      ix(2,me)=j1
      ix(3,me)=j2
      goto 13
   24 continue
      if(j2.le.0.or.j2.gt.nsp)goto 13
      w(j2)=E0
      goto 13
   30 if(k1.gt.0)ifer=1
      if(j1.lt.0.or.j1.ge.4.or.j2.le.0.or.j2.gt.15) goto 13
      j1=j1+1
      er(2,j1,j2)=e0
      er(3,j1,j2)=d0
      if(j2.eq.4)er(2,j1,j2)=e0*PI/180.d0
      if(j2.eq.4)er(3,j1,j2)=d0*PI/180.d0
      if(j2.eq.7)er(2,j1,j2)=e0*PI/180.d0
      if(j2.eq.7)er(3,j1,j2)=d0*PI/180.d0
      goto 13
   14 continue
c      write(*,*)' chpt 2',s(5,2)
c      write(10,*)((i,j,vr(i,j)*rvpb,j=1,ks),i=1,ns)
      call SETP(x,dx)
c      write(*,*)' chpt 3',s(5,2)
c simulation of input composed spectra:
      if(k0.lt.0) call simul(si,ndf)
c input of real data:
c      if(k0.gt.0) call vstup
c      write(*,*)' chpt 4',s(5,2)
      nsu=ns*nu
      write(*,501)ks,ns,nu,me,ifil,kr,kpr
CMS      write(*,502)
      write(2,501)ks,ns,nu,me,ifil,kr,kpr
      write(2,*)' mean int.:',ew
      write(2,*)' cont. shifts:',(1.d0-ew(l),l=1,5)
c      write(*,*)iu
c      write(*,*)(t(l),l=1,ks)
CMS      read(*,*)
c Graphics:
      call phgini(kr)
      call phglim(.0d0,.0d0,dfloat(ndf),2.d0)
      call phglin(.0d0,.0d0,dfloat(ndf),0.d0,15)
      call phglin(dfloat(ndf),0.d0,dfloat(ndf),2.d0,15)
      call phglin(dfloat(ndf),2.d0,0.d0,2.d0,15)
      call phglin(0.d0,2.d0,0.d0,0.d0,15)
      p2=.05d0*dfloat(ndf)
      call phglin(p2,0.9d0,p2,1.0d0,4)
      p1=200.d0/us(2,1)
      call phglin(p2,0.9d0,p2+p1,0.9d0,4)
c      call show(si,npx2,ndf,1,0.d0,1.d0,3)
c      call show(si,npx2,ndf,2,0.d0,1.d0,3)
      do 12 j=1,ns
      ys=0.
      do 11 i=1,ndf1,2
   11 ys=ys+si(i,j)
      ys=ys/dfloat(ndf2)
      if(k0.lt.0)
     /call show(si,npx2,ndf,j,.9d0-spsep*dfloat(j)-ys,1.d0,4)
   12 continue
      pos=1.d0/dfloat(ks+1)
      wtot=0.d0
      do 4 l=1,ks
      wtot=wtot+w(l)
c  plot of input composed spektra:
      ys=0.
      if(kr.eq.2)write(3,*)' s'
      if(kr.eq.2)write(3,*)' 0. 0. 1. sc'
      do 1 i=1,ndf1,2
    1 ys=ys+sp(i,l)
      ys=ys/dfloat(ndf2)
      cont(l)=ys
      call show(sp,npx2,ndf,l,1.d0-ys+pos*dfloat(ks-l),1.d0,2)
c  FFT on input composed spectra:
      do 2 i=1,ndf1,2
      f(i+1)=0.
      f(i)=sp(i,l)-ys
    2 continue
      call four1(f,ndf2,1)
c   plot of the transform:
      do 3 i=1,ndf1,2
      fsp(i,l)=f(i)
      fsp(i+1,l)=f(i+1)
c      f(i)=dsqrt((f(i)**2+f(i+1)**2)/dfloat(ndf2))
    3 continue
c      call show(f,npx2,ndf,1,.1*dfloat(l),1.d0,1)
    4 continue
c component solution by correlations:
c      write(*,*)skor(ndf)
c convergence of orbital parameters:
c      write(10,*)((i,j,vr(1,j)*rvpb,j=1,ks),i=1,ns)
c      write(*,*)' chpt 5',s(5,2)
      if(me.gt.0) then
       do 22 iter=1,niter
c       write(2,*)'achil',iter
        CALL ACHIL(me+1,X,DX,PP,10*me,DS0)
c       p1=skor(ndf)
        p1=suma(x)
        p2=scoef(ndf)
        p3=dsqrt(2.d0*p1/(wtot*dfloat(ndf)))
        write(2,*)'achil',iter,p1,p2,p3
   22  continue
c       write(*,*)'SETE'
c       write(2,*)'chpt 3c',el(2),del(2)
       call SETE(x,dx)
c       write(2,*)'chpt 3d',el(2),del(2)
      endif
c      call chyba(x,dx,me)
      write(2,*)' if er=',ifer
      if(ifer.gt.0) then
       call maper
       ifer=0
      endif
      do 5 i=1,4
      j1=i-1
      j=10*j1
      if(el(i,1).ne.0.)write(2,508)j1,el(i,1),del(i,1),j1,j1,
     /el(i,2),del(i,2),j1,el(i,3),del(i,3),j1,el(i,4)*180.d0/pi,
     /del(i,4)*180.d0/pi,j1,el(i,5),del(i,5),j1,el(i,6),del(i,6),
     /el(i,5)/el(i,6),j1,el(i,7)*180.d0/pi,del(i,7)*180.d0/pi,j1,
     /el(i,8),del(i,8),j1,el(i,9),del(i,9),j1,el(i,10),del(i,10),
     /j1,el(i,11),del(i,11)
    5 continue
c      write(10,*)(vr(j,1),j=1,5)
      call rv
c      write(10,*)(vr(j,1),j=1,5)
      p1=skor(ndf)
c      write(*,*)' main 1:'
      p2=scoef(ndf)
      do 16 j=1,ns
      kj=key(5+j)
c      write(*,*)' main 1a:'
      do 16 l=1,ks
      if(s(kj,l).ne.0.)write(2,503)kj,l,s(kj,l),ds(kj,l)
   16 continue
c      write(*,*)' main 2:'
      do 28 j=1,ns
      kj=key(5+j)
      if(key(kj).eq.0.or.ivj(kj).gt.0)goto 28
c        write(2,*)' free RV',j
      do 27 l=1,ks
      rvpb=us(2,iu(l))
      write(2,509)kj,l,vr(j,l)*rvpb,rvpb
   27 continue
   28 continue
c      write(*,*)' main 3:'
      p3=dsqrt(2.d0*p1/(wtot*dfloat(ndf)))
      write(*,*)p1,p2,p3
      write(2,*)p1,p2,p3
c      write(*,*)' chpt 8',s(5,2)
      do 9 iul=1,nu
c  mean level of continuum
      pn1=0.d0
      ys=0.d0
      do 20 l=1,ks
      if(iu(l).ne.iul)goto 20
      ys=ys+cont(l)
      pn1=pn1+1.0d0
   20 continue
      if(pn1.gt.0.) ys=ys/pn1
      q=1.d0+us(2,iul)/2.997924562d5
      p1=us(1,iul)
      p2=p1*q**(ndf2-1)
      write(2,506)pn1,iul,p1,p2,1.d0-ys
c plot of decomposed spectra:
      if(kr.eq.2)write(3,*)' s'
      if(kr.eq.2)write(3,*)' 0. 0. 0. sc'
      call stup(p1,p2,dp1,dp2,p01,p02)
      p0=.9d0-spsep*dfloat(1+ns*iul-ns)
      call phglin(.0d0,p0,dfloat(ndf),p0,15)
      n1=(p2-p02)/dp2+1.d0
      do 29 i=1,n1
      p0i=dfloat(ndf)*dlog((p02+dp2*dfloat(i-1))/p1)/dlog(p2/p1)
      dsp=p0-spsep/4.d0
      j=(p02+dp2*dfloat(i-1)-p01)/dp1+.5
      if(dabs(p02+dp2*dfloat(i-1)-p01-j*dp1).lt.0.1d0*dp2)
     / dsp=p0-spsep/2.d0
      call phglin(p0i,p0,p0i,dsp,15)
   29 continue
      p1=p1/q
      if(kr.eq.2)write(3,*)' s'
      if(kr.eq.2)write(3,*)' 0. .7 .3 sc'
      do 8 j=1,ns
      erv(j)=0.d0
      jul=j+ns*iul-ns
      do 6 i=1,ndf
    6 f(i)=fsv(i,jul)
c      write(10,*)' f(1)=',f(1)
      call four1(f,ndf2,-1)
      call show(f,npx2,ndf,1,.9d0-spsep*dfloat(jul),1.d0/dfloat(ndf2),3)
      do 7 i=1,ndf2
      fout(i,j)=f(2*i-1)/dfloat(ndf2)
    7 f(2*i-1)=f(2*i)
c imag. part: call show(f,npx2,ndf,1,.9d0-spsep*dfloat(j),1.d0/dfloat(ndf2),5)
    8 continue
      do 9 i=1,ndf2
      p1=p1*q
      write(2,51)p1,(1.d0+fout(i,j),j=1,ns)
c      write(10,*)1.d0+fout(i,ns)
    9 continue
c plot of synthetized input spectra:
c      write(*,*)' chpt 9',s(5,2)
c      if(kdif.gt.0)rewind(3)
      if(kr.eq.2)write(3,*)' s'
      if(kr.eq.2)write(3,*)' 0. 1. 0. sc'
      do 15 l=1,ks
      call synt(f,l)
      call four1(f,ndf2,-1)
      call show(f,npx2,ndf,1,1.+pos*dfloat(ks-l),1.d0/dfloat(ndf2),3)
c output of O-C:
      if(kdif.gt.0)then
       write(4,54)t(l),us(1,iu(l)),us(2,iu(l)),w(l),ndf2
       do 25 j=1,ndf,2
       f(j)=sp(j,l)-cont(l)-f(j)/dfloat(ndf2)
       f(j+1)=0.
   25  continue
       if(kdif.lt.6)then
        call four1(f,ndf2,1)
        theta=-12.56637061435917292d0/dfloat(ndf)
        thlj=theta*idint(dabs(vr(kdif,l))+.5d0)
c        write(2,*)idint(dabs(vr(kdif,l))+.5d0)
        if(vr(kdif,l).lt.0.)thlj=-thlj
        c0=cmplx(1.d0/dfloat(ndf2),0.d0)
        c1=cmplx(dcos(thlj),dsin(thlj))
        do 26 j=1,ndf,2
        c2=c0*cmplx(f(j),f(j+1))
        f(j)=dreal(c2)
        f(j+1)=dimag(c2)
        c0=c0*c1
   26   continue
        call four1(f,ndf2,-1)
       endif
       write(4,52)(f(j),j=1,ndf,2)
      endif
   15 continue
c individual RV's
      write(2,504)(key(5+j),j=1,ns)
c      write(*,*)' chpt 10',s(5,2)
      if(kr.eq.2)write(3,*)' s'
      if(kr.eq.2)write(3,*)' 1. 0. 0. sc'
      wtot=0.0d0
      do 17 lsum=1,ks
c      write(10,*)(vr(j,lsum),j=1,5)
      rvpb=us(2,iu(lsum))
      wtot=wtot+w(lsum)
      do 18 j=1,ns
      x(j)=vr(j,lsum)
      x0(j)=x(j)
   18 dx(j)=rvpb
      write(*,*)lsum
      CALL ACHIL(ns+1,X,DX,PP,10*ns,DS0)
      write(2,505)lsum,t(lsum),(x(j)*rvpb,(x(j)-x0(j))*rvpb,j=1,ns)
      do 19 j=1,ns
c      j2=key(10+j)
      erv(j)=erv(j)+w(lsum)*((x(j)-x0(j))*rvpb)**2
   19 vr(j,lsum)=x(j)
      call synt(f,lsum)
      call four1(f,ndf2,-1)
      call show(f,npx2,ndf,1,1.+pos*dfloat(ks-lsum),1.d0/dfloat(ndf2),4)
   17 continue
      write(2,507)(dsqrt(erv(j)/wtot),j=1,ns)
c      write(2,507)(dsqrt(erv(j)/dfloat(ks)),j=1,ns)
c      write(*,*)' chpt 11',s(5,2)
      call phgend
      goto 99
  105 stop
   51 format(f10.4,5f8.5)
   52 format(10f8.5)
   54 format(f12.4,f10.4,2f7.3,i8)
  500 format(' KOREL08 - release 12. 12. 08, (c) P. Hadrava'/
     / ' Compiled for maximum of ',i4,' spectra,',i5,' bins each')
  501 format(' End of input:' ,i3,' spectra of ',i1,' stars in ',i1
     /,' regions. ',i2,' elements to be converged.'/
     /' filtered ',i4,' harmonics, plot mode=',i2,', print mode=',i2)
  502 FORMAT(' Press Enter to continue!')
  503 FORMAT('s',i2,i4,' 0 1 1 ',2f8.5)
  504 FORMAT('  N       t     ',5('   VR(',i1,')     O-C  '))
  505 FORMAT(i4,1x,f10.4,10F9.3)
  506 FORMAT(f4.0,' spectra in',i2,
     /'th region (',f9.3,',',f9.3,') with total continuum shift',f7.4)
  507 FORMAT(/' rms of 1 obs.:',9x,5(F9.3,9x))
  508 FORMAT(/'o',i2,'  1 0 1 1',F16.9,F10.3,' = PERIOD(',i1,')'/
     /'o',i2,'  2 0 1 1',F16.9,F10.3,' = PERIASTRON EPOCH'/
     /'o',i2,'  3 0 1 1',F16.9,F10.3,' = ECCENTRICITY'/
     /'o',i2,'  4 0 1 1',F16.9,F10.3,' = PERIASTRON LONG.'/
     /'o',i2,'  5 0 1 1',F16.9,F10.3,' = K1'/
     /'o',i2,'  6 0 1 1',F16.9,F10.3,' = q = M2/M1,  K2 =',F16.9/
     /'o',i2,'  7 0 1 1',F16.9,F10.3,' = d omega/dt'/
     /'o',i2,'  8 0 1 1',F16.9,F10.3,' = d P/dt'/
     /'o',i2,'  9 0 1 1',F16.9,F10.3,' = d e/dt'/
     /'o',i2,' 10 0 1 1',F16.9,F10.3,' = d K1/dt'/
     /'o',i2,' 11 0 1 1',F16.9,F10.3,' = d q/dt')
  509 FORMAT('v',i2,i4,' 0 1 1 ',2f9.3)
  510 FORMAT(1x,a1,5i4,2e12.5)
      end

      BLOCK DATA
      IMPLICIT REAL*8(A-H,O-Z)
      include 'korelpar.f'
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/er/er(3,4,15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      DATA EL/1.D0,3*0.0D0,2.D1,.5D0,54*0.d0/
      DATA DEL/3*.1D0,3*.5D0,54*.1d0/
      data s/nsp*0.d0,nsp*0.d0,nsp*0.d0,nsp*0.d0,nsp*0.d0/
     /ds/nsp*0.1d0,nsp*0.1d0,nsp*0.1d0,nsp*0.1d0,nsp*0.1d0/
      data er/180*.0d0/
      END

      subroutine synt(f,l)
      implicit real*8 (a-h,o-z)
      include 'korelpar.f'
      dimension f(npx2)
      complex*16 c(5),c1(5),p,delta
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/param/param(5,7),kodp(5)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      iul=iu(l)
      nsu=ns*nu
      m=ndf
      m1=m-1
      m21=m/2+1
      theta=12.56637061435917292d0/dfloat(m)
c      theta=-12.56637061435917292d0/dfloat(m)
c      do 1 j=1,ns
c      thlj=theta*idint(dabs(vr(j,l))+.5d0)
c      if(vr(j,l).gt.0.)thlj=-thlj
c      c1(j)=cmplx(dcos(thlj),dsin(thlj))
c      p0=dexp(s(key(j+5),l))
c    1 c(j)=cmplx(p0)
      do 10 i=1,m21,2
      yi=theta*dfloat((i-1)/2)
      p=cmplx(0.)
      do 2 j=1,ns
      jul=j+ns*(iul-1)
c      p=p+c(j)*cmplx(fsv(i,jul),fsv(i+1,jul))
      p=p+dexp(s(key(j+5),l))*cmplx(fsv(i,jul),fsv(i+1,jul))*
     /       delta(yi,j,l,kodp(j))
    2 continue
      f(i)=dreal(p)
      f(i+1)=dimag(p)
      if(i.gt.1.and.i.lt.m21)then
       f(m-i+2)=f(i)
       f(m-i+3)=-f(i+1)
      endif
c      do 10 j=1,ns
c      c(j)=c(j)*c1(j)
   10 continue
      return
      end

      subroutine vstup
      implicit real*8 (a-h,o-z)
      include 'korelpar.f'
      common f(npx2)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      common/eqwi/ew(5),eww(5),ews(5,5)
      common/tmpl/tmplp(mtmp,4),tmpl(mtmp,npx2),ntmp
      open(3,file='korel.dat',status='old')
      ndf2=0
      do 4 i=1,5
      ew(i)=0.d0
      eww(i)=0.d0
      do 4 j=1,5
    4 ews(i,j)=0.d0
      l=0
      nu=0
    1 l=l+1
      read(3,*,end=99)pt,p1,dp,pw,ndf0
      if(l.eq.1) then
       ndf2=ndf0
       ndf=2*ndf2
       ndf1=ndf-1
       write(*,*)' Length of spectrum=',ndf2
      endif
      if(ndf0.ne.ndf2)write(*,*)' Warning: wrong length (',ndf0,
     /') of spectrum',l
      if(l.gt.nsp)write(*,*)' Warning: more then',nsp,' spectra!'
      if(l.gt.nsp)goto 99
      t(l)=pt
      w(l)=pw
      if(nu.eq.0)then
       nu=1
       us(1,nu)=p1
       us(2,nu)=dp
       iu(l)=nu
       goto 3
      endif
      num=min0(nu,mnu)
      do 2 j=1,num
      if(p1.eq.us(1,j).and.dp.eq.us(2,j)) then
       iu(l)=j
       goto 3
      endif
    2 continue
      nu=nu+1
      iu(l)=nu
      if(nu*ns.gt.15.or.nu.gt.5)then
       read(3,*)(sp(i,l),i=1,ndf1,2)
       l=l-1
       goto 1
      else
       us(1,nu)=p1
       us(2,nu)=dp
      endif
    3 continue
      read(3,*)(sp(i,l),i=1,ndf1,2)
      sum=0.0d0
      do 5 i=2,ndf,2
      sp(i,l)=0.d0
      sum=sum+sp(i-1,l)
    5 continue
      j=iu(l)
      if(j.le.5)then
       ew(j)=ew(j)+sum*pw
       eww(j)=eww(j)+pw
      endif
c      write(2,*)l,j,sum
      go to 1
   99 continue
      ks=min0(l-1,nsp)
      if(nu.gt.mnu)
     /write(*,*)' Warning: more then ',mnu,' spectral regions! =',nu
      if(nu*ns.gt.mnsu)
     /write(*,*)' Warning: more then ',mnsu,' component spectra! =',nu*ns
       num=min0(nu,mnu)
      do 6 j=1,num
       if(eww(j).ne.0.)ew(j)=ew(j)/eww(j)/dfloat(ndf/2)
    6 continue
c input of template spectra
      ntmp=0
      do 8 i=1,mtmp
      read(9,*,end=10)(tmplp(i,j),j=1,3)
c      write(10,*)' template:',(tmplp(i,j),j=1,3)
      if(tmplp(i,1)*tmplp(i,2)*tmplp(i,3).eq.0.d0)goto 9
      do 11 j=1,ndf1,2
      read(9,*,end=10)f(j)
c      write(*,*)j,f(j)
c      read(9,*,end=10)(f(j),j=1,ndf1,2)
   11 continue
      ntmp=ntmp+1
      tmplp(i,4)=0.
      do 12 j=1,nu
      if(dabs(us(1,j)-tmplp(i,1)).lt.1.d-8.and.
     /dabs(us(2,j)-tmplp(i,2)).lt.1.d-8)tmplp(i,4)=j
c      write(*,*)us(1,j),us(2,j)
c      if(tmplp(i,4).ne.0.d0)write(*,*)j,tmplp(i,1),tmplp(i,2)
   12 continue
c      write(*,*)tmplp(i,1),tmplp(i,2),tmplp(i,4)
      do 7 j=2,ndf,2
      f(j)=0.0d0
    7 continue
      call four1(f,ndf2,1)
      do 8 j=1,ndf
c      if(j.eq.4.or.j.eq.ndf2+2.or.j.eq.ndf)write(10,*)' i,j,tmpl=',
c     /i,j,f(j-1),f(j)
    8 tmpl(i,j)=f(j)
      goto 9
   10 write(*,*)' End of tmpl. sp., ntmp, j=',ntmp,j
    9 write(*,*)' Number of templates = ',ntmp
      write(2,*)' Number of templates = ',ntmp
      do 13 i=1,ntmp
      j=tmplp(i,3)
   13 write(2,*)i,(tmplp(i,j),j=1,2),j
      return
      end

      subroutine show(f,npx2,ndf,l,dy,cy,ib)
CMS$LARGE: f
      implicit real*8 (a-h,o-z)
      dimension f(npx2,l)
      ndf1=ndf-1
      x1=1.
      y1=f(1,l)*cy+dy
      y1=dmin1(2.d0,dmax1(0.d0,y1))
      do 1 i=3,ndf1,2
c      if(l.eq.16.and.i-1.eq.64*(i/64))write(*,*)i,f(i,l)
      x2=i
      y2=f(i,l)*cy+dy
      y2=dmin1(2.d0,dmax1(0.d0,y2))
      call phglin(x1,y1,x2,y2,ib)
      x1=x2
    1 y1=y2
      return
      end

      function skor(m)
      implicit real*8 (a-h,o-z)
      include 'korelpar.f'
      dimension ipiv(5),in(5),it(5)
      complex a(5,5),b(5),pp1
      complex*16 c(5,nsp),c1(5,nsp),p1,delta
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/param/param(5,7),kodp(5)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      common/tmpl/tmplp(mtmp,4),tmpl(mtmp,npx2),ntmp
      nsu=ns*nu
      m1=m-1
      m21=m/2+1
c      write(10,*)' skor, m21=',m21
      theta=-12.56637061435917292d0/dfloat(m)
      skor=0.d0
      do 10 iul=1,nu
      nst=0
      do 5 i=1,ns
      in(i)=0
      it(i)=0
      j0=1
      do 11 j=1,ntmp
      if(tmplp(j,3).eq.key(5+i).and.tmplp(j,4).eq.iul)then
       j0=0
       it(i)=j
      endif
   11 continue
      nst=nst+j0
    5 in(i)=nst*j0
c  pole in=index hvezdy v reseni rovnic (0=neresi se)
c       it=poradove cislo vzoru (0=zadny)
c      write(*,*)' skor 1:',ntmp,nst
c       write(*,*)' skor 1a:',in,it
c 0th-order Fourier mode: (continuum shift is set to the 1st comp.)
c       fsv(1,1+ns*iul-ns)=real(b(1))
c       fsv(2,1+ns*iul-ns)=aimag(b(1))
       pp1=0.d0
       do 13 l=1,ks
       pp1=pp1+dexp(s(key(j+5),l))*w(l)*cmplx(fsp(1,l),fsp(2,l))
   13  continue
       fsv(1,1+ns*iul-ns)=real(pp1)
       fsv(2,1+ns*iul-ns)=aimag(pp1)
       do 4 j=2,ns
       jul=j+ns*iul-ns
       fsv(i,jul)=0.d0
       fsv(i+1,jul)=0.d0
    4  continue
c other Fourier modes:
      do 10 i=3,m21,2
      yi=theta*dfloat((i-1)/2)
      do 1 j=1,nst
      b(j)=cmplx(0.d0,0.d0)
      do 1 j0=1,j
    1 a(j,j0)=cmplx(0.d0,0.d0)
      do 12 j=1,ns
      jt=in(j)
c      if(i.eq.3) write(10,*)' in(',j,')=',jt,' it=',it(j)
      if(jt.eq.0)goto 12
      do 2 l=1,ks
      if(iu(l).ne.iul)goto 2
c       if(i.eq.3)write(10,*)j,l,vr(j,l)
c      if(i.eq.3) write(10,*)' tmpl=',tmpl(1,3),tmpl(1,4)
c      if(it(j).eq.0) then
       b(jt)=b(jt)+delta(yi,j,l,kodp(j))*dexp(s(key(j+5),l))
     /  *cmplx(fsp(i,l),fsp(i+1,l))*w(l)
c       if(i.eq.3)write(10,*)' jt,b=',jt,b(jt)
       do 9 j0=1,ns
       j0t=in(j0)
       if(j0t.ne.0)then
       if(j0t.le.j) a(jt,j0t)=a(jt,j0t)+delta(yi,j,l,kodp(j))*w(l)
     /  *delta(-yi,j0,l,kodp(j0))*dexp(s(key(j0+5),l)+s(key(j+5),l))
       else
        b(jt)=b(jt)-delta(yi,j,l,kodp(j))*dexp(s(key(j0+5),l)
     /   +s(key(j+5),l))*cmplx(tmpl(it(j0),i),tmpl(it(j0),i+1))
     /     *w(l)*delta(-yi,j0,l,kodp(j0))
c       if(i.eq.3)write(10,*)' j,j0,b',j,j0,b(jt)
       endif
    9  continue
c      endif
    2 continue
   12 continue
      if(nst.gt.1)then
       do 14 j=2,nst
       j1=j-1
       do 14 jt=1,j1
   14  a(jt,j)=conjg(a(j,jt))
      endif
c      if(i.eq.3.or.i.eq.m1)then
c       write(10,*)' skor, i=',i,' nst=',nst,' m21=',m21
c       write(10,*)' a:',(ip,(jp,a(ip,jp),jp=1,nst),ip=1,nst)
c       write(10,*)' p:',(ip,b(ip),ip=1,nst)
c      endif
      call cgesv(nst,1,a,5,ipiv,b,5,info)
c       if(i.eq.3.or.i.eq.m1)write(10,*)'l:',(ip,b(ip),ip=1,nst)
c      if(info.ne.0.and.i.eq.3)write(*,*)((vr(j,l),j=1,ns),l=1,ks)
      if(info.ne.0)write(*,*)' Error',info,' in solution of mode',i
c     write(*,*)ipiv(1),ipiv(2)
      do 3 j=1,ns
      jul=j+ns*(iul-1)
c      if(i.le.2*ifil+1.or.i.gt.ndf-2*ifil)then
c       fsv(i,jul)=0.d0
c       fsv(i+1,jul)=0.d0
c      else
      if(it(j).eq.0) then
       fsv(i,jul)=real(b(in(j)))
       fsv(i+1,jul)=aimag(b(in(j)))
      else
       fsv(i,jul)=tmpl(it(j),i)
       fsv(i+1,jul)=tmpl(it(j),i+1)
      endif
c complex conjugate:
      if(i.lt.m21) then
       fsv(m+2-i,jul)=fsv(i,jul)
       fsv(m+3-i,jul)=-fsv(i+1,jul)
      endif
    3 continue
      if(i.le.2*ifil+1.or.i.gt.ndf-2*ifil)goto 8
c sum contribution of unfiltered modes
      do 6 l=1,ks
      if(iu(l).ne.iul)goto 6
      p1=cmplx(fsp(i,l),fsp(i+1,l))
      do 7 j=1,ns
      jul=j+ns*(iul-1)
      p1=p1-delta(-yi,j,l,kodp(j))*dexp(s(key(j+5),l))*
     /cmplx(fsv(i,jul),fsv(i+1,jul))
    7 continue
      p2=p1*conjg(p1)
      if(i.eq.m21)p2=p2*0.5d0
      skor=skor+p2*w(l)
    6 continue
    8 continue
   10 continue
      skor=2.d0*skor
c      write(*,*)' skor 2:',skor
      return
      end

      function scoef(m)
c  calculation of strength factors
      implicit real*8 (a-h,o-z)
      include 'korelpar.f'
      dimension ipiv(5)
      complex a(5,5),b(5)
c      complex*16 c1j,c1j0,cj,cj0,cjm,cjj
      complex*16 c1j,c1m,cj,cm,cjm,cjj,delta
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      common/param/param(5,7),kodp(5)
      common/tmpl/tmplp(mtmp,4),tmpl(mtmp,npx2),ntmp
      nm=0
      do 1 i=1,5
      if(key(i).ge.2)nm=nm+1
    1 continue
      if(nm.le.0) then
       scoef=skor(m)
       return
      endif
      m1=m-1
      m21=m/2+1
      theta=-12.56637061435917292d0/dfloat(m)
      do 8 l=1,ks
      tl=t(l)
      do 2 jm=1,nm
      b(jm)=cmplx(0.d0,0.d0)
      do 2 jj=1,nm
    2 a(jm,jj)=cmplx(0.d0,0.d0)
      jm=0
      do 7 j=1,ns
      kj=key(j+5)
      if(key(kj).lt.2) goto 7
c      thlj=theta*idint(dabs(vr(j,l))+.5d0)
c      if(vr(j,l).lt.0.)thlj=-thlj
c      c1m=cmplx(dcos(thlj),dsin(thlj))
c      cm=cmplx(1.d0,0.d0)
      jm=jm+1
      jj=0
      do 6 j0=1,ns
      kj0=key(j0+5)
      if(key(kj0).ge.2) jj=jj+1
c      thlj=theta*idint(dabs(vr(j0,l))+.5d0)
c      if(vr(j0,l).lt.0.)thlj=-thlj
c      c1j=cmplx(dcos(thlj),-dsin(thlj))
c      cj=cmplx(1.d0,0.d0)
      do 5 i=1,m21,2
       yi=theta*dfloat((i-1)/2)
       cj=delta(-yi,j0,l,kodp(j0))
       cm=delta(yi,j,l,kodp(j))
       if(i.le.2*ifil+1.or.i.gt.ndf-2*ifil)goto 4
      do 3 l1=1,ks
       if(t(l1).ne.tl)goto 3
       iul=iu(l1)
       jum=j+ns*(iul-1)
       juj=j0+ns*(iul-1)
       cjm=cm*cmplx(fsv(i,jum),-fsv(i+1,jum))
      if(j0.eq.1) then
        b(jm)=b(jm)+cjm*cmplx(fsp(i,l1),fsp(i+1,l1))
        if(i.gt.1.and.i.lt.m21)
     /  b(jm)=b(jm)+conjg(cjm*cmplx(fsp(i,l1),fsp(i+1,l1)))
       endif
       cjm=cjm*cj*cmplx(fsv(i,juj),fsv(i+1,juj))
       if(i.gt.1.and.i.lt.m21) cjm=cjm+conjg(cjm)
       if(key(kj0).lt.2) then
        b(jm)=b(jm)-cjm*dexp(s(kj0,l1))
       else
        a(jm,jj)=a(jm,jj)+cjm
       endif
    3 continue
    4 continue
c      cm=cm*c1m
c      cj=cj*c1j
    5 continue
    6 continue
    7 continue
      do 13 jm=1,nm
      b(jm)=b(jm)+conjg(b(jm))
      do 12 jj=1,nm
   12 a(jm,jj)=a(jm,jj)+conjg(a(jm,jj))
c      write(2,50)jm,(real(a(jm,jj)),jj=1,nm),real(b(jm))
c   50 format(i2,6e12.5)
   13 continue
      call cgesv(nm,1,a,5,ipiv,b,5,info)
      jm=0
      do 8 j=1,ns
      if(key(key(j+5)).lt.2) goto 8
      jm=jm+1
      p1=real(b(jm))
      p2=aimag(b(jm))
      if(p1.lt.0.0.or.p2*p2.ge.1.d-4) then
c       CALL settextposition(23,1,curpos)
       write(*,*)' !',j,l,p1,p2
       write(2,*)' !',j,l,p1,p2
      endif
      if(p1.gt.0.0) then
       s(key(j+5),l)=dlog(p1)
      else
       s(key(j+5),l)=-9.9999d0
      endif
    8 continue
      do 11 j=1,ns
      kj=key(j+5)
      if(key(kj).lt.2) goto 11
      do 14 i=1,ntmp
      if(tmplp(i,3).eq.kj)goto 11
   14 continue
c Renormalization of line-strengths
      s0=0.d0
      do 9 l=1,ks
c  mean magnitude: s0=s0+s(kj,l), mean intensity:
       s0=s0+exp(s(kj,l))
    9 continue
c  mean magnitude: s0=s0/dfloat(ks), mean intensity:
       s0=dlog(s0/dfloat(ks))
      do 10 l=1,ks
   10 s(kj,l)=s(kj,l)-s0
   11 continue
      scoef=skor(m)
      return
      end


      FUNCTION SUMA(X)
C Suma
      IMPLICIT REAL*8(A-H,O-Z)
      include 'korelpar.f'
      DIMENSION X(1)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      common/sum/lsum
      if(lsum.eq.0) then
       CALL SETE(X,DX)
       call rv
       suma=skor(ndf)
       do 1 i=1,5
       if(key(i).eq.2) goto2
    1  continue
       return
    2  p=suma
       do 3 i=1,5
       suma=scoef(ndf)
c      write(2,*)' !',i,p,suma
       if(dabs(p-suma).le.1.d-5*p)return
    3  p=suma
      else
       suma=sumicka(x)
      endif
      RETURN
      END

      FUNCTION SUMICKA(X)
C Sumicka
      IMPLICIT REAL*8(A-H,O-Z)
      include 'korelpar.f'
      DIMENSION X(1)
      complex*16 c(5),c1(5),p1,delta
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      common/sum/lsum
      common/param/param(5,7),kodp(5)
      m=ndf
      m1=m-1
      m21=m/2+1
      theta=-12.56637061435917292d0/dfloat(m)
      do 1 j=1,ns
c      thlj=idint(dabs(x(j))+.5d0)
c      if(x(j).lt.0.)thlj=-thlj
c      dvrjl=x(j)-thlj
c      thlj=theta*thlj
c      c1(j)=cmplx(dcos(thlj),dsin(thlj))
cc?     / *cmplx(1.d0+dvrjl**2*(dcos(y)-1.d0),-dvrjl*dsin(y))
c      p0=dexp(s(key(j+5),lsum))
c    1 c(j)=cmplx(p0)
      vr(j,lsum)=x(j)
    1 continue
      sumicka=0.
      do 10 i=1,m21,2
       if(i.le.2*ifil+1.or.i.gt.ndf-2*ifil)goto 8
       yi=theta*dfloat((i-1)/2)
       p1=cmplx(fsp(i,lsum),fsp(i+1,lsum))
       do 7 j=1,ns
       jul=j+ns*(iu(lsum)-1)
c      p1=p1-conjg(c(j))*cmplx(fsv(i,jul),fsv(i+1,jul))
       p1=p1-delta(-yi,j,lsum,kodp(j))*cmplx(fsv(i,jul),fsv(i+1,jul))
     / *dexp(s(key(j+5),lsum))
    7  continue
       p0=p1*conjg(p1)
       if(i.gt.1.and.i.lt.m21) p0=p0+p0
       sumicka=sumicka+p0
    8 continue
c      do 10 j=1,ns
c      c(j)=c(j)*c1(j)
   10 continue
      RETURN
      END

      SUBROUTINE RV
      IMPLICIT REAL*8 (A-H,O-Z)
      include 'korelpar.f'
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
c      DATA PI2/6.28318530717958D0/
      DATA pi/3.14159265358979d0/
c radial velocities in hierarchical system: 3(1(0(1,2),2(3,4)),5)
      DO 1 L=1,KS
      IUL=IU(L)
      RVPB=US(2,IUL)
C      WRITE(*,*)' chkpt 3',IUL,RVPB
      IF(EL(4,1).EQ.0.) THEN
       YY3=0.D0
       DT3=0.
      ELSE
       TT=(T(L)-EL(4,2))/EL(4,1)
       AM3=TT*PI*(2.d0-EL(4,8)*TT)
       OM=EL(4,4)+EL(4,7)*(T(L)-EL(4,2))
       EC=EL(4,3)+EL(4,9)*(T(L)-EL(4,2))
       AK=EL(4,5)+EL(4,10)*(T(L)-EL(4,2))
       Q4=EL(4,6)+EL(4,11)*(T(L)-EL(4,2))
       CALL KEPLER(AM3,EC,AE3,UPS3,R3)
       YY3=(DCOS(OM+UPS3)+EC*DCOS(OM))*AK
       DT3=EL(4,1)*AK*(1.D0-EC**2)**1.5*DSIN(OM+UPS3)/
     / (1.D0+EC*DCOS(UPS3))/1883651.8312
      endif
      if(el(3,1).eq.0.) then
       yy2=0.d0
       dt2=0.
      else
       TT=(T(L)-EL(3,2)-DT3)/EL(3,1)
       AM2=TT*PI*(2.d0-EL(3,8)*TT)
       OM=EL(3,4)+EL(3,7)*(T(L)-EL(3,2)-DT3)
       EC=EL(3,3)+EL(3,9)*(T(L)-EL(3,2)-DT3)
       AK=EL(3,5)+EL(3,10)*(T(L)-EL(3,2)-DT3)
       Q3=EL(3,6)+EL(3,11)*(T(L)-EL(3,2)-DT3)
       CALL KEPLER(AM2,EC,AE2,UPS2,R2)
       YY2=(DCOS(OM+UPS2)+EC*DCOS(OM))*AK
       DT2=EL(3,1)*AK*(1.D0-EC**2)**1.5*DSIN(OM+UPS2)/
     / (1.D0+EC*DCOS(UPS2))/1883651.8312
      endif
      if(el(2,1).eq.0.) then
       yy1=0.d0
      else
       TT=(T(L)-EL(2,2)-DT3+DT2/EL(3,6))/EL(2,1)
       AM1=TT*PI*(2.d0-EL(2,8)*TT)
       OM=EL(2,4)+EL(2,7)*(T(L)-EL(2,2)-DT3+DT2/Q3)
       EC=EL(2,3)+EL(2,9)*(T(L)-EL(2,2)-DT3+DT2/Q3)
       AK=EL(2,5)+EL(2,10)*(T(L)-EL(2,2)-DT3+DT2/Q3)
       Q2=EL(2,6)+EL(2,11)*(T(L)-EL(2,2)-DT3+DT2/Q3)
       CALL KEPLER(AM1,EC,AE1,UPS1,R1)
       YY1=(DCOS(OM+UPS1)+EC*DCOS(OM))*AK
      endif
      TT=(T(L)-EL(1,2)-DT3-DT2)/EL(1,1)
      AM=TT*PI*(2.d0-EL(1,8)*TT)
      OM=EL(1,4)+EL(1,7)*(T(L)-EL(1,2)-DT3-DT2)
      EC=EL(1,3)+EL(1,9)*(T(L)-EL(1,2)-DT3-DT2)
      AK=EL(1,5)+EL(1,10)*(T(L)-EL(1,2)-DT3-DT2)
      Q1=EL(1,6)+EL(1,11)*(T(L)-EL(1,2)-DT3-DT2)
      CALL KEPLER(AM,EC,AE,UPS,R)
      YY=(DCOS(OM+UPS)+EC*DCOS(OM))*AK
C      WRITE(*,*)' CHKPT 2'
      J=1
      IF(IVJ(1).GT.0) VR(J,L)=(YY3+YY2+YY)/RVPB
      IF(key(1).GT.0) J=J+1
      IF(IVJ(2).GT.0) VR(J,L)=(YY3+YY2-YY/Q1)/RVPB
      IF(key(2).GT.0) J=J+1
      IF(IVJ(3).GT.0) VR(J,L)=(YY3-YY2/Q3+YY1)/RVPB
      IF(key(3).GT.0) J=J+1
      IF(IVJ(4).GT.0) VR(J,L)=(YY3-YY2/Q3-YY1/Q2)/RVPB
      IF(key(4).GT.0) J=J+1
      IF(IVJ(5).GT.0) VR(J,L)=-YY3/Q4/RVPB
    1 CONTINUE
      RETURN
      END

      subroutine simul(si,m)
      implicit real*8 (a-h,o-z)
      include 'korelpar.f'
      dimension si(m,5),p(5,3),iin(5)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
c      DATA PI,PI2/3.14159265358979D0,6.28318530717958D0/
      m1=m-1
      nu=1
      do 4 l=1,ks
      w(l)=1.d0
    4 iu(l)=1
      read(1,*)(t(l),l=1,ks)
c spektra parameters: primary continuum, centr. int., halfwidth, secondary
      do 1 j=1,ns
      read(1,*)(p(j,l),l=2,3),iin(j)
      write(*,*)(p(j,l),l=2,3),iin(j)
    1 continue
      read(1,*)sum,rvpb
      write(*,*)' noise=',sum,' RV/bin=',rvpb
      us(1,1)=1000.d0
      us(2,1)=rvpb
      nu=1
c radial velocities:
      call rv
c      write(*,*)' chkpt 1'
      i0=m/2
      do 5 i=1,m1,2
      di=dfloat(i-i0)/2.d0
      do 2 j=1,ns
      if(iin(j).le.1)si(i,j)=-p(j,2)*p(j,3)**2/(p(j,3)**2+di**2)
      if(iin(j).ge.2)si(i,j)=dmin1(0.d0,p(j,2)*((di/p(j,3))**2-1.d0))
    2 si(i+1,j)=0.d0
      do 6 l=1,ks
      sp(i,l)=1.d0+sum*(ran(1)-ran(2))
      sp(i+1,l)=0.d0
      do 3 j=1,ns
c      if(iin(j).le.1) sp(i,l)
c     / =sp(i,l)-p(j,2)*p(j,3)**2/(p(j,3)**2+(di-vr(j,l))**2)
c      if(iin(j).ge.2)sp(i,l)
c     / =sp(i,l)+dmin1(0.d0,p(j,2)*(((di-vr(j,l))/p(j,3))**2-1.d0))
      if(iin(j).le.1) sp(i,l)=sp(i,l)-
     / dexp(s(key(j+5),l))*p(j,2)*p(j,3)**2/(p(j,3)**2+(di-vr(j,l))**2)
      if(iin(j).ge.2)sp(i,l)=sp(i,l)+dexp(s(key(j+5),l))*
     / dmin1(0.d0,p(j,2)*(((di-vr(j,l))/p(j,3))**2-1.d0))
    3 continue
c     if(l.eq.16.and.i-1.eq.64*(i/64))write(*,*)i,sp(i,l)
    6 continue
    5 continue
      return
      end

      SUBROUTINE KEPLER(AM,E,AE,UPS,R)
C PODPROGRAM NA RESENI KEPLEROVY ROVNICE
      IMPLICIT REAL*8(A-H,O-Z)
      DATA PI,E0,C0/3.14159265358979D0,0.D0,1.D0/
      IF(E.EQ.E0) GO TO 2
      C0=DSQRT((1.D0+E)/(1.D0-E))
      E0=E
    2 AE=AM
      DO 1 I=1,50
      DE=(AM-AE+E*DSIN(AE))/(1.D0-E*DCOS(AE))
      AE=AE+DE
      IF(DABS(DE).LT.1.D-12) GOTO 3
    1 CONTINUE
    3 UPS=PI+(AE-PI)/C0
      IF(DABS(AE-PI).GT.1.D-5) UPS=2.D0*DATAN(DTAN(.5D0*AE)*C0)
      R=(1.D0-E*E)/(1.D0+E*DCOS(UPS))
      RETURN
      END

      function ran(idum)
c generator of random numbers according to num. rec.
      real*8 ran,r(97),rm1,rm2
      parameter (m1=259200,ia1=7141,ic1=54773,rm1=1./m1)
      parameter (m2=134456,ia2=8121,ic2=28411,rm2=1./m2)
      parameter (m3=243000,ia3=4561,ic3=51349)
      data iff /0/
      if(idum.lt.0.or.iff.eq.0) then
       iff=1
       ix1=mod(ic1-idum,m1)
       ix1=mod(ia1*ix1+ic1,m1)
       ix2=mod(ix1,m2)
       ix1=mod(ia1*ix1+ic1,m1)
       ix3=mod(ix1,m3)
       do 11 j=1,97
        ix1=mod(ia1*ix1+ic1,m1)
        ix2=mod(ia2*ix2+ic2,m2)
        r(j)=(dfloat(ix1)+dfloat(ix2)*rm2)*rm1
   11  continue
       idum=1
      endif
      ix1=mod(ia1*ix1+ic1,m1)
      ix2=mod(ia2*ix2+ic2,m2)
      ix3=mod(ia3*ix3+ic3,m3)
      j=1+(97*ix3)/m3
      if(j.gt.97.or.j.lt.1)pause
      ran=r(j)
      r(j)=(dfloat(ix1)+dfloat(ix2)*rm2)*rm1
c      call random(x)
c      ran=x
      return
      end

      subroutine sete(x,dx)
      implicit real*8(a-h,o-z)
      include 'korelpar.f'
      dimension x(1),dx(1)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      if(me.le.0) return
      do 10 j=1,me
      j0=ix(1,j)
      j1=ix(2,j)
      j2=ix(3,j)
      if(j0.gt.1)then
       if(j0.gt.2)then
        vr(key(10+j1),j2)=x(j)
        dvr(key(10+j1),j2)=dx(j)
       else
        s(j1,j2)=x(j)
        ds(j1,j2)=dx(j)
       endif
      else
c       i=10*j1+j2
       el(j1,j2)=x(j)
       if(j2.eq.1)el(j1,j2)=dexp(x(j))
       if(j2.eq.3)el(j1,j2)=1.d0/(1.d0+dexp(-x(j)))
       del(j1,j2)=dx(j)
       if(j2.eq.1)del(j1,j2)=dx(j)*el(j1,j2)
       if(j2.eq.3)del(j1,j2)=dx(j)/
     /    (1.d0/el(j1,j2)+1.d0/(1.d0-el(j1,j2)))
      endif
   10 continue
      return
      end

      subroutine setp(x,dx)
      implicit real*8(a-h,o-z)
      include 'korelpar.f'
      dimension x(1),dx(1)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      if(me.le.0) return
      do 10 j=1,me
      j0=ix(1,j)
      j1=ix(2,j)
      j2=ix(3,j)
      if(j0.gt.1) then
       if(j0.gt.2)then
c        j1=i/1000
c        j2=i-1000*j1
        x(j)=vr(key(10+j1),j2)
        dx(j)=dvr(key(10+j1),j2)
c       write(*,*)j1,j2,x(j)
       else
        x(j)=s(j1,j2)
        dx(j)=ds(j1,j2)
c       write(*,*)j1,j2,x(j)
      endif
      else
c       i=10*j1+j2
       x(j)=el(j1,j2)
       if(j2.eq.1)x(j)=dlog(el(j1,j2))
       if(j2.eq.3)x(j)=dlog(el(j1,j2)/(1.d0-el(j1,j2)))
       dx(j)=del(j1,j2)
       if(j2.eq.1)dx(j)=dx(j)/el(j1,j2)
       if(j2.eq.3)
     / dx(j)=dx(j)*(1.d0/el(j1,j2)+1.d0/(1.d0-el(j1,j2)))
      endif
   10 continue
      return
      end


      SUBROUTINE ACHIL(M1,X,DX,S,NITER,DS0)
C PODPROGRAM NA OPTIMALIZACI METODOU SIMPLEXU
      IMPLICIT REAL*8(A-H,O-Z)
      logical lpr
      CHARACTER*4 IA,IB,IC,ID,IM
CMS      INCLUDE 'FGRAPH.FD'
      DIMENSION S(M1,1),X0(10),XA(10),XB(10),XC(10),X(1),DX(1)
      DIMENSION S0(11)
      common/sum/lsum
      common/kpr/kpr
CMS      RECORD /rccoord/curpos
      DATA AA,BB,CC,DD/.9D0,.35D0,2.D0,.5D0/
      DATA IA,IB,IC,ID,IM/'A','B','C','D',' '/
CMS      CALL settextposition(22,1,curpos)
      write(*,*)'       '
      lpr=((kpr.ge.2).and.(lsum.eq.0)).or.(kpr.ge.3)
      ITER=0
      M=M1-1
      AM1=DFLOAT(M)
      PM=(DSQRT(DFLOAT(M1))+DFLOAT(M-1))/AM1/DSQRT(2.D0)
      QM=(DSQRT(DFLOAT(M1))-1.D0)/AM1/DSQRT(2.D0)
      DO 2 J=1,M
      S(1,J)=X(J)
      DO 1 I=2,M1
    1 S(I,J)=X(J)+QM*DX(J)
    2 S(J+1,J)=X(J)+PM*DX(J)
      DO 4 I=1,M1
      DO 3 J=1,M
    3 X(J)=S(I,J)
    4 S0(I)=SUMA(X)
    5 ITER=ITER+1
      FH=S0(1)
      FL=FH
      IH=1
      IL=1
      DO 7 I=2,M1
      IF(S0(I).GE.FL) GOTO 6
      FL=S0(I)
      IL=I
      GOTO 7
    6 IF(S0(I).LE.FH) GOTO 7
      FH=S0(I)
      IH=I
    7 CONTINUE
      IF(ITER.GT.NITER) GOTO 27
      DO 8 J=1,M
    8 X0(J)=0.
      FS=FL
      DO 11 I=1,M1
      IF(I.EQ.IH) GOTO 11
      IF(S0(I).LE.FS) GOTO 9
      FS=S0(I)
      IS=I
    9 DO 10 J=1,M
   10 X0(J)=X0(J)+S(I,J)/AM1
   11 CONTINUE
      DO 12 J=1,M
   12 XA(J)=(1.D0+AA)*X0(J)-AA*S(IH,J)
      SA=SUMA(XA)
C      IF(SA.GE.FL) GOTO 15
      IF(SA.GE.FS) GOTO 15
      DO 13 J=1,M
   13 XC(J)=(1.D0-CC)*X0(J)+CC*XA(J)
      SC=SUMA(XC)
      IF(SC.GE.SA) GOTO 16
CMS      CALL settextposition(22,1,curpos)
      WRITE(*,50)ITER,IC,IH,S0(IH),(S(IH,J),J=1,M)
      if(lpr)WRITE(2,50)ITER,IC,IH,S0(IH),(S(IH,J),J=1,M)
      S0(IH)=SC
      DO 14 J=1,M
   14 S(IH,J)=XC(J)
      GOTO 5
   15 IF(SA.GE.FS) GOTO 18
   16 continue
CMS    CALL settextposition(22,1,curpos)
      WRITE(*,50)ITER,IA,IH,S0(IH),(S(IH,J),J=1,M)
      if(lpr)WRITE(2,50)ITER,IA,IH,S0(IH),(S(IH,J),J=1,M)
      DO 17 J=1,M
   17 S(IH,J)=XA(J)
      S0(IH)=SA
      GOTO 5
   18 IF(SA.LE.FH) GOTO 20
      DO 19 J=1,M
   19 XB(J)=(1.D0-BB)*X0(J)+BB*S(IH,J)
      GOTO 22
   20 DO 21 J=1,M
   21 XB(J)=(1.D0-BB)*X0(J)+BB*XA(J)
   22 SB=SUMA(XB)
      IF(SB.GE.FH) GOTO 24
CMS      CALL settextposition(22,1,curpos)
      WRITE(*,50)ITER,IB,IH,S0(IH),(S(IH,J),J=1,M)
      if(lpr)WRITE(2,50)ITER,IB,IH,S0(IH),(S(IH,J),J=1,M)
      DO 23 J=1,M
   23 S(IH,J)=XB(J)
      S0(IH)=SB
      GOTO 5
   24 continue
CMS      CALL settextposition(22,1,curpos)
      WRITE(*,50)ITER,ID,IH,S0(IH),(S(IH,J),J=1,M)
      if(lpr)WRITE(2,50)ITER,ID,IH,S0(IH),(S(IH,J),J=1,M)
      DO 26 I=1,M1
      IF(I.EQ.IL) GOTO 26
      DO 25 J=1,M
      X(J)=S(IL,J)+DD*(S(I,J)-S(IL,J))
   25 S(I,J)=X(J)
      S0(I)=SUMA(X)
   26 CONTINUE
      GOTO 5
   27 DS0=1.-S0(IL)/S0(IH)
      DO 29 I=1,M
      X(I)=S(IL,I)
      DXI=0.D0
      DO 28 J=1,M1
   28 DXI=DMAX1(DXI,DABS(S(J,I)-X(I)))
      IF(DXI.EQ.0.) DS0=0.
   29 IF(DXI.NE.0.) DX(I)=DXI
      WRITE(*,50)ITER,IM,IH,S0(IH),(DX(J),J=1,M)
      WRITE(*,50)ITER,IM,IL,S0(IL),(X(J),J=1,M)
      if(lpr)WRITE(2,50)ITER,IM,IH,S0(IH),(DX(J),J=1,M)
      if(lpr)WRITE(2,50)ITER,IM,IL,S0(IL),(X(J),J=1,M)
   50 FORMAT(1X,I3,1X,A1,I2,11E12.5)
      RETURN
      END

c FFT - Fast Fourier Transform
      SUBROUTINE FOUR1(F,NN,ISIGN)
      REAL*8 WR,WI,WPR,WPI,WTEMP,THETA,F
      DIMENSION F(*)
      N=2*NN
      J=1
      DO 11 I=1,N,2
       IF(J.GT.I)THEN
        TEMPR=F(J)
        TEMPI=F(J+1)
        F(J)=F(I)
        F(J+1)=F(I+1)
        F(I)=TEMPR
        F(I+1)=TEMPI
       ENDIF
       M=N/2
    1  IF ((M.GE.2).AND.(J.GT.M)) THEN
        J=J-M
        M=M/2
       GO TO 1
       ENDIF
       J=J+M
   11 CONTINUE
      MMAX=2
    3 IF (N.GT.MMAX) THEN
       ISTEP=2*MMAX
       THETA=6.28318530717959D0/(ISIGN*MMAX)
       WPR=-2.D0*DSIN(0.5D0*THETA)**2
       WPI=DSIN(THETA)
       WR=1.D0
       WI=0.D0
       DO 13 M=1,MMAX,2
        DO 12 I=M,N,ISTEP
         J=I+MMAX
         TEMPR=SNGL(WR)*F(J)-SNGL(WI)*F(J+1)
         TEMPI=SNGL(WR)*F(J+1)+SNGL(WI)*F(J)
         F(J)=F(I)-TEMPR
         F(J+1)=F(I+1)-TEMPI
         F(I)=F(I)+TEMPR
         F(I+1)=F(I+1)+TEMPI
   12   CONTINUE
        WTEMP=WR
        WR=WR*WPR-WI*WPI+WR
        WI=WI*WPR+WTEMP*WPI+WI
   13  CONTINUE
       MMAX=ISTEP
      GO TO 3
      ENDIF
      RETURN
      END

      SUBROUTINE CGESV( N, NRHS, A, LDA, IPIV, B, LDB, INFO )
*
*  -- LAPACK driver routine (version 1.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 29, 1992
*
*     .. Scalar Arguments ..
      INTEGER            INFO, LDA, LDB, N, NRHS
*     ..
*     .. Array Arguments ..
      INTEGER            IPIV( * )
      COMPLEX            A( LDA, * ), B( LDB, * )
*     ..
*
*  Purpose
*  =======
*
*  CGESV computes the solution to a complex system of linear equations
*     A * X = B,
*  where A is an N by N matrix and X and B are N by NRHS matrices.
*
*  The LU decomposition with partial pivoting and row interchanges is
*  used to factor A as
*     A = P * L * U,
*  where P is a permutation matrix, L is unit lower triangular, and U is
*  upper triangular.  The factored form of A is then used to solve the
*  system of equations A * X = B.
*
*  Arguments
*  =========
*
*  N       (input) INTEGER
*          The number of linear equations, i.e., the order of the
*          matrix A.  N >= 0.
*
*  NRHS    (input) INTEGER
*          The number of right hand sides, i.e., the number of columns
*          of the matrix B.  NRHS >= 0.
*
*  A       (input/output) COMPLEX array, dimension (LDA,N)
*          On entry, the N by N matrix of coefficients A.
*          On exit, the factors L and U from the factorization
*          A = P*L*U; the unit diagonal elements of L are not stored.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,N).
*
*  IPIV    (output) INTEGER array, dimension (N)
*          The pivot indices that define the permutation matrix P;
*          row i of the matrix was interchanged with row IPIV(i).
*
*  B       (input/output) COMPLEX array, dimension (LDB,NRHS)
*          On entry, the N by NRHS matrix of right hand side vectors B
*          for the system of equations A*X = B.
*          On exit, if INFO = 0, the N by NRHS matrix of solution
*          vectors X.
*
*  LDB     (input) INTEGER
*          The leading dimension of the array B.  LDB >= max(1,N).
*
*  INFO    (output) INTEGER
*          = 0: successful exit
*          < 0: if INFO = -k, the k-th argument had an illegal value
*          > 0: if INFO = k, U(k,k) is exactly zero.  The factorization
*               has been completed, but the factor U is exactly
*               singular, so the solution could not be computed.
*
*  =====================================================================
*
*     .. External Subroutines ..
      EXTERNAL           CGETRF, CGETRS, XERBLA
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          MAX
*     ..
*     .. Executable Statements ..
*
*     Test the input parameters.
*
      INFO = 0
      IF( N.LT.0 ) THEN
         INFO = -1
      ELSE IF( NRHS.LT.0 ) THEN
         INFO = -2
      ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
         INFO = -4
      ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
         INFO = -7
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'CGESV ', -INFO )
         RETURN
      END IF
*
*     Compute the LU factorization of A.
*
      CALL CGETRF( N, N, A, LDA, IPIV, INFO )
      IF( INFO.EQ.0 ) THEN
*
*        Solve the system A*X = B, overwriting B with X.
*
         CALL CGETRS( 'No transpose', N, NRHS, A, LDA, IPIV, B, LDB,
     $                INFO )
      END IF
      RETURN
*
*     End of CGESV
*
      END

      SUBROUTINE CGETRF( M, N, A, LDA, IPIV, INFO )
*
*  -- LAPACK routine (version 1.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 29, 1992
*
*     .. Scalar Arguments ..
      INTEGER            INFO, LDA, M, N
*     ..
*     .. Array Arguments ..
      INTEGER            IPIV( * )
      COMPLEX            A( LDA, * )
*     ..
*
*  Purpose
*  =======
*
*  CGETRF computes an LU factorization of a general m-by-n matrix A
*  using partial pivoting with row interchanges.
*
*  The factorization has the form
*     A = P * L * U
*  where P is a permutation matrix, L is lower triangular with unit
*  diagonal elements (lower trapezoidal if m > n), and U is upper
*  triangular (upper trapezoidal if m < n).
*
*  This is the right-looking Level 3 BLAS version of the algorithm.
*
*  Arguments
*  =========
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 0.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 0.
*
*  A       (input/output) COMPLEX array, dimension (LDA,N)
*          On entry, the m by n matrix to be factored.
*          On exit, the factors L and U from the factorization
*          A = P*L*U; the unit diagonal elements of L are not stored.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,M).
*
*  IPIV    (output) INTEGER array, dimension (min(M,N))
*          The pivot indices; for 1 <= i <= min(M,N), row i of the
*          matrix was interchanged with row IPIV(i).
*
*  INFO    (output) INTEGER
*          = 0: successful exit
*          < 0: if INFO = -k, the k-th argument had an illegal value
*          > 0: if INFO = k, U(k,k) is exactly zero. The factorization
*               has been completed, but the factor U is exactly
*               singular, and division by zero will occur if it is used
*               to solve a system of equations.
*
*  =====================================================================
*
*     .. Parameters ..
      COMPLEX            ONE
      PARAMETER          ( ONE = 1.0E+0 )
*     ..
*     .. Local Scalars ..
      INTEGER            I, IINFO, J, JB, NB
*     ..
*     .. External Subroutines ..
      EXTERNAL           CGEMM, CGETF2, CLASWP, CTRSM, XERBLA
*     ..
*     .. External Functions ..
      INTEGER            ILAENV
      EXTERNAL           ILAENV
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          MAX, MIN
*     ..
*     .. Executable Statements ..
*
*     Test the input parameters.
*
      INFO = 0
      IF( M.LT.0 ) THEN
         INFO = -1
      ELSE IF( N.LT.0 ) THEN
         INFO = -2
      ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
         INFO = -4
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'CGETRF', -INFO )
         RETURN
      END IF
*
*     Quick return if possible
*
      IF( M.EQ.0 .OR. N.EQ.0 )
     $   RETURN
*
*     Determine the block size for this environment.
*
      NB = ILAENV( 1, 'CGETRF', ' ', M, N, -1, -1 )
      IF( NB.LE.1 .OR. NB.GE.MIN( M, N ) ) THEN
*
*        Use unblocked code.
*
         CALL CGETF2( M, N, A, LDA, IPIV, INFO )
      ELSE
*
*        Use blocked code.
*
         DO 20 J = 1, MIN( M, N ), NB
            JB = MIN( MIN( M, N )-J+1, NB )
*
*           Factor diagonal and subdiagonal blocks and test for exact
*           singularity.
*
            CALL CGETF2( M-J+1, JB, A( J, J ), LDA, IPIV( J ), IINFO )
*
*           Adjust INFO and the pivot indices.
*
            IF( INFO.EQ.0 .AND. IINFO.GT.0 )
     $         INFO = IINFO + J - 1
            DO 10 I = J, MIN( M, J+JB-1 )
               IPIV( I ) = J - 1 + IPIV( I )
   10       CONTINUE
*
*           Apply interchanges to columns 1:J-1.
*
            CALL CLASWP( J-1, A, LDA, J, J+JB-1, IPIV, 1 )
*
            IF( J+JB.LE.N ) THEN
*
*              Apply interchanges to columns J+JB:N.
*
               CALL CLASWP( N-J-JB+1, A( 1, J+JB ), LDA, J, J+JB-1,
     $                      IPIV, 1 )
*
*              Compute block row of U.
*
               CALL CTRSM( 'Left', 'Lower', 'No transpose', 'Unit', JB,
     $                     N-J-JB+1, ONE, A( J, J ), LDA, A( J, J+JB ),
     $                     LDA )
               IF( J+JB.LE.M ) THEN
*
*                 Update trailing submatrix.
*
                  CALL CGEMM( 'No transpose', 'No transpose', M-J-JB+1,
     $                        N-J-JB+1, JB, -ONE, A( J+JB, J ), LDA,
     $                        A( J, J+JB ), LDA, ONE, A( J+JB, J+JB ),
     $                        LDA )
               END IF
            END IF
   20    CONTINUE
      END IF
      RETURN
*
*     End of CGETRF
*
      END

      SUBROUTINE CGETRS( TRANS, N, NRHS, A, LDA, IPIV, B, LDB, INFO )
*
*  -- LAPACK routine (version 1.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 29, 1992
*
*     .. Scalar Arguments ..
      CHARACTER          TRANS
      INTEGER            INFO, LDA, LDB, N, NRHS
*     ..
*     .. Array Arguments ..
      INTEGER            IPIV( * )
      COMPLEX            A( LDA, * ), B( LDB, * )
*     ..
*
*  Purpose
*  =======
*
*  CGETRS solves a system of linear equations
*     A * X = B,  A**T * X = B,  or  A**H * X = B
*  with a general n by n matrix A using the LU factorization computed
*  by CGETRF.
*
*  Arguments
*  =========
*
*  TRANS   (input) CHARACTER*1
*          Specifies the form of the system of equations.
*          = 'N':  A * X = B     (No transpose)
*          = 'T':  A**T * X = B  (Transpose)
*          = 'C':  A**H * X = B  (Conjugate transpose)
*
*  N       (input) INTEGER
*          The order of the matrix A.  N >= 0.
*
*  NRHS    (input) INTEGER
*          The number of right hand sides, i.e., the number of columns
*          of the matrix B.  NRHS >= 0.
*
*  A       (input) COMPLEX array, dimension (LDA,N)
*          The factors L and U from the factorization A = P*L*U
*          as computed by CGETRF.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,N).
*
*  IPIV    (input) INTEGER array, dimension (N)
*          The pivot indices from CGETRF; for 1<=i<=N, row i of the
*          matrix was interchanged with row IPIV(i).
*
*  B       (input/output) COMPLEX array, dimension (LDB,NRHS)
*          On entry, the right hand side vectors B for the system of
*          linear equations.
*          On exit, the solution vectors, X.
*
*  LDB     (input) INTEGER
*          The leading dimension of the array B.  LDB >= max(1,N).
*
*  INFO    (output) INTEGER
*          = 0:  successful exit
*          < 0: if INFO = -k, the k-th argument had an illegal value
*
*  =====================================================================
*
*     .. Parameters ..
      COMPLEX            ONE
      PARAMETER          ( ONE = 1.0E+0 )
*     ..
*     .. Local Scalars ..
      LOGICAL            NOTRAN
*     ..
*     .. External Functions ..
      LOGICAL            LSAME
      EXTERNAL           LSAME
*     ..
*     .. External Subroutines ..
      EXTERNAL           CLASWP, CTRSM, XERBLA
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          MAX
*     ..
*     .. Executable Statements ..
*
*     Test the input parameters.
*
      INFO = 0
      NOTRAN = LSAME( TRANS, 'N' )
      IF( .NOT.NOTRAN .AND. .NOT.LSAME( TRANS, 'T' ) .AND. .NOT.
     $    LSAME( TRANS, 'C' ) ) THEN
         INFO = -1
      ELSE IF( N.LT.0 ) THEN
         INFO = -2
      ELSE IF( NRHS.LT.0 ) THEN
         INFO = -3
      ELSE IF( LDA.LT.MAX( 1, N ) ) THEN
         INFO = -5
      ELSE IF( LDB.LT.MAX( 1, N ) ) THEN
         INFO = -8
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'CGETRS', -INFO )
         RETURN
      END IF
*
*     Quick return if possible
*
      IF( N.EQ.0 .OR. NRHS.EQ.0 )
     $   RETURN
*
      IF( NOTRAN ) THEN
*
*        Solve A * X = B.
*
*        Apply row interchanges to the right hand sides.
*
         CALL CLASWP( NRHS, B, LDB, 1, N, IPIV, 1 )
*
*        Solve L*X = B, overwriting B with X.
*
         CALL CTRSM( 'Left', 'Lower', 'No transpose', 'Unit', N, NRHS,
     $               ONE, A, LDA, B, LDB )
*
*        Solve U*X = B, overwriting B with X.
*
         CALL CTRSM( 'Left', 'Upper', 'No transpose', 'Non-unit', N,
     $               NRHS, ONE, A, LDA, B, LDB )
      ELSE
*
*        Solve A**T * X = B  or A**H * X = B.
*
*        Solve U'*X = B, overwriting B with X.
*
         CALL CTRSM( 'Left', 'Upper', TRANS, 'Non-unit', N, NRHS, ONE,
     $               A, LDA, B, LDB )
*
*        Solve L'*X = B, overwriting B with X.
*
         CALL CTRSM( 'Left', 'Lower', TRANS, 'Unit', N, NRHS, ONE, A,
     $               LDA, B, LDB )
*
*        Apply row interchanges to the solution vectors.
*
         CALL CLASWP( NRHS, B, LDB, 1, N, IPIV, -1 )
      END IF
*
      RETURN
*
*     End of CGETRS
*
      END

      SUBROUTINE XERBLA( SRNAME, INFO )
*
*  -- LAPACK auxiliary routine (version 1.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 29, 1992
*
*     .. Scalar Arguments ..
      CHARACTER*6        SRNAME
      INTEGER            INFO
*     ..
*
*  Purpose
*  =======
*
*  XERBLA  is an error handler for the LAPACK routines.
*  It is called by an LAPACK routine if an input parameter has an
*  invalid value.  A message is printed and execution stops.
*
*  Installers may consider modifying the STOP statement in order to
*  call system-specific exception-handling facilities.
*
*  Arguments
*  =========
*
*  SRNAME  (input) CHARACTER*6
*          The name of the routine which called XERBLA.
*
*  INFO    (input) INTEGER
*          The position of the invalid parameter in the parameter list
*          of the calling routine.
*
*     .. Executable Statements ..
*
      WRITE( *, FMT = 9999 )SRNAME, INFO
*
      STOP
*
 9999 FORMAT( ' ** On entry to ', A6, ' parameter number ', I2, ' had ',
     $      'an illegal value' )
*
*     End of XERBLA
*
      END

      SUBROUTINE CTRSM ( SIDE, UPLO, TRANSA, DIAG, M, N, ALPHA, A, LDA,
     $                   B, LDB )
*     .. Scalar Arguments ..
      CHARACTER*1        SIDE, UPLO, TRANSA, DIAG
      INTEGER            M, N, LDA, LDB
      COMPLEX            ALPHA
*     .. Array Arguments ..
      COMPLEX            A( LDA, * ), B( LDB, * )
*     ..
*
*  Purpose
*  =======
*
*  CTRSM  solves one of the matrix equations
*
*     op( A )*X = alpha*B,   or   X*op( A ) = alpha*B,
*
*  where alpha is a scalar, X and B are m by n matrices, A is a unit, or
*  non-unit,  upper or lower triangular matrix  and  op( A )  is one  of
*
*     op( A ) = A   or   op( A ) = A'   or   op( A ) = conjg( A' ).
*
*  The matrix X is overwritten on B.
*
*  Parameters
*  ==========
*
*  SIDE   - CHARACTER*1.
*           On entry, SIDE specifies whether op( A ) appears on the left
*           or right of X as follows:
*
*              SIDE = 'L' or 'l'   op( A )*X = alpha*B.
*
*              SIDE = 'R' or 'r'   X*op( A ) = alpha*B.
*
*           Unchanged on exit.
*
*  UPLO   - CHARACTER*1.
*           On entry, UPLO specifies whether the matrix A is an upper or
*           lower triangular matrix as follows:
*
*              UPLO = 'U' or 'u'   A is an upper triangular matrix.
*
*              UPLO = 'L' or 'l'   A is a lower triangular matrix.
*
*           Unchanged on exit.
*
*  TRANSA - CHARACTER*1.
*           On entry, TRANSA specifies the form of op( A ) to be used in
*           the matrix multiplication as follows:
*
*              TRANSA = 'N' or 'n'   op( A ) = A.
*
*              TRANSA = 'T' or 't'   op( A ) = A'.
*
*              TRANSA = 'C' or 'c'   op( A ) = conjg( A' ).
*
*           Unchanged on exit.
*
*  DIAG   - CHARACTER*1.
*           On entry, DIAG specifies whether or not A is unit triangular
*           as follows:
*
*              DIAG = 'U' or 'u'   A is assumed to be unit triangular.
*
*              DIAG = 'N' or 'n'   A is not assumed to be unit
*                                  triangular.
*
*           Unchanged on exit.
*
*  M      - INTEGER.
*           On entry, M specifies the number of rows of B. M must be at
*           least zero.
*           Unchanged on exit.
*
*  N      - INTEGER.
*           On entry, N specifies the number of columns of B.  N must be
*           at least zero.
*           Unchanged on exit.
*
*  ALPHA  - COMPLEX         .
*           On entry,  ALPHA specifies the scalar  alpha. When  alpha is
*           zero then  A is not referenced and  B need not be set before
*           entry.
*           Unchanged on exit.
*
*  A      - COMPLEX          array of DIMENSION ( LDA, k ), where k is m
*           when  SIDE = 'L' or 'l'  and is  n  when  SIDE = 'R' or 'r'.
*           Before entry  with  UPLO = 'U' or 'u',  the  leading  k by k
*           upper triangular part of the array  A must contain the upper
*           triangular matrix  and the strictly lower triangular part of
*           A is not referenced.
*           Before entry  with  UPLO = 'L' or 'l',  the  leading  k by k
*           lower triangular part of the array  A must contain the lower
*           triangular matrix  and the strictly upper triangular part of
*           A is not referenced.
*           Note that when  DIAG = 'U' or 'u',  the diagonal elements of
*           A  are not referenced either,  but are assumed to be  unity.
*           Unchanged on exit.
*
*  LDA    - INTEGER.
*           On entry, LDA specifies the first dimension of A as declared
*           in the calling (sub) program.  When  SIDE = 'L' or 'l'  then
*           LDA  must be at least  max( 1, m ),  when  SIDE = 'R' or 'r'
*           then LDA must be at least max( 1, n ).
*           Unchanged on exit.
*
*  B      - COMPLEX          array of DIMENSION ( LDB, n ).
*           Before entry,  the leading  m by n part of the array  B must
*           contain  the  right-hand  side  matrix  B,  and  on exit  is
*           overwritten by the solution matrix  X.
*
*  LDB    - INTEGER.
*           On entry, LDB specifies the first dimension of B as declared
*           in  the  calling  (sub)  program.   LDB  must  be  at  least
*           max( 1, m ).
*           Unchanged on exit.
*
*
*  Level 3 Blas routine.
*
*  -- Written on 8-February-1989.
*     Jack Dongarra, Argonne National Laboratory.
*     Iain Duff, AERE Harwell.
*     Jeremy Du Croz, Numerical Algorithms Group Ltd.
*     Sven Hammarling, Numerical Algorithms Group Ltd.
*
*
*     .. External Functions ..
      LOGICAL            LSAME
      EXTERNAL           LSAME
*     .. External Subroutines ..
      EXTERNAL           XERBLA
*     .. Intrinsic Functions ..
      INTRINSIC          CONJG, MAX
*     .. Local Scalars ..
      LOGICAL            LSIDE, NOCONJ, NOUNIT, UPPER
      INTEGER            I, INFO, J, K, NROWA
      COMPLEX            TEMP
*     .. Parameters ..
      COMPLEX            ONE
      PARAMETER        ( ONE  = ( 1.0E+0, 0.0E+0 ) )
      COMPLEX            ZERO
      PARAMETER        ( ZERO = ( 0.0E+0, 0.0E+0 ) )
*     ..
*     .. Executable Statements ..
*
*     Test the input parameters.
*
      LSIDE  = LSAME( SIDE  , 'L' )
      IF( LSIDE )THEN
         NROWA = M
      ELSE
         NROWA = N
      END IF
      NOCONJ = LSAME( TRANSA, 'T' )
      NOUNIT = LSAME( DIAG  , 'N' )
      UPPER  = LSAME( UPLO  , 'U' )
*
      INFO   = 0
      IF(      ( .NOT.LSIDE                ).AND.
     $         ( .NOT.LSAME( SIDE  , 'R' ) )      )THEN
         INFO = 1
      ELSE IF( ( .NOT.UPPER                ).AND.
     $         ( .NOT.LSAME( UPLO  , 'L' ) )      )THEN
         INFO = 2
      ELSE IF( ( .NOT.LSAME( TRANSA, 'N' ) ).AND.
     $         ( .NOT.LSAME( TRANSA, 'T' ) ).AND.
     $         ( .NOT.LSAME( TRANSA, 'C' ) )      )THEN
         INFO = 3
      ELSE IF( ( .NOT.LSAME( DIAG  , 'U' ) ).AND.
     $         ( .NOT.LSAME( DIAG  , 'N' ) )      )THEN
         INFO = 4
      ELSE IF( M  .LT.0               )THEN
         INFO = 5
      ELSE IF( N  .LT.0               )THEN
         INFO = 6
      ELSE IF( LDA.LT.MAX( 1, NROWA ) )THEN
         INFO = 9
      ELSE IF( LDB.LT.MAX( 1, M     ) )THEN
         INFO = 11
      END IF
      IF( INFO.NE.0 )THEN
         CALL XERBLA( 'CTRSM ', INFO )
         RETURN
      END IF
*
*     Quick return if possible.
*
      IF( N.EQ.0 )
     $   RETURN
*
*     And when  alpha.eq.zero.
*
      IF( ALPHA.EQ.ZERO )THEN
         DO 20, J = 1, N
            DO 10, I = 1, M
               B( I, J ) = ZERO
   10       CONTINUE
   20    CONTINUE
         RETURN
      END IF
*
*     Start the operations.
*
      IF( LSIDE )THEN
         IF( LSAME( TRANSA, 'N' ) )THEN
*
*           Form  B := alpha*inv( A )*B.
*
            IF( UPPER )THEN
               DO 60, J = 1, N
                  IF( ALPHA.NE.ONE )THEN
                     DO 30, I = 1, M
                        B( I, J ) = ALPHA*B( I, J )
   30                CONTINUE
                  END IF
                  DO 50, K = M, 1, -1
                     IF( B( K, J ).NE.ZERO )THEN
                        IF( NOUNIT )
     $                     B( K, J ) = B( K, J )/A( K, K )
                        DO 40, I = 1, K - 1
                           B( I, J ) = B( I, J ) - B( K, J )*A( I, K )
   40                   CONTINUE
                     END IF
   50             CONTINUE
   60          CONTINUE
            ELSE
               DO 100, J = 1, N
                  IF( ALPHA.NE.ONE )THEN
                     DO 70, I = 1, M
                        B( I, J ) = ALPHA*B( I, J )
   70                CONTINUE
                  END IF
                  DO 90 K = 1, M
                     IF( B( K, J ).NE.ZERO )THEN
                        IF( NOUNIT )
     $                     B( K, J ) = B( K, J )/A( K, K )
                        DO 80, I = K + 1, M
                           B( I, J ) = B( I, J ) - B( K, J )*A( I, K )
   80                   CONTINUE
                     END IF
   90             CONTINUE
  100          CONTINUE
            END IF
         ELSE
*
*           Form  B := alpha*inv( A' )*B
*           or    B := alpha*inv( conjg( A' ) )*B.
*
            IF( UPPER )THEN
               DO 140, J = 1, N
                  DO 130, I = 1, M
                     TEMP = ALPHA*B( I, J )
                     IF( NOCONJ )THEN
                        DO 110, K = 1, I - 1
                           TEMP = TEMP - A( K, I )*B( K, J )
  110                   CONTINUE
                        IF( NOUNIT )
     $                     TEMP = TEMP/A( I, I )
                     ELSE
                        DO 120, K = 1, I - 1
                           TEMP = TEMP - CONJG( A( K, I ) )*B( K, J )
  120                   CONTINUE
                        IF( NOUNIT )
     $                     TEMP = TEMP/CONJG( A( I, I ) )
                     END IF
                     B( I, J ) = TEMP
  130             CONTINUE
  140          CONTINUE
            ELSE
               DO 180, J = 1, N
                  DO 170, I = M, 1, -1
                     TEMP = ALPHA*B( I, J )
                     IF( NOCONJ )THEN
                        DO 150, K = I + 1, M
                           TEMP = TEMP - A( K, I )*B( K, J )
  150                   CONTINUE
                        IF( NOUNIT )
     $                     TEMP = TEMP/A( I, I )
                     ELSE
                        DO 160, K = I + 1, M
                           TEMP = TEMP - CONJG( A( K, I ) )*B( K, J )
  160                   CONTINUE
                        IF( NOUNIT )
     $                     TEMP = TEMP/CONJG( A( I, I ) )
                     END IF
                     B( I, J ) = TEMP
  170             CONTINUE
  180          CONTINUE
            END IF
         END IF
      ELSE
         IF( LSAME( TRANSA, 'N' ) )THEN
*
*           Form  B := alpha*B*inv( A ).
*
            IF( UPPER )THEN
               DO 230, J = 1, N
                  IF( ALPHA.NE.ONE )THEN
                     DO 190, I = 1, M
                        B( I, J ) = ALPHA*B( I, J )
  190                CONTINUE
                  END IF
                  DO 210, K = 1, J - 1
                     IF( A( K, J ).NE.ZERO )THEN
                        DO 200, I = 1, M
                           B( I, J ) = B( I, J ) - A( K, J )*B( I, K )
  200                   CONTINUE
                     END IF
  210             CONTINUE
                  IF( NOUNIT )THEN
                     TEMP = ONE/A( J, J )
                     DO 220, I = 1, M
                        B( I, J ) = TEMP*B( I, J )
  220                CONTINUE
                  END IF
  230          CONTINUE
            ELSE
               DO 280, J = N, 1, -1
                  IF( ALPHA.NE.ONE )THEN
                     DO 240, I = 1, M
                        B( I, J ) = ALPHA*B( I, J )
  240                CONTINUE
                  END IF
                  DO 260, K = J + 1, N
                     IF( A( K, J ).NE.ZERO )THEN
                        DO 250, I = 1, M
                           B( I, J ) = B( I, J ) - A( K, J )*B( I, K )
  250                   CONTINUE
                     END IF
  260             CONTINUE
                  IF( NOUNIT )THEN
                     TEMP = ONE/A( J, J )
                     DO 270, I = 1, M
                       B( I, J ) = TEMP*B( I, J )
  270                CONTINUE
                  END IF
  280          CONTINUE
            END IF
         ELSE
*
*           Form  B := alpha*B*inv( A' )
*           or    B := alpha*B*inv( conjg( A' ) ).
*
            IF( UPPER )THEN
               DO 330, K = N, 1, -1
                  IF( NOUNIT )THEN
                     IF( NOCONJ )THEN
                        TEMP = ONE/A( K, K )
                     ELSE
                        TEMP = ONE/CONJG( A( K, K ) )
                     END IF
                     DO 290, I = 1, M
                        B( I, K ) = TEMP*B( I, K )
  290                CONTINUE
                  END IF
                  DO 310, J = 1, K - 1
                     IF( A( J, K ).NE.ZERO )THEN
                        IF( NOCONJ )THEN
                           TEMP = A( J, K )
                        ELSE
                           TEMP = CONJG( A( J, K ) )
                        END IF
                        DO 300, I = 1, M
                           B( I, J ) = B( I, J ) - TEMP*B( I, K )
  300                   CONTINUE
                     END IF
  310             CONTINUE
                  IF( ALPHA.NE.ONE )THEN
                     DO 320, I = 1, M
                        B( I, K ) = ALPHA*B( I, K )
  320                CONTINUE
                  END IF
  330          CONTINUE
            ELSE
               DO 380, K = 1, N
                  IF( NOUNIT )THEN
                     IF( NOCONJ )THEN
                        TEMP = ONE/A( K, K )
                     ELSE
                        TEMP = ONE/CONJG( A( K, K ) )
                     END IF
                     DO 340, I = 1, M
                        B( I, K ) = TEMP*B( I, K )
  340                CONTINUE
                  END IF
                  DO 360, J = K + 1, N
                     IF( A( J, K ).NE.ZERO )THEN
                        IF( NOCONJ )THEN
                           TEMP = A( J, K )
                        ELSE
                           TEMP = CONJG( A( J, K ) )
                        END IF
                        DO 350, I = 1, M
                           B( I, J ) = B( I, J ) - TEMP*B( I, K )
  350                   CONTINUE
                     END IF
  360             CONTINUE
                  IF( ALPHA.NE.ONE )THEN
                     DO 370, I = 1, M
                        B( I, K ) = ALPHA*B( I, K )
  370                CONTINUE
                  END IF
  380          CONTINUE
            END IF
         END IF
      END IF
*
      RETURN
*
*     End of CTRSM .
*
      END

      SUBROUTINE CGETF2( M, N, A, LDA, IPIV, INFO )
*
*  -- LAPACK routine (version 1.0a) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     June 30, 1992
*
*     .. Scalar Arguments ..
      INTEGER            INFO, LDA, M, N
*     ..
*     .. Array Arguments ..
      INTEGER            IPIV( * )
      COMPLEX            A( LDA, * )
*     ..
*
*  Purpose
*  =======
*
*  CGETF2 computes an LU factorization of a general m-by-n matrix A
*  using partial pivoting with row interchanges.
*
*  The factorization has the form
*     A = P * L * U
*  where P is a permutation matrix, L is lower triangular with unit
*  diagonal elements (lower trapezoidal if m > n), and U is upper
*  triangular (upper trapezoidal if m < n).
*
*  This is the right-looking Level 2 BLAS version of the algorithm.
*
*  Arguments
*  =========
*
*  M       (input) INTEGER
*          The number of rows of the matrix A.  M >= 0.
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.  N >= 0.
*
*  A       (input/output) COMPLEX array, dimension (LDA,N)
*          On entry, the m by n matrix to be factored.
*          On exit, the factors L and U from the factorization
*          A = P*L*U; the unit diagonal elements of L are not stored.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.  LDA >= max(1,M).
*
*  IPIV    (output) INTEGER array, dimension (min(M,N))
*          The pivot indices; for 1 <= i <= min(M,N), row i of the
*          matrix was interchanged with row IPIV(i).
*
*  INFO    (output) INTEGER
*          = 0: successful exit
*          < 0: if INFO = -k, the k-th argument had an illegal value
*          > 0: if INFO = k, U(k,k) is exactly zero. The factorization
*               has been completed, but the factor U is exactly
*               singular, and division by zero will occur if it is used
*               to solve a system of equations.
*
*  =====================================================================
*
*     .. Parameters ..
      COMPLEX            ONE, ZERO
      PARAMETER          ( ONE = 1.0E+0, ZERO = 0.0E+0 )
*     ..
*     .. Local Scalars ..
      INTEGER            J, JP
*     ..
*     .. External Functions ..
      INTEGER            ICAMAX
      EXTERNAL           ICAMAX
*     ..
*     .. External Subroutines ..
      EXTERNAL           CGERU, CSCAL, CSWAP, XERBLA
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          MAX, MIN
*     ..
*     .. Executable Statements ..
*
*     Test the input parameters.
*
      INFO = 0
      IF( M.LT.0 ) THEN
         INFO = -1
      ELSE IF( N.LT.0 ) THEN
         INFO = -2
      ELSE IF( LDA.LT.MAX( 1, M ) ) THEN
         INFO = -4
      END IF
      IF( INFO.NE.0 ) THEN
         CALL XERBLA( 'CGETF2', -INFO )
         RETURN
      END IF
*
*     Quick return if possible
*
      IF( M.EQ.0 .OR. N.EQ.0 )
     $   RETURN
*
      DO 10 J = 1, MIN( M, N )
*
*        Find pivot and test for singularity.
*
         JP = J - 1 + ICAMAX( M-J+1, A( J, J ), 1 )
         IPIV( J ) = JP
         IF( A( JP, J ).NE.ZERO ) THEN
*
*           Apply the interchange to columns 1:N.
*
            IF( JP.NE.J )
     $         CALL CSWAP( N, A( J, 1 ), LDA, A( JP, 1 ), LDA )
*
*           Compute elements J+1:M of J-th column.
*
            IF( J.LT.M )
     $         CALL CSCAL( M-J, ONE / A( J, J ), A( J+1, J ), 1 )
*
         ELSE IF( INFO.EQ.0 ) THEN
*
            INFO = J
         END IF
*
         IF( J.LT.MIN( M, N ) ) THEN
*
*           Update trailing submatrix.
*
            CALL CGERU( M-J, N-J, -ONE, A( J+1, J ), 1, A( J, J+1 ),
     $                  LDA, A( J+1, J+1 ), LDA )
         END IF
   10 CONTINUE
      RETURN
*
*     End of CGETF2
*
      END

      SUBROUTINE CLASWP( N, A, LDA, K1, K2, IPIV, INCX )
*
*  -- LAPACK auxiliary routine (version 1.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 29, 1992
*
*     .. Scalar Arguments ..
      INTEGER            INCX, K1, K2, LDA, N
*     ..
*     .. Array Arguments ..
      INTEGER            IPIV( * )
      COMPLEX            A( LDA, * )
*     ..
*
*  Purpose
*  =======
*
*  CLASWP performs a series of row interchanges on the matrix A.
*  One row interchange is initiated for each of rows K1 through K2 of A.
*
*  Arguments
*  =========
*
*  N       (input) INTEGER
*          The number of columns of the matrix A.
*
*  A       (input/output) COMPLEX array, dimension (LDA,N)
*          On entry, the matrix of column dimension N to which the row
*          interchanges will be applied.
*          On exit, the permuted matrix.
*
*  LDA     (input) INTEGER
*          The leading dimension of the array A.
*
*  K1      (input) INTEGER
*          The first element of IPIV for which a row interchange will
*          be done.
*
*  K2      (input) INTEGER
*          The last element of IPIV for which a row interchange will
*          be done.
*
*  IPIV    (input) INTEGER array, dimension (M*abs(INCX))
*          The vector of pivot indices.  Only the elements in positions
*          K1 through K2 of IPIV are accessed.
*          IPIV(K) = L implies rows K and L are to be interchanged.
*
*  INCX    (input) INTEGER
*          The increment between successive values of IPIV.  If IPIV
*          is negative, the pivots are applied in reverse order.
*
*
*     .. Local Scalars ..
      INTEGER            I, IP, IX
*     ..
*     .. External Subroutines ..
      EXTERNAL           CSWAP
*     ..
*     .. Executable Statements ..
*
*     Interchange row I with row IPIV(I) for each of rows K1 through K2.
*
      IF( INCX.EQ.0 )
     $   RETURN
      IF( INCX.GT.0 ) THEN
         IX = K1
      ELSE
         IX = 1 + ( 1-K2 )*INCX
      END IF
      IF( INCX.EQ.1 ) THEN
         DO 10 I = K1, K2
            IP = IPIV( I )
            IF( IP.NE.I )
     $         CALL CSWAP( N, A( I, 1 ), LDA, A( IP, 1 ), LDA )
   10    CONTINUE
      ELSE IF( INCX.GT.1 ) THEN
         DO 20 I = K1, K2
            IP = IPIV( IX )
            IF( IP.NE.I )
     $         CALL CSWAP( N, A( I, 1 ), LDA, A( IP, 1 ), LDA )
            IX = IX + INCX
   20    CONTINUE
      ELSE IF( INCX.LT.0 ) THEN
         DO 30 I = K2, K1, -1
            IP = IPIV( IX )
            IF( IP.NE.I )
     $         CALL CSWAP( N, A( I, 1 ), LDA, A( IP, 1 ), LDA )
            IX = IX + INCX
   30    CONTINUE
      END IF
*
      RETURN
*
*     End of CLASWP
*
      END

      INTEGER          FUNCTION ILAENV( ISPEC, NAME, OPTS, N1, N2, N3,
     $                 N4 )
*
*  -- LAPACK auxiliary routine (preliminary version) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 20, 1992
*
*     .. Scalar Arguments ..
      CHARACTER*( * )    NAME, OPTS
      INTEGER            ISPEC, N1, N2, N3, N4
*     ..
*
*  Purpose
*  =======
*
*  ILAENV is called from the LAPACK routines to choose problem-dependent
*  parameters for the local environment.  See ISPEC for a description of
*  the parameters.
*
*  This version provides a set of parameters which should give good,
*  but not optimal, performance on many of the currently available
*  computers.  Users are encouraged to modify this subroutine to set
*  the tuning parameters for their particular machine using the option
*  and problem size information in the arguments.
*
*  This routine will not function correctly if it is converted to all
*  lower case.  Converting it to all upper case is allowed.
*
*  Arguments
*  =========
*
*  ISPEC   (input) INTEGER
*          Specifies the parameter to be returned as the value of
*          ILAENV.
*          = 1: the optimal blocksize; if this value is 1, an unblocked
*               algorithm will give the best performance.
*          = 2: the minimum block size for which the block routine
*               should be used; if the usable block size is less than
*               this value, an unblocked routine should be used.
*          = 3: the crossover point (in a block routine, for N less
*               than this value, an unblocked routine should be used)
*          = 4: the number of shifts, used in the nonsymmetric
*               eigenvalue routines
*          = 5: the minimum column dimension for blocking to be used;
*               rectangular blocks must have dimension at least k by m,
*               where k is given by ILAENV(2,...) and m by ILAENV(5,...)
*          = 6: the crossover point for the SVD (when reducing an m by n
*               matrix to bidiagonal form, if max(m,n)/min(m,n) exceeds
*               this value, a QR factorization is used first to reduce
*               the matrix to a triangular form.)
*          = 7: the number of processors
*          = 8: the crossover point for the multishift QR and QZ methods
*               for nonsymmetric eigenvalue problems.
*
*  NAME    (input) CHARACTER*(*)
*          The name of the calling subroutine, in either upper case or
*          lower case.
*
*  OPTS    (input) CHARACTER*(*)
*          The character options to the subroutine NAME, concatenated
*          into a single character string.  For example, UPLO = 'U',
*          TRANS = 'T', and DIAG = 'N' for a triangular routine would
*          be specified as OPTS = 'UTN'.
*
*  N1      (input) INTEGER
*  N2      (input) INTEGER
*  N3      (input) INTEGER
*  N4      (input) INTEGER
*          Problem dimensions for the subroutine NAME; these may not all
*          be required.
*
* (ILAENV) (output) INTEGER
*          >= 0: the value of the parameter specified by ISPEC
*          < 0:  if ILAENV = -k, the k-th argument had an illegal value.
*
*  Further Details
*  ===============
*
*  The following conventions have been used when calling ILAENV from the
*  LAPACK routines:
*  1)  OPTS is a concatenation of all of the character options to
*      subroutine NAME, in the same order that they appear in the
*      argument list for NAME, even if they are not used in determining
*      the value of the parameter specified by ISPEC.
*  2)  The problem dimensions N1, N2, N3, N4 are specified in the order
*      that they appear in the argument list for NAME.  N1 is used
*      first, N2 second, and so on, and unused problem dimensions are
*      passed a value of -1.
*  3)  The parameter value returned by ILAENV is checked for validity in
*      the calling subroutine.  For example, ILAENV is used to retrieve
*      the optimal blocksize for STRTRI as follows:
*
*      NB = ILAENV( 1, 'STRTRI', UPLO // DIAG, N, -1, -1, -1 )
*      IF( NB.LE.1 ) NB = MAX( 1, N )
*
*  =====================================================================
*
*     .. Local Scalars ..
      LOGICAL            CNAME, SNAME
      CHARACTER*1        C1
      CHARACTER*2        C2, C4
      CHARACTER*3        C3
      CHARACTER*6        SUBNAM
      INTEGER            I, IC, IZ, NB, NBMIN, NX
*     ..
*     .. Intrinsic Functions ..
      INTRINSIC          CHAR, ICHAR, INT, MIN, REAL
*     ..
*     .. Executable Statements ..
*
      GO TO ( 100, 100, 100, 400, 500, 600, 700, 800 ) ISPEC
*
*     Invalid value for ISPEC
*
      ILAENV = -1
      RETURN
*
  100 CONTINUE
*
*     Convert NAME to upper case if the first character is lower case.
*
      ILAENV = 1
      SUBNAM = NAME
      IC = ICHAR( SUBNAM( 1:1 ) )
      IZ = ICHAR( 'Z' )
      IF( IZ.EQ.90 .OR. IZ.EQ.122 ) THEN
*
*        ASCII character set
*
         IF( IC.GE.97 .AND. IC.LE.122 ) THEN
            SUBNAM( 1:1 ) = CHAR( IC-32 )
            DO 10 I = 2, 6
               IC = ICHAR( SUBNAM( I:I ) )
               IF( IC.GE.97 .AND. IC.LE.122 )
     $            SUBNAM( I:I ) = CHAR( IC-32 )
   10       CONTINUE
         END IF
*
      ELSE IF( IZ.EQ.233 .OR. IZ.EQ.169 ) THEN
*
*        EBCDIC character set
*
         IF( ( IC.GE.129 .AND. IC.LE.137 ) .OR.
     $       ( IC.GE.145 .AND. IC.LE.153 ) .OR.
     $       ( IC.GE.162 .AND. IC.LE.169 ) ) THEN
            SUBNAM( 1:1 ) = CHAR( IC+64 )
            DO 20 I = 2, 6
               IC = ICHAR( SUBNAM( I:I ) )
               IF( ( IC.GE.129 .AND. IC.LE.137 ) .OR.
     $             ( IC.GE.145 .AND. IC.LE.153 ) .OR.
     $             ( IC.GE.162 .AND. IC.LE.169 ) )
     $            SUBNAM( I:I ) = CHAR( IC+64 )
   20       CONTINUE
         END IF
*
      ELSE IF( IZ.EQ.218 .OR. IZ.EQ.250 ) THEN
*
*        Prime machines:  ASCII+128
*
         IF( IC.GE.225 .AND. IC.LE.250 ) THEN
            SUBNAM( 1:1 ) = CHAR( IC-32 )
            DO 30 I = 2, 6
               IC = ICHAR( SUBNAM( I:I ) )
               IF( IC.GE.225 .AND. IC.LE.250 )
     $            SUBNAM( I:I ) = CHAR( IC-32 )
   30       CONTINUE
         END IF
      END IF
*
      C1 = SUBNAM( 1:1 )
      SNAME = C1.EQ.'S' .OR. C1.EQ.'D'
      CNAME = C1.EQ.'C' .OR. C1.EQ.'Z'
      IF( .NOT.( CNAME .OR. SNAME ) )
     $   RETURN
      C2 = SUBNAM( 2:3 )
      C3 = SUBNAM( 4:6 )
      C4 = C3( 2:3 )
*
      GO TO ( 110, 200, 300 ) ISPEC
*
  110 CONTINUE
*
*     ISPEC = 1:  block size
*
*     In these examples, separate code is provided for setting NB for
*     real and complex.  We assume that NB will take the same value in
*     single or double precision.
*
      NB = 1
*
      IF( C2.EQ.'GE' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            IF( SNAME ) THEN
               NB = 64
            ELSE
               NB = 64
            END IF
         ELSE IF( C3.EQ.'QRF' .OR. C3.EQ.'RQF' .OR. C3.EQ.'LQF' .OR.
     $            C3.EQ.'QLF' ) THEN
            IF( SNAME ) THEN
               NB = 32
            ELSE
               NB = 32
            END IF
         ELSE IF( C3.EQ.'HRD' ) THEN
            IF( SNAME ) THEN
               NB = 32
            ELSE
               NB = 32
            END IF
         ELSE IF( C3.EQ.'BRD' ) THEN
            IF( SNAME ) THEN
               NB = 32
            ELSE
               NB = 32
            END IF
         ELSE IF( C3.EQ.'TRI' ) THEN
            IF( SNAME ) THEN
               NB = 64
            ELSE
               NB = 64
            END IF
         END IF
      ELSE IF( C2.EQ.'PO' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            IF( SNAME ) THEN
               NB = 64
            ELSE
               NB = 64
            END IF
         END IF
      ELSE IF( C2.EQ.'SY' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            IF( SNAME ) THEN
               NB = 64
            ELSE
               NB = 64
            END IF
         ELSE IF( SNAME .AND. C3.EQ.'TRD' ) THEN
            NB = 1
         ELSE IF( SNAME .AND. C3.EQ.'GST' ) THEN
            NB = 64
         END IF
      ELSE IF( CNAME .AND. C2.EQ.'HE' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            NB = 64
         ELSE IF( C3.EQ.'TRD' ) THEN
            NB = 1
         ELSE IF( C3.EQ.'GST' ) THEN
            NB = 64
         END IF
      ELSE IF( SNAME .AND. C2.EQ.'OR' ) THEN
         IF( C3( 1:1 ).EQ.'G' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NB = 32
            END IF
         ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NB = 32
            END IF
         END IF
      ELSE IF( CNAME .AND. C2.EQ.'UN' ) THEN
         IF( C3( 1:1 ).EQ.'G' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NB = 32
            END IF
         ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NB = 32
            END IF
         END IF
      ELSE IF( C2.EQ.'GB' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            IF( SNAME ) THEN
               IF( N4.LE.64 ) THEN
                  NB = 1
               ELSE
                  NB = 32
               END IF
            ELSE
               IF( N4.LE.64 ) THEN
                  NB = 1
               ELSE
                  NB = 32
               END IF
            END IF
         END IF
      ELSE IF( C2.EQ.'PB' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            IF( SNAME ) THEN
               IF( N2.LE.64 ) THEN
                  NB = 1
               ELSE
                  NB = 32
               END IF
            ELSE
               IF( N2.LE.64 ) THEN
                  NB = 1
               ELSE
                  NB = 32
               END IF
            END IF
         END IF
      ELSE IF( C2.EQ.'TR' ) THEN
         IF( C3.EQ.'TRI' ) THEN
            IF( SNAME ) THEN
               NB = 64
            ELSE
               NB = 64
            END IF
         END IF
      ELSE IF( C2.EQ.'LA' ) THEN
         IF( C3.EQ.'UUM' ) THEN
            IF( SNAME ) THEN
               NB = 64
            ELSE
               NB = 64
            END IF
         END IF
      ELSE IF( SNAME .AND. C2.EQ.'ST' ) THEN
         IF( C3.EQ.'EBZ' ) THEN
            NB = 1
         END IF
      END IF
      ILAENV = NB
      RETURN
*
  200 CONTINUE
*
*     ISPEC = 2:  minimum block size
*
      NBMIN = 2
      IF( C2.EQ.'GE' ) THEN
         IF( C3.EQ.'QRF' .OR. C3.EQ.'RQF' .OR. C3.EQ.'LQF' .OR.
     $       C3.EQ.'QLF' ) THEN
            IF( SNAME ) THEN
               NBMIN = 2
            ELSE
               NBMIN = 2
            END IF
         ELSE IF( C3.EQ.'HRD' ) THEN
            IF( SNAME ) THEN
               NBMIN = 2
            ELSE
               NBMIN = 2
            END IF
         ELSE IF( C3.EQ.'BRD' ) THEN
            IF( SNAME ) THEN
               NBMIN = 2
            ELSE
               NBMIN = 2
            END IF
         ELSE IF( C3.EQ.'TRI' ) THEN
            IF( SNAME ) THEN
               NBMIN = 2
            ELSE
               NBMIN = 2
            END IF
         END IF
      ELSE IF( C2.EQ.'SY' ) THEN
         IF( C3.EQ.'TRF' ) THEN
            IF( SNAME ) THEN
               NBMIN = 2
            ELSE
               NBMIN = 2
            END IF
         ELSE IF( SNAME .AND. C3.EQ.'TRD' ) THEN
            NBMIN = 2
         END IF
      ELSE IF( CNAME .AND. C2.EQ.'HE' ) THEN
         IF( C3.EQ.'TRD' ) THEN
            NBMIN = 2
         END IF
      ELSE IF( SNAME .AND. C2.EQ.'OR' ) THEN
         IF( C3( 1:1 ).EQ.'G' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NBMIN = 2
            END IF
         ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NBMIN = 2
            END IF
         END IF
      ELSE IF( CNAME .AND. C2.EQ.'UN' ) THEN
         IF( C3( 1:1 ).EQ.'G' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NBMIN = 2
            END IF
         ELSE IF( C3( 1:1 ).EQ.'M' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NBMIN = 2
            END IF
         END IF
      END IF
      ILAENV = NBMIN
      RETURN
*
  300 CONTINUE
*
*     ISPEC = 3:  crossover point
*
      NX = 0
      IF( C2.EQ.'GE' ) THEN
         IF( C3.EQ.'QRF' .OR. C3.EQ.'RQF' .OR. C3.EQ.'LQF' .OR.
     $       C3.EQ.'QLF' ) THEN
            IF( SNAME ) THEN
               NX = 128
            ELSE
               NX = 128
            END IF
         ELSE IF( C3.EQ.'HRD' ) THEN
            IF( SNAME ) THEN
               NX = 128
            ELSE
               NX = 128
            END IF
         ELSE IF( C3.EQ.'BRD' ) THEN
            IF( SNAME ) THEN
               NX = 128
            ELSE
               NX = 128
            END IF
         END IF
      ELSE IF( C2.EQ.'SY' ) THEN
         IF( SNAME .AND. C3.EQ.'TRD' ) THEN
            NX = 1
         END IF
      ELSE IF( CNAME .AND. C2.EQ.'HE' ) THEN
         IF( C3.EQ.'TRD' ) THEN
            NX = 1
         END IF
      ELSE IF( SNAME .AND. C2.EQ.'OR' ) THEN
         IF( C3( 1:1 ).EQ.'G' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NX = 128
            END IF
         END IF
      ELSE IF( CNAME .AND. C2.EQ.'UN' ) THEN
         IF( C3( 1:1 ).EQ.'G' ) THEN
            IF( C4.EQ.'QR' .OR. C4.EQ.'RQ' .OR. C4.EQ.'LQ' .OR.
     $          C4.EQ.'QL' .OR. C4.EQ.'HR' .OR. C4.EQ.'TR' .OR.
     $          C4.EQ.'BR' ) THEN
               NX = 128
            END IF
         END IF
      END IF
      ILAENV = NX
      RETURN
*
  400 CONTINUE
*
*     ISPEC = 4:  number of shifts (used by xHSEQR)
*
      ILAENV = 6
      RETURN
*
  500 CONTINUE
*
*     ISPEC = 5:  minimum column dimension (not used)
*
      ILAENV = 2
      RETURN
*
  600 CONTINUE
*
*     ISPEC = 6:  crossover point for SVD (used by xGELSS and xGESVD)
*
      ILAENV = INT( REAL( MIN( N1, N2 ) )*1.6E0 )
      RETURN
*
  700 CONTINUE
*
*     ISPEC = 7:  number of processors (not used)
*
      ILAENV = 1
      RETURN
*
  800 CONTINUE
*
*     ISPEC = 8:  crossover point for multishift (used by xHSEQR)
*
      ILAENV = 50
      RETURN
*
*     End of ILAENV
*
      END

      SUBROUTINE CGEMM ( TRANSA, TRANSB, M, N, K, ALPHA, A, LDA, B, LDB,
     $                   BETA, C, LDC )
*     .. Scalar Arguments ..
      CHARACTER*1        TRANSA, TRANSB
      INTEGER            M, N, K, LDA, LDB, LDC
      COMPLEX            ALPHA, BETA
*     .. Array Arguments ..
      COMPLEX            A( LDA, * ), B( LDB, * ), C( LDC, * )
*     ..
*
*  Purpose
*  =======
*
*  CGEMM  performs one of the matrix-matrix operations
*
*     C := alpha*op( A )*op( B ) + beta*C,
*
*  where  op( X ) is one of
*
*     op( X ) = X   or   op( X ) = X'   or   op( X ) = conjg( X' ),
*
*  alpha and beta are scalars, and A, B and C are matrices, with op( A )
*  an m by k matrix,  op( B )  a  k by n matrix and  C an m by n matrix.
*
*  Parameters
*  ==========
*
*  TRANSA - CHARACTER*1.
*           On entry, TRANSA specifies the form of op( A ) to be used in
*           the matrix multiplication as follows:
*
*              TRANSA = 'N' or 'n',  op( A ) = A.
*
*              TRANSA = 'T' or 't',  op( A ) = A'.
*
*              TRANSA = 'C' or 'c',  op( A ) = conjg( A' ).
*
*           Unchanged on exit.
*
*  TRANSB - CHARACTER*1.
*           On entry, TRANSB specifies the form of op( B ) to be used in
*           the matrix multiplication as follows:
*
*              TRANSB = 'N' or 'n',  op( B ) = B.
*
*              TRANSB = 'T' or 't',  op( B ) = B'.
*
*              TRANSB = 'C' or 'c',  op( B ) = conjg( B' ).
*
*           Unchanged on exit.
*
*  M      - INTEGER.
*           On entry,  M  specifies  the number  of rows  of the  matrix
*           op( A )  and of the  matrix  C.  M  must  be at least  zero.
*           Unchanged on exit.
*
*  N      - INTEGER.
*           On entry,  N  specifies the number  of columns of the matrix
*           op( B ) and the number of columns of the matrix C. N must be
*           at least zero.
*           Unchanged on exit.
*
*  K      - INTEGER.
*           On entry,  K  specifies  the number of columns of the matrix
*           op( A ) and the number of rows of the matrix op( B ). K must
*           be at least  zero.
*           Unchanged on exit.
*
*  ALPHA  - COMPLEX         .
*           On entry, ALPHA specifies the scalar alpha.
*           Unchanged on exit.
*
*  A      - COMPLEX          array of DIMENSION ( LDA, ka ), where ka is
*           k  when  TRANSA = 'N' or 'n',  and is  m  otherwise.
*           Before entry with  TRANSA = 'N' or 'n',  the leading  m by k
*           part of the array  A  must contain the matrix  A,  otherwise
*           the leading  k by m  part of the array  A  must contain  the
*           matrix A.
*           Unchanged on exit.
*
*  LDA    - INTEGER.
*           On entry, LDA specifies the first dimension of A as declared
*           in the calling (sub) program. When  TRANSA = 'N' or 'n' then
*           LDA must be at least  max( 1, m ), otherwise  LDA must be at
*           least  max( 1, k ).
*           Unchanged on exit.
*
*  B      - COMPLEX          array of DIMENSION ( LDB, kb ), where kb is
*           n  when  TRANSB = 'N' or 'n',  and is  k  otherwise.
*           Before entry with  TRANSB = 'N' or 'n',  the leading  k by n
*           part of the array  B  must contain the matrix  B,  otherwise
*           the leading  n by k  part of the array  B  must contain  the
*           matrix B.
*           Unchanged on exit.
*
*  LDB    - INTEGER.
*           On entry, LDB specifies the first dimension of B as declared
*           in the calling (sub) program. When  TRANSB = 'N' or 'n' then
*           LDB must be at least  max( 1, k ), otherwise  LDB must be at
*           least  max( 1, n ).
*           Unchanged on exit.
*
*  BETA   - COMPLEX         .
*           On entry,  BETA  specifies the scalar  beta.  When  BETA  is
*           supplied as zero then C need not be set on input.
*           Unchanged on exit.
*
*  C      - COMPLEX          array of DIMENSION ( LDC, n ).
*           Before entry, the leading  m by n  part of the array  C must
*           contain the matrix  C,  except when  beta  is zero, in which
*           case C need not be set on entry.
*           On exit, the array  C  is overwritten by the  m by n  matrix
*           ( alpha*op( A )*op( B ) + beta*C ).
*
*  LDC    - INTEGER.
*           On entry, LDC specifies the first dimension of C as declared
*           in  the  calling  (sub)  program.   LDC  must  be  at  least
*           max( 1, m ).
*           Unchanged on exit.
*
*
*  Level 3 Blas routine.
*
*  -- Written on 8-February-1989.
*     Jack Dongarra, Argonne National Laboratory.
*     Iain Duff, AERE Harwell.
*     Jeremy Du Croz, Numerical Algorithms Group Ltd.
*     Sven Hammarling, Numerical Algorithms Group Ltd.
*
*
*     .. External Functions ..
      LOGICAL            LSAME
      EXTERNAL           LSAME
*     .. External Subroutines ..
      EXTERNAL           XERBLA
*     .. Intrinsic Functions ..
      INTRINSIC          CONJG, MAX
*     .. Local Scalars ..
      LOGICAL            CONJA, CONJB, NOTA, NOTB
      INTEGER            I, INFO, J, L, NCOLA, NROWA, NROWB
      COMPLEX            TEMP
*     .. Parameters ..
      COMPLEX            ONE
      PARAMETER        ( ONE  = ( 1.0E+0, 0.0E+0 ) )
      COMPLEX            ZERO
      PARAMETER        ( ZERO = ( 0.0E+0, 0.0E+0 ) )
*     ..
*     .. Executable Statements ..
*
*     Set  NOTA  and  NOTB  as  true if  A  and  B  respectively are not
*     conjugated or transposed, set  CONJA and CONJB  as true if  A  and
*     B  respectively are to be  transposed but  not conjugated  and set
*     NROWA, NCOLA and  NROWB  as the number of rows and  columns  of  A
*     and the number of rows of  B  respectively.
*
      NOTA  = LSAME( TRANSA, 'N' )
      NOTB  = LSAME( TRANSB, 'N' )
      CONJA = LSAME( TRANSA, 'C' )
      CONJB = LSAME( TRANSB, 'C' )
      IF( NOTA )THEN
         NROWA = M
         NCOLA = K
      ELSE
         NROWA = K
         NCOLA = M
      END IF
      IF( NOTB )THEN
         NROWB = K
      ELSE
         NROWB = N
      END IF
*
*     Test the input parameters.
*
      INFO = 0
      IF(      ( .NOT.NOTA                 ).AND.
     $         ( .NOT.CONJA                ).AND.
     $         ( .NOT.LSAME( TRANSA, 'T' ) )      )THEN
         INFO = 1
      ELSE IF( ( .NOT.NOTB                 ).AND.
     $         ( .NOT.CONJB                ).AND.
     $         ( .NOT.LSAME( TRANSB, 'T' ) )      )THEN
         INFO = 2
      ELSE IF( M  .LT.0               )THEN
         INFO = 3
      ELSE IF( N  .LT.0               )THEN
         INFO = 4
      ELSE IF( K  .LT.0               )THEN
         INFO = 5
      ELSE IF( LDA.LT.MAX( 1, NROWA ) )THEN
         INFO = 8
      ELSE IF( LDB.LT.MAX( 1, NROWB ) )THEN
         INFO = 10
      ELSE IF( LDC.LT.MAX( 1, M     ) )THEN
         INFO = 13
      END IF
      IF( INFO.NE.0 )THEN
         CALL XERBLA( 'CGEMM ', INFO )
         RETURN
      END IF
*
*     Quick return if possible.
*
      IF( ( M.EQ.0 ).OR.( N.EQ.0 ).OR.
     $    ( ( ( ALPHA.EQ.ZERO ).OR.( K.EQ.0 ) ).AND.( BETA.EQ.ONE ) ) )
     $   RETURN
*
*     And when  alpha.eq.zero.
*
      IF( ALPHA.EQ.ZERO )THEN
         IF( BETA.EQ.ZERO )THEN
            DO 20, J = 1, N
               DO 10, I = 1, M
                  C( I, J ) = ZERO
   10          CONTINUE
   20       CONTINUE
         ELSE
            DO 40, J = 1, N
               DO 30, I = 1, M
                  C( I, J ) = BETA*C( I, J )
   30          CONTINUE
   40       CONTINUE
         END IF
         RETURN
      END IF
*
*     Start the operations.
*
      IF( NOTB )THEN
         IF( NOTA )THEN
*
*           Form  C := alpha*A*B + beta*C.
*
            DO 90, J = 1, N
               IF( BETA.EQ.ZERO )THEN
                  DO 50, I = 1, M
                     C( I, J ) = ZERO
   50             CONTINUE
               ELSE IF( BETA.NE.ONE )THEN
                  DO 60, I = 1, M
                     C( I, J ) = BETA*C( I, J )
   60             CONTINUE
               END IF
               DO 80, L = 1, K
                  IF( B( L, J ).NE.ZERO )THEN
                     TEMP = ALPHA*B( L, J )
                     DO 70, I = 1, M
                        C( I, J ) = C( I, J ) + TEMP*A( I, L )
   70                CONTINUE
                  END IF
   80          CONTINUE
   90       CONTINUE
         ELSE IF( CONJA )THEN
*
*           Form  C := alpha*conjg( A' )*B + beta*C.
*
            DO 120, J = 1, N
               DO 110, I = 1, M
                  TEMP = ZERO
                  DO 100, L = 1, K
                     TEMP = TEMP + CONJG( A( L, I ) )*B( L, J )
  100             CONTINUE
                  IF( BETA.EQ.ZERO )THEN
                     C( I, J ) = ALPHA*TEMP
                  ELSE
                     C( I, J ) = ALPHA*TEMP + BETA*C( I, J )
                  END IF
  110          CONTINUE
  120       CONTINUE
         ELSE
*
*           Form  C := alpha*A'*B + beta*C
*
            DO 150, J = 1, N
               DO 140, I = 1, M
                  TEMP = ZERO
                  DO 130, L = 1, K
                     TEMP = TEMP + A( L, I )*B( L, J )
  130             CONTINUE
                  IF( BETA.EQ.ZERO )THEN
                     C( I, J ) = ALPHA*TEMP
                  ELSE
                     C( I, J ) = ALPHA*TEMP + BETA*C( I, J )
                  END IF
  140          CONTINUE
  150       CONTINUE
         END IF
      ELSE IF( NOTA )THEN
         IF( CONJB )THEN
*
*           Form  C := alpha*A*conjg( B' ) + beta*C.
*
            DO 200, J = 1, N
               IF( BETA.EQ.ZERO )THEN
                  DO 160, I = 1, M
                     C( I, J ) = ZERO
  160             CONTINUE
               ELSE IF( BETA.NE.ONE )THEN
                  DO 170, I = 1, M
                     C( I, J ) = BETA*C( I, J )
  170             CONTINUE
               END IF
               DO 190, L = 1, K
                  IF( B( J, L ).NE.ZERO )THEN
                     TEMP = ALPHA*CONJG( B( J, L ) )
                     DO 180, I = 1, M
                        C( I, J ) = C( I, J ) + TEMP*A( I, L )
  180                CONTINUE
                  END IF
  190          CONTINUE
  200       CONTINUE
         ELSE
*
*           Form  C := alpha*A*B'          + beta*C
*
            DO 250, J = 1, N
               IF( BETA.EQ.ZERO )THEN
                  DO 210, I = 1, M
                     C( I, J ) = ZERO
  210             CONTINUE
               ELSE IF( BETA.NE.ONE )THEN
                  DO 220, I = 1, M
                     C( I, J ) = BETA*C( I, J )
  220             CONTINUE
               END IF
               DO 240, L = 1, K
                  IF( B( J, L ).NE.ZERO )THEN
                     TEMP = ALPHA*B( J, L )
                     DO 230, I = 1, M
                        C( I, J ) = C( I, J ) + TEMP*A( I, L )
  230                CONTINUE
                  END IF
  240          CONTINUE
  250       CONTINUE
         END IF
      ELSE IF( CONJA )THEN
         IF( CONJB )THEN
*
*           Form  C := alpha*conjg( A' )*conjg( B' ) + beta*C.
*
            DO 280, J = 1, N
               DO 270, I = 1, M
                  TEMP = ZERO
                  DO 260, L = 1, K
                     TEMP = TEMP + CONJG( A( L, I ) )*CONJG( B( J, L ) )
  260             CONTINUE
                  IF( BETA.EQ.ZERO )THEN
                     C( I, J ) = ALPHA*TEMP
                  ELSE
                     C( I, J ) = ALPHA*TEMP + BETA*C( I, J )
                  END IF
  270          CONTINUE
  280       CONTINUE
         ELSE
*
*           Form  C := alpha*conjg( A' )*B' + beta*C
*
            DO 310, J = 1, N
               DO 300, I = 1, M
                  TEMP = ZERO
                  DO 290, L = 1, K
                     TEMP = TEMP + CONJG( A( L, I ) )*B( J, L )
  290             CONTINUE
                  IF( BETA.EQ.ZERO )THEN
                     C( I, J ) = ALPHA*TEMP
                  ELSE
                     C( I, J ) = ALPHA*TEMP + BETA*C( I, J )
                  END IF
  300          CONTINUE
  310       CONTINUE
         END IF
      ELSE
         IF( CONJB )THEN
*
*           Form  C := alpha*A'*conjg( B' ) + beta*C
*
            DO 340, J = 1, N
               DO 330, I = 1, M
                  TEMP = ZERO
                  DO 320, L = 1, K
                     TEMP = TEMP + A( L, I )*CONJG( B( J, L ) )
  320             CONTINUE
                  IF( BETA.EQ.ZERO )THEN
                     C( I, J ) = ALPHA*TEMP
                  ELSE
                     C( I, J ) = ALPHA*TEMP + BETA*C( I, J )
                  END IF
  330          CONTINUE
  340       CONTINUE
         ELSE
*
*           Form  C := alpha*A'*B' + beta*C
*
            DO 370, J = 1, N
               DO 360, I = 1, M
                  TEMP = ZERO
                  DO 350, L = 1, K
                     TEMP = TEMP + A( L, I )*B( J, L )
  350             CONTINUE
                  IF( BETA.EQ.ZERO )THEN
                     C( I, J ) = ALPHA*TEMP
                  ELSE
                     C( I, J ) = ALPHA*TEMP + BETA*C( I, J )
                  END IF
  360          CONTINUE
  370       CONTINUE
         END IF
      END IF
*
      RETURN
*
*     End of CGEMM .
*
      END

      LOGICAL          FUNCTION LSAME( CA, CB )
*
*  -- LAPACK auxiliary routine (version 1.0) --
*     Univ. of Tennessee, Univ. of California Berkeley, NAG Ltd.,
*     Courant Institute, Argonne National Lab, and Rice University
*     February 29, 1992
*
*     .. Scalar Arguments ..
      CHARACTER          CA, CB
*     ..
*
*  Purpose
*  =======
*
*  LSAME returns .TRUE. if CA is the same letter as CB regardless of
*  case.
*
*  Arguments
*  =========
*
*  CA      (input) CHARACTER*1
*  CB      (input) CHARACTER*1
*          CA and CB specify the single characters to be compared.
*
*     .. Intrinsic Functions ..
      INTRINSIC          ICHAR
*     ..
*     .. Local Scalars ..
      INTEGER            INTA, INTB, ZCODE
*     ..
*     .. Executable Statements ..
*
*     Test if the characters are equal
*
      LSAME = CA.EQ.CB
      IF( LSAME )
     $   RETURN
*
*     Now test for equivalence if both characters are alphabetic.
*
      ZCODE = ICHAR( 'Z' )
*
*     Use 'Z' rather than 'A' so that ASCII can be detected on Prime
*     machines, on which ICHAR returns a value with bit 8 set.
*     ICHAR('A') on Prime machines returns 193 which is the same as
*     ICHAR('A') on an EBCDIC machine.
*
      INTA = ICHAR( CA )
      INTB = ICHAR( CB )
*
      IF( ZCODE.EQ.90 .OR. ZCODE.EQ.122 ) THEN
*
*        ASCII is assumed - ZCODE is the ASCII code of either lower or
*        upper case 'Z'.
*
         IF( INTA.GE.97 .AND. INTA.LE.122 ) INTA = INTA - 32
         IF( INTB.GE.97 .AND. INTB.LE.122 ) INTB = INTB - 32
*
      ELSE IF( ZCODE.EQ.233 .OR. ZCODE.EQ.169 ) THEN
*
*        EBCDIC is assumed - ZCODE is the EBCDIC code of either lower or
*        upper case 'Z'.
*
         IF( INTA.GE.129 .AND. INTA.LE.137 .OR.
     $       INTA.GE.145 .AND. INTA.LE.153 .OR.
     $       INTA.GE.162 .AND. INTA.LE.169 ) INTA = INTA + 64
         IF( INTB.GE.129 .AND. INTB.LE.137 .OR.
     $       INTB.GE.145 .AND. INTB.LE.153 .OR.
     $       INTB.GE.162 .AND. INTB.LE.169 ) INTB = INTB + 64
*
      ELSE IF( ZCODE.EQ.218 .OR. ZCODE.EQ.250 ) THEN
*
*        ASCII is assumed, on Prime machines - ZCODE is the ASCII code
*        plus 128 of either lower or upper case 'Z'.
*
         IF( INTA.GE.225 .AND. INTA.LE.250 ) INTA = INTA - 32
         IF( INTB.GE.225 .AND. INTB.LE.250 ) INTB = INTB - 32
      END IF
      LSAME = INTA.EQ.INTB
*
*     RETURN
*
*     End of LSAME
*
      END

      integer function icamax(n,cx,incx)
c
c     finds the index of element having max. absolute value.
c     jack dongarra, linpack, 3/11/78.
c     modified to correct problem with negative increment, 8/21/90.
c
      complex cx(n)
      real smax
      integer i,incx,ix,n
      complex zdum
      real cabs1
      cabs1(zdum) = abs(real(zdum)) + abs(aimag(zdum))
c
      icamax = 0
      if( n .lt. 1 ) return
      icamax = 1
      if(n.eq.1)return
      if(incx.eq.1)go to 20
c
c        code for increment not equal to 1
c
      ix = 1
      if(incx.lt.0)ix = (-n+1)*incx + 1
      smax = cabs1(cx(ix))
      ix = ix + incx
      do 10 i = 2,n
         if(cabs1(cx(ix)).le.smax) go to 5
         icamax = i
         smax = cabs1(cx(ix))
    5    ix = ix + incx
   10 continue
      return
c
c        code for increment equal to 1
c
   20 smax = cabs1(cx(1))
      do 30 i = 2,n
         if(cabs1(cx(i)).le.smax) go to 30
         icamax = i
         smax = cabs1(cx(i))
   30 continue
      return
      end

      subroutine  cswap (n,cx,incx,cy,incy)
c
c     interchanges two vectors.
c     jack dongarra, linpack, 3/11/78.
c
      complex cx(n),cy(n),ctemp
      integer i,incx,incy,ix,iy,n
c
      if(n.le.0)return
      if(incx.eq.1.and.incy.eq.1)go to 20
c
c       code for unequal increments or equal increments not equal
c         to 1
c
      ix = 1
      iy = 1
      if(incx.lt.0)ix = (-n+1)*incx + 1
      if(incy.lt.0)iy = (-n+1)*incy + 1
      do 10 i = 1,n
        ctemp = cx(ix)
        cx(ix) = cy(iy)
        cy(iy) = ctemp
        ix = ix + incx
        iy = iy + incy
   10 continue
      return
c
c       code for both increments equal to 1
   20 do 30 i = 1,n
        ctemp = cx(i)
        cx(i) = cy(i)
        cy(i) = ctemp
   30 continue
      return
      end

      subroutine  cscal(n,ca,cx,incx)
c
c     scales a vector by a constant.
c     jack dongarra, linpack,  3/11/78.
c     modified to correct problem with negative increment, 8/21/90.
c
      complex ca,cx(n)
      integer i,incx,ix,n
c
      if(n.le.0)return
      if(incx.eq.1)go to 20
c
c        code for increment not equal to 1
c
      ix = 1
      if(incx.lt.0)ix = (-n+1)*incx + 1
      do 10 i = 1,n
        cx(ix) = ca*cx(ix)
        ix = ix + incx
   10 continue
      return
c
c        code for increment equal to 1
c
   20 do 30 i = 1,n
        cx(i) = ca*cx(i)
   30 continue
      return
      end

      SUBROUTINE CGERU ( M, N, ALPHA, X, INCX, Y, INCY, A, LDA )
*     .. Scalar Arguments ..
      COMPLEX            ALPHA
      INTEGER            INCX, INCY, LDA, M, N
*     .. Array Arguments ..
      COMPLEX            A( LDA, * ), X( * ), Y( * )
*     ..
*
*  Purpose
*  =======
*
*  CGERU  performs the rank 1 operation
*
*     A := alpha*x*y' + A,
*
*  where alpha is a scalar, x is an m element vector, y is an n element
*  vector and A is an m by n matrix.
*
*  Parameters
*  ==========
*
*  M      - INTEGER.
*           On entry, M specifies the number of rows of the matrix A.
*           M must be at least zero.
*           Unchanged on exit.
*
*  N      - INTEGER.
*           On entry, N specifies the number of columns of the matrix A.
*           N must be at least zero.
*           Unchanged on exit.
*
*  ALPHA  - COMPLEX         .
*           On entry, ALPHA specifies the scalar alpha.
*           Unchanged on exit.
*
*  X      - COMPLEX          array of dimension at least
*           ( 1 + ( m - 1 )*abs( INCX ) ).
*           Before entry, the incremented array X must contain the m
*           element vector x.
*           Unchanged on exit.
*
*  INCX   - INTEGER.
*           On entry, INCX specifies the increment for the elements of
*           X. INCX must not be zero.
*           Unchanged on exit.
*
*  Y      - COMPLEX          array of dimension at least
*           ( 1 + ( n - 1 )*abs( INCY ) ).
*           Before entry, the incremented array Y must contain the n
*           element vector y.
*           Unchanged on exit.
*
*  INCY   - INTEGER.
*           On entry, INCY specifies the increment for the elements of
*           Y. INCY must not be zero.
*           Unchanged on exit.
*
*  A      - COMPLEX          array of DIMENSION ( LDA, n ).
*           Before entry, the leading m by n part of the array A must
*           contain the matrix of coefficients. On exit, A is
*           overwritten by the updated matrix.
*
*  LDA    - INTEGER.
*           On entry, LDA specifies the first dimension of A as declared
*           in the calling (sub) program. LDA must be at least
*           max( 1, m ).
*           Unchanged on exit.
*
*
*  Level 2 Blas routine.
*
*  -- Written on 22-October-1986.
*     Jack Dongarra, Argonne National Lab.
*     Jeremy Du Croz, Nag Central Office.
*     Sven Hammarling, Nag Central Office.
*     Richard Hanson, Sandia National Labs.
*
*
*     .. Parameters ..
      COMPLEX            ZERO
      PARAMETER        ( ZERO = ( 0.0E+0, 0.0E+0 ) )
*     .. Local Scalars ..
      COMPLEX            TEMP
      INTEGER            I, INFO, IX, J, JY, KX
*     .. External Subroutines ..
      EXTERNAL           XERBLA
*     .. Intrinsic Functions ..
      INTRINSIC          MAX
*     ..
*     .. Executable Statements ..
*
*     Test the input parameters.
*
      INFO = 0
      IF     ( M.LT.0 )THEN
         INFO = 1
      ELSE IF( N.LT.0 )THEN
         INFO = 2
      ELSE IF( INCX.EQ.0 )THEN
         INFO = 5
      ELSE IF( INCY.EQ.0 )THEN
         INFO = 7
      ELSE IF( LDA.LT.MAX( 1, M ) )THEN
         INFO = 9
      END IF
      IF( INFO.NE.0 )THEN
         CALL XERBLA( 'CGERU ', INFO )
         RETURN
      END IF
*
*     Quick return if possible.
*
      IF( ( M.EQ.0 ).OR.( N.EQ.0 ).OR.( ALPHA.EQ.ZERO ) )
     $   RETURN
*
*     Start the operations. In this version the elements of A are
*     accessed sequentially with one pass through A.
*
      IF( INCY.GT.0 )THEN
         JY = 1
      ELSE
         JY = 1 - ( N - 1 )*INCY
      END IF
      IF( INCX.EQ.1 )THEN
         DO 20, J = 1, N
            IF( Y( JY ).NE.ZERO )THEN
               TEMP = ALPHA*Y( JY )
               DO 10, I = 1, M
                  A( I, J ) = A( I, J ) + X( I )*TEMP
   10          CONTINUE
            END IF
            JY = JY + INCY
   20    CONTINUE
      ELSE
         IF( INCX.GT.0 )THEN
            KX = 1
         ELSE
            KX = 1 - ( M - 1 )*INCX
         END IF
         DO 40, J = 1, N
            IF( Y( JY ).NE.ZERO )THEN
               TEMP = ALPHA*Y( JY )
               IX   = KX
               DO 30, I = 1, M
                  A( I, J ) = A( I, J ) + X( IX )*TEMP
                  IX        = IX        + INCX
   30          CONTINUE
            END IF
            JY = JY + INCY
   40    CONTINUE
      END IF
*
      RETURN
*
*     End of CGERU .
*
      END

c      include  'korel.chb'
CC      INCLUDE  'phg.f'

C   PHG (version for SUN):
      SUBROUTINE PHGINI(I)
CMS      INCLUDE 'FGRAPH.FD'
CMS      INTEGER*2 DUMMY
      INTEGER*2 MGX,MGY,MTX,MTY
c      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,IOUT,IX0,IY0
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
CMS      RECORD /VIDEOCONFIG/SCREEN
      COMMON /PHG/MGX,MGY,MTX,MTY
      COMMON SCREEN
      IOUT=I
CMS      CALL GETVIDEOCONFIG(SCREEN)
CMS      SELECT CASE(SCREEN.ADAPTER)
CMS      CASE($CGA,$OCGA)
CMS      DUMMY=SETVIDEOMODE($MRES4COLOR)
CMS      CASE($EGA,$OEGA)
CMS      DUMMY=SETVIDEOMODE($ERESCOLOR)
CMS      CASE($VGA,$OVGA)
CMS      DUMMY=SETVIDEOMODE($VRES16COLOR)
CMS      CASE DEFAULT
CMS      DUMMY=0
CMS      END SELECT
CMS      CALL GETVIDEOCONFIG(SCREEN)
C      IF(DUMMY.EQ.0) WRITE(*,*)
C     /' THIS PROGRAM REQUIRES A CGA, EGA, OR VGA GRAPHICS CARD.'
CMS      CALL CLEARSCREEN($GCLEARSCREEN)
CMS      MGX=SCREEN.NUMXPIXELS
CMS      MGY=SCREEN.NUMYPIXELS
CMS      MTX=SCREEN.NUMTEXTCOLS
CMS      MTY=SCREEN.NUMTEXTROWS
      IF(IOUT.LE.0) RETURN
C   iout=1 =>HPGL, iout=2 => PS
      OPEN(3,FILE='phg.out',status='unknown')
      if(iout.eq.1)then
       OPEN(3,FILE='phg.out',status='unknown')
       WRITE(3,50)
      endif
      if(iout.eq.2)then
       OPEN(3,FILE='phg.ps',status='unknown')
       WRITE(3,51)
      endif
   50 FORMAT('SP1;')
   51 FORMAT('%! PS-output by PHG fortran-package'/
     /'%%BoundingBox:-10 -10 510 510'/
     /'/l {lineto} def'/
     /'/m {moveto} def'/
     /'/sc {setrgbcolor} def'/
     /'/s {stroke} def'/
     /'/w {setlinewidth} def')
      RETURN
      END

      SUBROUTINE PHGEND
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
      if(iout.eq.2)WRITE(3,50)
   50 FORMAT('s'/'showpage'/'end')
      CLOSE(3)
      RETURN
      END

      SUBROUTINE PHGLIM(XMI,YMI,XMA,YMA)
CMS      INCLUDE 'FGRAPH.FD'
CMS      INTEGER*2 DUMMY
      INTEGER*2 MGX,MGY,MTX,MTY
      REAL*8 XMI,YMI,XMA,YMA
      COMMON /PHG/MGX,MGY,MTX,MTY
c      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,IOUT,IX0,IY0
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
CMS      CALL SETVIEWPORT(0,0,MGX,MGY)
CMS      CALL SETTEXTWINDOW(1,1,MTX,MTY)
C      DUMMY = SETWINDOW(.FALSE.,XMI,YMI,XMA,YMA)
CMS      DUMMY = SETWINDOW(.TRUE.,XMI,YMI,XMA,YMA)
CMS      DUMMY = RECTANGLE($GBORDER,0,0,MGX-1,MGY-1)
C      IF(IOUT.LE.0)RETURN
c      IX0=0
c      IY0=0
      x01=xmi-1.
      y01=ymi-1.
      X0=(XMA+XMI)/2.D0
      Y0=(YMA+YMI)/2.D0
      SC=19998.
      if(iout.eq.2)then
       sc=500.
       x0=xmi
       y0=ymi
      endif
      SCX=sc/(XMA-XMI)
      SCY=sc/(YMA-YMI)
      RETURN
      END

      SUBROUTINE PHGLIN(X1,Y1,X2,Y2,I)
CMS      INCLUDE 'FGRAPH.FD'
CMS      INTEGER*2 DUMMY
      INTEGER*2 I2
      REAL*8 X1,Y1,X2,Y2
c      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,IOUT,IX0,IY0
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
CMS      RECORD /WXYCOORD/WXY
      I2=I
CMS      DUMMY = SETCOLOR(I2)
CMS      CALL MOVETO_W(X1,Y1,WXY)
CMS      DUMMY = LINETO_W(X2,Y2)
      IF(IOUT.LE.0)RETURN
      x10=x1
      y10=y1
      if(iout.eq.1)then
       IX1=(X1-X0)*SCX
       IY1=(Y1-Y0)*SCY
       IF(X10.NE.X01.OR.Y10.NE.Y01) WRITE(3,51)IX1,IY1
       IX1=(X2-X0)*SCX
       IY1=(Y2-Y0)*SCY
       WRITE(3,52)IX1,IY1
      endif
      if(iout.eq.2)then
       IF(X10.NE.X01.OR.Y10.NE.Y01) then
        if(i.eq.1)write(3,55)
        if(i.gt.1)write(3,56)
        WRITE(3,53)(X1-X0)*scx,(Y1-Y0)*scy
c        WRITE(3,54)(X1-X0)*scx,(Y1-Y0)*scy
       endif
       WRITE(3,54)(X2-X0)*scx,(Y2-Y0)*scy
      endif
      X01=X2
      Y01=Y2
   51 FORMAT('PU;PA',I5,',',I5,';')
   52 FORMAT('PD;PA',I5,',',I5,';')
   53 format(f6.2,1x,f6.2,' m')
   54 format(f6.2,1x,f6.2,' l')
   55 format('s'/' 0.2 w')
   56 format('s'/' 0.6 w')
C   51 FORMAT('MA ',2F7.3)
C   52 FORMAT('PA ',2F7.3)
      RETURN
      END

      SUBROUTINE PHGVEC(X1,Y1,X2,Y2,XV,FIV,I)
CMS      INCLUDE 'FGRAPH.FD'
CMS      INTEGER*2 DUMMY
      INTEGER*2 I2
      REAL*8 X1,Y1,X2,Y2,XV,FIV,CF,SF,X3,Y3,XV0
c      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,IOUT,IX0,IY0
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
CMS      RECORD /WXYCOORD/WXY
      I2=I
CMS      DUMMY=SETCOLOR(I2)
CMS      CALL MOVETO_W(X1,Y1,WXY)
CMS      DUMMY=LINETO_W(X2,Y2)
      XV0=XV/DSQRT((X1-X2)**2+(Y1-Y2)**2)
      CF=XV0*DCOS(FIV*3.14159265358979D0/180.D0)
      SF=XV0*DSIN(FIV*3.14159265358979D0/180.D0)
      X3=X2+CF*(X1-X2)+SF*(Y1-Y2)
      Y3=Y2-SF*(X1-X2)+CF*(Y1-Y2)
      call phglin(x1,y1,x2,y2,i)
      call phglin(x2,y2,x3,y3,i)
      X3=X3-2.D0*SF*(Y1-Y2)
      Y3=Y3+2.D0*SF*(X1-X2)
      call phglin(x2,y2,x3,y3,i)
      RETURN
      END

      SUBROUTINE LIN3(X,N,IC)
      REAL*8 DX1,DX2,DY1,DY2
      DIMENSION X(3,N)
c      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,IOUT,IX0,IY0
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
      CB=COS(BET)
      SB=SIN(BET)
      CA=COS(ALF)
      SA=SIN(ALF)
      DX2=(X(1,1)*CB+X(2,1)*SB)
      DY2=(X(2,1)*CB-X(1,1)*SB)*SA+X(3,1)*CA
      DO 100 I=2,N
      DX1=DX2
      DY1=DY2
      DX2=(X(1,I)*CB+X(2,I)*SB)
      DY2=(X(2,I)*CB-X(1,I)*SB)*SA+X(3,I)*CA
      CALL PHGLIN(DX1,DY1,DX2,DY2,IC)
  100 CONTINUE
      RETURN
      END

      SUBROUTINE VEC3(X,N,XV,FIV,IC)
      REAL*8 DX1,DX2,DY1,DY2,XV,FIV
      DIMENSION X(3,N)
c      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,IOUT,IX0,IY0
      COMMON/PROJ/ALF,BET,SCX,SCY,X0,Y0,X01,Y01,IOUT
      CB=COS(BET)
      SB=SIN(BET)
      CA=COS(ALF)
      SA=SIN(ALF)
      DX2=(X(1,1)*CB+X(2,1)*SB)
      DY2=(X(2,1)*CB-X(1,1)*SB)*SA+X(3,1)*CA
      IF(N.LE.2)GOTO 101
      N1=N-1
      DO 100 I=2,N1
      DX1=DX2
      DY1=DY2
      DX2=(X(1,I)*CB+X(2,I)*SB)
      DY2=(X(2,I)*CB-X(1,I)*SB)*SA+X(3,I)*CA
      CALL PHGLIN(DX1,DY1,DX2,DY2,IC)
  100 CONTINUE
  101 DX1=DX2
      DY1=DY2
      DX2=(X(1,N)*CB+X(2,N)*SB)
      DY2=(X(2,N)*CB-X(1,N)*SB)*SA+X(3,N)*CA
      CALL PHGVEC(DX1,DY1,DX2,DY2,XV,FIV,IC)
      RETURN
      END

      subroutine stup(x1,x2,dx1,dx2,x01,x02)
      implicit real*8 (a-h,o-z)
      dx=dlog10(x2-x1)
      ldx=dx
      if(dx.lt.0.)ldx=ldx-1
      dx1=10.d0**ldx
      nx=(x2-x1)/dx1
      if(nx.ge.5)dx2=dx1/2.d0
      if(nx.ge.2.and.nx.lt.5)dx2=dx1/5.d0
      if(nx.lt.2)then
       dx2=dx1/10.
       dx1=dx1/2.
      endif
      n0=x1/dx1
      if(x1.gt.0.)n0=n0+1
      x01=dx1*n0
      n0=x1/dx2
      if(x1.gt.0.)n0=n0+1
      x02=dx2*n0
      return
      end

      function deltr(x,vs,us,r2,i)
c podprogram na rotacni rozsireni
      implicit real*8 (a-h,o-z)
      del=0.d0
      if(x.le.-1.d0.or.x.ge.1.d0)return
      a=dsqrt(1.d0-x*x)
      del=2.d0*uint(a,a,i)
      if(dabs(x-vs).ge.r2)return
      du=dsqrt(r2*r2-(x-vs)**2)
      if(us-du.ge.a.or.us+du+a.le.0.d0)return
      if(us+du.ge.a)then
       if(us-du+a.le.0.d0)then
        del=0.d0
       else
        del=0.5d0*del+uint(us-du,a,i)
       endif
      else
       if(us-du+a.le.0.d0)then
        del=0.5d0*del-uint(us+du,a,i)
       else
        del=del-uint(us+du,a,i)+uint(us-du,a,i)
       endif
      endif
      return
      end

      function uint(u,a,i)
c  pomocna pro deltr
      implicit real*8 (a-h,o-z)
      uint=u
      if(i.eq.0)return
      uint=0.5d0*(u*dsqrt(a*a-u*u)+a*a*dasin(u/a))
      return
      end


      doublecomplex function delta(y,j,l,model)
      implicit real*8 (a-h,o-z)
      include 'korelpar.f'
c      dimension ipiv(5)
c      complex a(5,5),b(5)
c      complex*16 c(5,nsp),c1(5,nsp),p1
      common/param/param(5,7),kodp(5)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/t/t(nsp),w(nsp),vr(5,nsp),dvr(5,nsp),sp(npx2,nsp),
     /fsp(npx2,nsp),fsv(npx2,mnsu),s(5,nsp),ds(5,nsp),us(2,mnu),
     /iu(nsp),ivj(5)
      data pi/3.14159265358979323d0/
      nsu=ns*nu
c      m1=m-1
c      theta=-12.56637061435917292d0/dfloat(ndf)
      if(model.gt.0)goto 1
c posunuta delta-funkce
      thlj=idint(dabs(vr(j,l))+.5d0)
      if(vr(j,l).lt.0.)thlj=-thlj
      dvrjl=thlj-vr(j,l)
      thlj=y*thlj
      delta=cmplx(dcos(thlj),dsin(thlj))
c zpresneni pod rozliseni pixelu
      delta=delta*cmplx(1.d0+dvrjl**2*(dcos(y)-1.d0),-dvrjl*dsin(y))
      return
    1 if(model.gt.1)goto 2
c pulzace lin. - neudelane
Cc d/dv [exp(iyv)(1-iyv)-1]/y^2=v exp(iyv)
Cc [exp(iyv)(1-iyv)-1]/y^2= cos(yv)+yv sin(yv)-1+isin(yv)-iyvcos(yv)
C      if(i.le.ndf2+2) then
C      if(y.eq.0.) then
C       fp1(i)=0.5
C       fp2(i)=1.d0
C      else
      z=y*vr(j,l)
      if(dabs(z).le.1.d-9) then
       delta=cmplx(1.d0,0.d0)
      else
       deltar=2.d0*(dcos(z)+z*dsin(z)-1.d0)/(z)**2
       deltai=2.d0*(dsin(z)-z*dcos(z))/(z)**2
C     /   -z*dcos(z))/(z)**2)
C       fp1(ndf+2-i)=1.d0-fp1(i)
C       fp2(ndf+2-i)=fp2(i)
C       if(i.eq.ndf2+1)fp1(i)=0.5d0
C      endif
       delta=cmplx(deltar,deltai)
      endif
      return
    2 if(model.gt.2)goto 3
c pulzace kvadr. - neudelane
Cc d/dv [exp(iyv)(2i+2yv-iy^2v^2)-2i]/y^3=v^2 exp(iyv)
Cc pulzacni rozsireni: [exp(iyv)(2i+2yv-iy^2v^2)-2i]/y^3=
Cc [icos(yv)(2-y^2v^2)+2iyv sin(yv)-2i+
Cc   -sin(yv)(2-y^2v^2)+2yv cos(yv)]/y^3
      z=y*vr(j,l)
c      nsigy=(y/pi+0.d0)
      if(dabs(z).le.1.d-9) then
       delta=cmplx(1.d0,0.d0)
      else
C       z=2.d0*pi*y*x0
c        z=y*vr(j,l)
c         if(l.eq.5)write(2,*)y,z
       deltai=3.d0*(dcos(z)*(2.d0-(z)**2)+2.d0*z*dsin(z)-2.d0)/(z)**3
       deltar=3.d0*(-dsin(z)*(2.d0-(z)**2)+2.d0*z*dcos(z))/(z)**3
C       fp1(ndf+2-i)=-fp1(i)
C       fp2(ndf+2-i)=fp2(i)
C       if(i.eq.ndf2+1)fp1(i)=0.5d0
c       if(dabs(y)-3.14159265358979d0.lt.1.d-9) then
        delta=cmplx(deltar,deltai)
c       else
c        delta=cmplx(deltar,-deltai)
c       endif
      endif
c      if(l.eq.1)write(2,*)y,delta
      return
c rotacni efekt - neudelane
    3 continue
      delta=cmplx(1.d0,0.d0)
      return
      end

      subroutine maper
      implicit real*8 (a-h,o-z)
      dimension pom(21)
      common/el/el(4,15),del(4,15),ix(3,10),rvpb,ks,ns,nu,me,
     /ifil,ndf,key(15)
      common/er/er(3,4,15)
      open(8,file='korermap.dat')
      do 1 i=1,4
      do 1 j=1,15
    1 er(1,i,j)=el(i,j)
      do 4 iy=1,21
      py=0.1d0*dfloat(iy)-1.1d0
      do 3 i1=1,21
      px=0.1d0*dfloat(i1)-1.1d0
      do 2 i=1,4
      do 2 j=1,15
      el(i,j)=er(1,i,j)+px*er(2,i,j)+py*er(3,i,j)
    2 call rv
      pom(i1)=scoef(ndf)
      if(iy.eq.1.and.i1.eq.1) then
       iym=1
       ixm=1
       pmin=pom(i1)
      else
       if(pom(i1).lt.pmin) then
        iym=iy
        ixm=i1
        pmin=pom(i1)
       endif
      endif
    3 continue
    4 write(8,50)pom
      do 5 i=1,4
      do 5 j=1,15
    5 el(i,j)=er(1,i,j)
      write(2,51)ixm,iym,pmin
      px=0.1d0*dfloat(ixm)-1.1d0
      py=0.1d0*dfloat(iym)-1.1d0
      do 6 i=1,4
      do 6 j=1,15
      if(er(2,i,j).ne.0.0.or.er(3,i,j).ne.0.0)
     / write(2,52) i,j,er(1,i,j)+px*er(2,i,j)+py*er(3,i,j),
     /er(1,i,j)-er(2,i,j)-er(3,i,j),er(1,i,j)-er(2,i,j)+er(3,i,j),
     /er(1,i,j)+er(2,i,j)-er(3,i,j)
    6 continue
   50 format(21e11.4)
   51 format(' Minimum error p(',i2,',',i2,')=',e12.6)
   52 format(' el(',i2,',',i2,')=',e12.6,' er(1.1):',e12.6,' er(1.21):'
     /,e12.6,' er(21,1):',e12.6)
      return
      end
