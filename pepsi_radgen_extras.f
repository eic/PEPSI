! A collection of routines needed by RADGEN
 
!---------------------------------------------------------------
! Calculate the F2 structure function

        subroutine mkf2 (DQ2,DX,A,Z,DF2,DF1)

        implicit none
        include "leptou.inc"
        include "mc_set.inc"

        double precision dQ2, dx, dF2, dF1
        DOUBLE PRECISION F2ALLM, DNP(5), DF2NF2P, DRATIO, DR
        DOUBLE PRECISION DISOC,  DHE3D(6), DHE4D(6)
        DOUBLE PRECISION gamma2, dnu, dw2, pmass2
        integer A, Z, iflavour
        real xpq(-6:6), xdpq(-6:6)
! ... charge of quark flavours; 2nd index is 1:proton, 2:neutron
! ... (effective isospin rotation for neutron)
        real qflavour(6,2)
        save qflavour
        data qflavour/1.,2.,1.,2.,1.,2.,
     +                2.,1.,1.,2.,1.,2./
C parameters for ratio F2(n)/F2(p)
C measured at NMC, (NMC Amaudruz et al. CERN-PPE/91-167))
        data DNP   / 0.976D0,    -1.34D0,      1.319D0,
     &              -2.133D0,     1.533D0/
C fit to latest result from Taeksu (he3d2_shin280498.fitpar)
C to be corrected for non isoscalarity !
        DATA DHE3D / 0.98733D0,   0.50409D0,  -0.22521D0,
     &              -0.66976D2,  -0.62318D0,   0.12104D1/

C parameters for ratio F2(4He)/F2(d), not corrected for isoscalarity
C fit to NMC+SLAC data (hed2_03.fitpar) - abr
        DATA DHE4D / 0.1051D1,   -0.1896D0,   -0.1026D0,
     &              -0.1704D2,    0.3086D0 ,   0.8509D1/
    
       pmass2=massp**2

       IF(genSet_FStruct(1:4).EQ.'ALLM') THEN
        if ((A.eq.1).and.(Z.eq.1)) then
           DF2=F2ALLM(dx,dq2)
        endif

        if ((A.eq.2).and.(Z.eq.1)) then
           DF2=F2ALLM(dx,dq2)
           DF2NF2P=DNP(1)+dx*(DNP(2)+dx*(DNP(3)+dx*(DNP(4)+dx*DNP(5))))
           DF2=DF2*0.5*(df2nf2p+1.)
        endif

        if ((A.eq.3).and.(Z.eq.2)) then
C...F2-deut(from F2-proton(ALLM) and F2n/F2p)*(He-3/F2-deut.)-Ratio:
           DF2=F2ALLM(dx,dq2)   
           DF2NF2P=DNP(1)+dx*(DNP(2)+dx*(DNP(3)+dx*(DNP(4)+dx*DNP(5))))
           DF2=DF2*0.5*(df2nf2p+1.)
           DRATIO = DHE3D(1) + DHE3D(2)*dx + DHE3D(3)*exp(DHE3D(4)*dx)
     &            + DHE3D(5)*dx**DHE3D(6)
C          undo isoscalarity correction
           DISOC=((A-Z)*DF2NF2P+Z)/(0.5*A*(1+DF2NF2P))
           DF2=DF2*DRATIO*DISOC
        endif

        if ((A.eq.4).and.(Z.eq.2)) then
C...F2-deut(from F2-proton(ALLM) and F2n/F2p)*(F2-4He/F2-deut)-Ratio
           DF2=F2ALLM(dx,dq2) 
           DF2NF2P=DNP(1)+dx*(DNP(2)+dx*(DNP(3)+dx*(DNP(4)+dx*DNP(5))))
           DF2=DF2*0.5*(df2nf2p+1.)
           DRATIO = DHE4D(1) + DHE4D(2)*dx + DHE4D(3)*exp(DHE4D(4)*dx)
     &            + DHE4D(5)*dx**DHE4D(6)
           DF2=DF2*DRATIO
        endif
       ENDIF

       IF (genSet_FStruct(1:3).EQ.'PDF') THEN
          call parton(real(x),real(q2),xpq,xdpq)
          df2 = 0.
C! ... for the moment assume sum over pdfs is F1 this neglects R
          do iflavour = 1, 6
             df2 = df2 + (z*(qflavour(iflavour,1)**2)/9.
     +                 + (a-z)*(qflavour(iflavour,2)**2)/9. )
     +               *((xpq(iflavour)/dx)+(xpq(-iflavour)/dx))
          enddo
       ENDIF

          Call MKR(DQ2,DX,DR)
          dw2=pmass2+dq2*(1-dx)/dx
          dnu=(dw2-pmass2+dq2)/(2.*massp)
          gamma2=dq2/(dnu**2)
          DF1=(1.D0+gamma2)/(2.D0*dx)/(1.D0+DR)*DF2

        return
        end

!---------------------------------------------------------------
! Calculate R = sigma_L/sigma_T

      SUBROUTINE MKR(DQ2,DX,DR)
      IMPLICIT NONE
      include "mc_set.inc"

      DOUBLE PRECISION DQ2, DX
      DOUBLE PRECISION DR,DELTAR

      IF ( genSet_R .EQ. '1990' ) THEN
*        Whitlow et al.,  Phys.Lett.B 250(1990),193
         CALL R1990(DQ2,DX,DR,DELTAR)
      ELSE IF ( genSet_R .EQ. '1998' ) THEN
*        E143, hep-ex/9808028
         CALL R1998(DQ2,DX,DR,DELTAR)
      ELSE IF ( genSet_R .eq. '0' ) THEN
* pure transverse (sigma_L=0)
         DR = 0.d0
      ELSE
         write(*,*)( 'MKR: invalid choice for R parametrization' )
      ENDIF

      RETURN
      END

C------------------------------------------------------------------

      SUBROUTINE R1990(DQ2,DX,DR,DELTAR)

      IMPLICIT NONE

      DOUBLE PRECISION DQ2, DX
      DOUBLE PRECISION DR, DELTAR

      REAL R
      REAL QQ35, XX
      REAL FAC, RLOG, Q2THR
      REAL R_A, R_B, R_C
C
C Data-Definition of R-Calculation, see
C            L.W.WHITLOW, SLAC-REPORT-357,
C            PH.D. THESIS, STANFORD UNIVERSITY,
C            MARCH 1990.
      REAL AR1990(3), BR1990(3), CR1990(3)
      DATA AR1990  / .06723, .46714, 1.89794 /
      DATA BR1990  / .06347, .57468, -.35342 /
      DATA CR1990  / .05992, .50885, 2.10807 /

      DELTAR = 0.

      XX=real(DX)
      IF (DQ2.LT.0.35) THEN
        QQ35=0.35
      ELSE
        QQ35=real(DQ2)
      ENDIF
C
C *** If Q2 < 0.35 then variable "R" is calculated at the fixed Q2 of 0.35
C
      FAC   = 1+12.*(QQ35/(1.+QQ35))*(.125**2/(XX**2+.125**2))
      RLOG  = FAC/LOG(QQ35/.04)
      Q2THR = 5.*(1.-XX)**5

      R_A   = AR1990(1)*RLOG +
     &        AR1990(2)/SQRT(SQRT(QQ35**4+AR1990(3)**4))
      R_B   = BR1990(1)*RLOG +
     &        BR1990(2)/QQ35 + BR1990(3)/(QQ35**2+.3**2)
      R_C   = CR1990(1)*RLOG +
     &        CR1990(2)/SQRT((QQ35-Q2THR)**2+CR1990(3)**2)
      R     = (R_A+R_B+R_C)/3.

      IF (DQ2.GE.0.35) THEN
        DR=dble(R)
      ELSE
        DR=dble(R)*DQ2/0.35
      ENDIF

c      print*,'R:',R
      
      END

C-----------------------------------------------------------------------
      SUBROUTINE R1998(DQ2,DX,DR,DELTAR)

C new fit to R  hep-ex/9808028 E143 Collab.
C it is based on the old 3 paramter forms
C 0.005<x<0.86, 0.5<Q2<130 GeV2
C E143 x-section measurement 0.03<x<0.4
C with  overall norm uncertainty 2.5%
C
C U. Stoesslein, October 1998
C

      IMPLICIT NONE

      DOUBLE PRECISION DQ2,DX,DR,DELTAR
      DOUBLE PRECISION Q2,Q2MAX,FAC,RLOG,Q2THR
      DOUBLE PRECISION R_A_NEW,R_A,R_B_NEW,R_B,R_C

      DOUBLE PRECISION A(6),B(6),C(6)

      DATA A/ .0485, 0.5470, 2.0621, -.3804,  0.5090, -.0285/
      DATA B/ .0481, 0.6114, -.3509, -.4611,  0.7172, -.0317/
      DATA C/ .0577, 0.4644, 1.8288,12.3708,-43.1043,41.7415/ 

      DOUBLE PRECISION DR1998
      EXTERNAL DR1998

* use R(0.35) if q2 is below 0.35
      Q2=DQ2
      Q2MAX=0.35
      IF(Q2.LT.Q2MAX) Q2=Q2MAX

      FAC   = 1+12.*(Q2/(1.+Q2))*(.125**2/(DX**2+.125**2))
      RLOG  = FAC/LOG(Q2/.04)
      Q2thr = C(4)*DX+C(5)*DX*DX+C(6)*DX*DX*DX

* new additional terms
      R_A_NEW = (1.+A(4)*DX+A(5)*DX*DX)*DX**(A(6))
      R_A   = A(1)*RLOG + A(2)/SQRT(SQRT(Q2**4+A(3)**4))*R_A_NEW
      R_B_NEW = (1.+B(4)*DX+B(5)*DX*DX)*DX**(B(6))
      R_B   = B(1)*RLOG + (B(2)/Q2 + B(3)/(Q2**2+0.3**2))*R_B_NEW
      R_C   = C(1)*RLOG + C(2)/SQRT((Q2-Q2thr)**2+C(3)**2)
      DR    = (R_A+R_B+R_C)/3.

* straight line fit extrapolation to R(Q2=0)=0
      if (dq2.lt.q2max) DR = DR*DQ2/Q2MAX

* I assume the fit uncertainty only for measured Q2 range
      if (Q2 .GT. 0.5) then
         DELTAR = DR1998(DX,Q2)
      else
         DELTAR=DR
      endif

      RETURN
      END

C--------------------------------------------------------------------
      DOUBLE PRECISION FUNCTION DR1998(DX,DQ2)

* Parameterize uncertainty in R1998 
* associated to the fitting procedure only

      IMPLICIT NONE
      DOUBLE PRECISION DX,DQ2

      DR1998 = 0.0078-0.013*DX+(0.070-0.39*DX+0.7*DX*DX)/(1.7+DQ2)

      RETURN
      END

!---------------------------------------------------------------
! Calculate the asymmetries A1 and A2

        subroutine mkasym (dQ2, dX, A, Z, dA1, dA2)

        implicit none
        include "leptou.inc"

        double precision dQ2, dx, dA1, dA2, df1, df2
        double precision DPPAR, DDPAR, massp, pmass2
        integer A, Z, iflavour
        real xpq(-6:6), xdpq(-6:6), g1
! ... charge of quark flavours; 2nd index is 1:proton, 2:neutron
! ... (effective isospin rotation for neutron)
        real qflavour(6,2)
        save qflavour
        data qflavour/1.,2.,1.,2.,1.,2.,
     +                2.,1.,1.,2.,1.,2./

        massp=0.938272013
        pmass2=massp**2
        DPPAR=0.53
        DDPAR=0.22

        if (lst(15).le.100) then
          da1 = 0.D0
          da2 = 0.D0
          return
        endif

        call mkf2(dq2, dx, A, Z, dF2, dF1)

        call parton(real(x),real(q2),xpq,xdpq)
        g1 = 0.
        do iflavour = 1, 6
          g1 = g1 + (z*(qflavour(iflavour,1)**2)/9.
     +            + (a-z)*(qflavour(iflavour,2)**2)/9. )
     +        *((xdpq(iflavour)/dx)+(xdpq(-iflavour)/dx))
        enddo

        da1 = dble(g1)/dF1
      
C        if (1.le.dQ2.and.dQ2.le.1.5) then
C           write(*,*)'In mkasym', dq2, dx, da1, g1, f1
C        endif 

        IF(A.EQ.1.and.Z.eq.1) THEN
           da2=dPPAR*MASSP*DX/(sqrt(DQ2))
        ELSEIF(A.EQ.2.and.Z.eq.1) THEN
           da2=dDPAR*MASSP*DX/(sqrt(DQ2))
        ELSEIF(A.EQ.1.and.Z.eq.0) THEN
           da2=(dDPAR-dPPAR)*MASSP*DX/(sqrt(DQ2))
        ELSE
           da2 = 0.D0
        ENDIF

        return
        end

!---------------------------------------------------------------
! Calculate the dilution factor

        subroutine fdilut (dQ2, dx, A, DF)

        implicit none

        DOUBLE PRECISION DQ2, DX, DF
        DOUBLE PRECISION DNP, DFN, DFP
        DOUBLE PRECISION DZ, DF2NF2P
        INTEGER A
        dimension dnp(7)
*        
C ... fit to NMC  F2n/F2p data (86/87+89 T1,T14)
        data dnp/
     +   0.67225D+00,
     +   0.16254D+01,
     +  -0.15436D+00,
     +   0.48301D-01,
     +   0.41979D+00,
     +   0.47331D-01,
     +  -0.17816D+00/

! Definitions of 'intrinsic' dilutions for neutron and proton (GNOME confused)

        dfn=1.
        dfp=1.

! Only 3He has a dilution, and we determine it as F2n/(2*F2p + F2n)

        if (A.ne.3) then
          df = 1.
        else
          dZ = 1./2.*DLOG(1.+DEXP(2.0-1000.*dX))
          df2nf2p = dnp(1)*(1.0-dx)**dnp(2)+dnp(3)*dx**dnp(4)
     1            +(dnp(5)+dnp(6)*dz+dnp(7)*dz**2)
          df = dfn*(1./((2./df2nf2p)+1))
        endif

        return

        END

!---------------------------------------------------------------
! Function to calculate F2 from ALLM parametrisation

      double precision FUNCTION f2allm(x,q2)

      implicit double precision (a-h,o-z)

      REAL M02,M12,LAM2,M22
      COMMON/ALLM/SP,AP,BP,SR,AR,BR,S,XP,XR,F2P,F2R
C  POMERON
      PARAMETER (
     , S11   =   0.28067, S12   =   0.22291, S13   =   2.1979,
     , A11   =  -0.0808 , A12   =  -0.44812, A13   =   1.1709,
     , B11   =   0.60243**2, B12   =   1.3754**2, B13   =   1.8439,
     , M12   =  49.457 )
 
C  REGGEON
      PARAMETER (
     , S21   =   0.80107, S22   =   0.97307, S23   =   3.4942,
     , A21   =   0.58400, A22   =   0.37888, A23   =   2.6063,
     , B21   =   0.10711**2, B22   =   1.9386**2, B23   =   0.49338,
     , M22   =   0.15052 )
C
      PARAMETER ( M02=0.31985, LAM2=0.065270, Q02=0.46017 +LAM2 )
      PARAMETER ( ALFA=112.2, XMP2=0.8802)
C                                                                               
      W2=q2*(1./x -1.)+xmp2
      W=dsqrt(w2)
C
      IF(Q2.EQ.0.) THEN 
       S=0.
       Z=1.           
C                                                                               
C   POMERON                                                                     
C                                                                               
       XP=1./(1.+(W2-XMP2)/(Q2+M12))                                   
       AP=A11          
       BP=B11         
       SP=S11        
       F2P=SP*XP**AP                                                
C                                                                               
C   REGGEON                                                                     
C                                                                               
       XR=1./(1.+(W2-XMP2)/(Q2+M22))          
       AR=A21                                 
       BR=B21                                 
       SR=S21
       F2R=SR*XR**AR              
C                                                                               
      ELSE          
       S=DLOG(DLOG((Q2+Q02)/LAM2)/DLOG(Q02/LAM2))                       
       Z=1.-X                                      
C                                                                               
C   POMERON                                                                     
C                                                                               
       XP=1./(1.+(W2-XMP2)/(Q2+M12))                
       AP=A11+(A11-A12)*(1./(1.+S**A13)-1.)         
       BP=B11+B12*S**B13     
       SP=S11+(S11-S12)*(1./(1.+S**S13)-1.)         
       F2P=SP*XP**AP*Z**BP                            
C                                                                               
C   REGGEON                                                                     
C                                                                               
       XR=1./(1.+(W2-XMP2)/(Q2+M22))   
       AR=A21+A22*S**A23              
       BR=B21+B22*S**B23                                                
       SR=S21+S22*S**S23             
       F2R=SR*XR**AR*Z**BR          
    
C                                                                               
      ENDIF

c      CIN=ALFA/(Q2+M02)*(1.+4.*XMP2*Q2/(Q2+W2-XMP2)**2)/Z              
c      SIGal=CIN*(F2P+F2R)                                             
c      f2allm=sigal/alfa*(q2**2*(1.-x))/(q2+4.*xmp2*x**2)
      f2allm = q2/(q2+m02)*(F2P+F2R)

      RETURN                       
      END 
