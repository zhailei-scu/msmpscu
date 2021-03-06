 !**** DESCRIPTION: _______________________________________________________________________________________
 !                  The program is used to analyze the bond distribution of defecter clusters.
 !                  The clutering results generated by Cfg_Track_SIA_GPU will be loaded for the
 !                  configurations of the clusters at difference time.
 !
 !                  SEE ALSO ____________________________________________________________________________
 !                       Cfg_Track_SIA_GPU_Main.F90
 !
 !
 !**** USAGE:       _______________________________________________________________________________________
 !
 !                  DefectCluster_Track.exe -s "filename" -T(est) t1, t2, ts
 !                  where:
 !                        -s filename:          - the pathname of files storing the clustering configurations generated by
 !                                                 Cfg_Track_SIA_GPU.exe
 !                  OPTIONS
 !                        -T(est) t1, t2, ts:   - the range for the tests to be involved in analysis
 !
 !                  ______________________________________________________________________________________
 !**** HISTORY:
 !                  version 1st 2015-11 (Hou Qing, Sichuan university)
 !
 !

 module DefectCluster_BondDis_hcp
 use DefectCluster_Analysis_hcp
 implicit none
 contains

  !**********************************************************************************
   subroutine DefectBondAnalysis()
  !***  DESCRIPTION: to analysis the bond information of clusters. The bond information
  !                  is descirbed in DefectBondInfo_HCP
  !
  !    INPUT:  IB,   the box IDclusters
  !
  !    OUTPUT: BONDS,    the array describing the bonds of the clusters
  !
   implicit none
       !--- dummy variables
       !--- local variables
        integer::IB, I, ICFG, ITIME,  CNUM, SHFIT, ENDFLAG, NBOX, NCFG, FLAG, IC, IC1, IH
        real(KINDDF)::TIME
        type(PartcleClusterList)::Clusters
        integer, dimension(:), allocatable::BondInfo, LSIAnum, VACnum, SIAnum
        integer::LSIA,SIA, bSIA_SIA, bSIA_SIA_C, bSIA_SIA_A, bSIA_SIA_M
        integer::VAC, bSIA_VAC, bSIA_VAC_C, bSIA_VAC_A, bSIA_VAC_M
        integer::     bVAC_VAC, bVAC_VAC_C, bVAC_VAC_A, bVAC_VAC_M

        integer::tLSIA,tSIA, tbSIA_SIA, tbSIA_SIA_C, tbSIA_SIA_A, tbSIA_SIA_M
        integer::tVAC, tbSIA_VAC, tbSIA_VAC_C, tbSIA_VAC_A, tbSIA_VAC_M
        integer::      tbVAC_VAC, tbVAC_VAC_C, tbVAC_VAC_A, tbVAC_VAC_M

       !--- the variable for bond analysis
        integer::rTCNUM0      = 0 !--- number of clusters expected
        integer::rTCNUM       = 0 !--- total number of clusters
        integer::rLSIA        = 0 !--- totoal number of SIA sites
        integer::rSIA         = 0 !--- totoal number of SIAs
        integer::rbSIA_SIA    = 0 !--- total number of SIA-SIA bonds
        integer::rbSIA_SIA_C  = 0 !--- total number of off-plane SIA-SIA bonds
        integer::rbSIA_SIA_A  = 0 !--- total number of in-plane SIA-SIA bonds
        integer::rbSIA_SIA_M  = 0 !--- total number of in-axsis SIA-SIA bonds

        integer::rVAC         = 0 !--- totoal number of VAC
        integer::rbSIA_VAC    = 0 !--- total number of SIA-VAC bonds
        integer::rbSIA_VAC_C  = 0
        integer::rbSIA_VAC_A  = 0
        integer::rbSIA_VAC_M  = 0

        integer::rbVAC_VAC    = 0 !--- total number of VAC-VAC bonds
        integer::rbVAC_VAC_C  = 0
        integer::rbVAC_VAC_A  = 0
        integer::rbVAC_VAC_M  = 0

        !--- the variable for seperation analysis
        integer, dimension(:,:), allocatable::SEP
        integer, parameter::p_SEPHISBINS = 15
        integer, dimension(p_SEPHISBINS)::SEPHIS
        !----
        integer, parameter::VSIZ = 12
        !--- local variables for IO
         integer::hFile, hFIle1, hFile2
         character*256::GFILE
         integer,dimension(:), allocatable::LINE, SEPFLAG
  !-------------


        !--- start analysis
             allocate(LINE(lbound(m_hFILE,dim=1):ubound(m_hFILE,dim=1)),   &
                      SEPFLAG(lbound(m_hFILE,dim=1):ubound(m_hFILE,dim=1))  )
             LINE = 0
             write(*,fmt="(A, I, A, I)") "Start analysis bond information for box ",m_CtrlParam%JOBID0, " to ", m_CtrlParam%JOBID1
             do IB = m_CtrlParam%JOBID0, m_CtrlParam%JOBID1, m_CtrlParam%JOBIDSTEP
                call Start_Load_ClusterCfg(IB, LINE(IB))
             end do

        !--- prepair for output
            !--- for bound analysis
            call GetParentPath(m_CfgPath, GFILE)
            GFILE = GFILE(1:len_trim(GFILE))//"BondAnaly/"
            call CreateDataFolder_Globle_Variables(GFILE)
            GFILE = GFILE(1:len_trim(GFILE))//"MeanBondDistribution"
            call AvailableIOUnit(hFile)
            open(UNIT=hFile, file = GFILE)
            write(hFile, fmt="(A, I8)")    '!--- THE MEAN BOND DISTRIBUTION VS TIME CREATED BY '//gm_ExeName(1:len_trim(gm_ExeName))
            write(hFile, fmt="(A)")        '!    A PROGRAM GENERATED BY THE MD PACKAGE AT SICHUAN UNIVERSITY'
            write(hFile, fmt="(A)")        '!    AUTHOR: HOU Qing'
            write(hFile, fmt="(A)")        '!    '
            write(hFile, fmt="(A, I8)")    '&MEAN_BOND_DIS'
            write(hFile, fmt="(A6,1x, A10, 2x, A12, 2x, 30(1x, A9, 1x))") "&TITLE",        &
                                 "ITIME", "TIME", "CLSNUM", "LSIANUM", "SIANUM", "VACNUM", &
                                 "SIA_SIA", "SIA_SIA_C", "SIA_SIA_A", "SIA_SIA_M",         &
                                 "SIA_VAC", "SIA_VAC_C", "SIA_VAC_A", "SIA_VAC_M",         &
                                 "VAC_VAC", "VAC_VAC_C", "VAC_VAC_A", "VAC_VAC_M"

            !--- for box sepearation
            call GetParentPath(m_CfgPath, GFILE)
            GFILE = GFILE(1:len_trim(GFILE))//"BondAnaly/"
            GFILE = GFILE(1:len_trim(GFILE))//"Cluster_Sepearion"
            call AvailableIOUnit(hFile1)
            open(UNIT=hFile1, file = GFILE)
            write(hFile1, fmt="(A, I8)")    '!--- THE SPEARTION OF CLUSTERS VS TIME CREATED BY '//gm_ExeName(1:len_trim(gm_ExeName))
            write(hFile1, fmt="(A)")        '!    A PROGRAM GENERATED BY THE MD PACKAGE AT SICHUAN UNIVERSITY'
            write(hFile1, fmt="(A)")        '!    AUTHOR: HOU Qing'
            write(hFile1, fmt="(A)")        '!    '
            write(hFile1, fmt="(A, I8)")    '&CLUSTER_SEPN'
            write(hFile1,fmt="(A)")          "!---  SYMBOL EXPLAINATION:"
            write(hFile1,fmt="(A)")          "!     ITIME:        time steps for jumping event occur"
            write(hFile1,fmt="(A)")          "!     TIME:         time (ps) at the time step"
            write(hFile1,fmt="(A)")          "!     CFG#:         corresponding configure ID of the previous reocding"
            write(hFile1,fmt="(A)")          "!     BOX#:         box ID"
            write(hFile2,fmt="(A)")          "!     NUM_CLUST:    number of clusters in the box"
            write(hFile2,fmt="(A)")          "!     SEPEART:      speration between clusters (I,J) for I=1, NUMC-1, J=I+1, NUMC"
            write(hFile1, fmt="(A6,1x, A10, 2x, A12, 2x, 30(1x, A9, 1x))") "&TITLE",        &
                                 "ITIME", "TIME", "CFG#", "BOX#", "NUM_CLUST", "SEPEART"


            call GetParentPath(m_CfgPath, GFILE)
            GFILE = GFILE(1:len_trim(GFILE))//"BondAnaly/"
            GFILE = GFILE(1:len_trim(GFILE))//"Seperation_Hist"
            call AvailableIOUnit(hFile2)
            open(UNIT=hFile2, file = GFILE)
            write(hFile2, fmt="(A, I8)")    '!--- THE SPEARTION HISTOGRAM OF CLUSTERS VS TIME CREATED BY '//gm_ExeName(1:len_trim(gm_ExeName))
            write(hFile2, fmt="(A)")        '!    A PROGRAM GENERATED BY THE MD PACKAGE AT SICHUAN UNIVERSITY'
            write(hFile2, fmt="(A)")        '!    AUTHOR: HOU Qing'
            write(hFile2, fmt="(A)")        '!    '
            write(hFile2, fmt="(A, I8)")    '&SEP_HIST'
            write(hFile2,fmt="(A)")          "!---  SYMBOL EXPLAINATION:"
            write(hFile2,fmt="(A)")          "!     ITIME:        time steps for jumping event occur"
            write(hFile2,fmt="(A)")          "!     TIME:         time (ps) at the time step"
            write(hFile2,fmt="(A)")          "!     BOXNUM:       number of boxes"
            write(hFile2,fmt="(A)")          "!     CLSNUM:       number of clusters"
            write(hFile2,fmt="(A)")          "!     SEP_NUM:      number of non-first neighbor cluster connections"
            write(hFile2,fmt="(A)")          "!     SEP_HIS:      histogram of seperations"

            write(hFile2, fmt="(A6,1x, A10, 2x, A12, 2x, 30(1x, A9, 1x))") "&TITLE",        &
                                 "ITIME", "TIME", "BOXNUM", "CLSNUM", "SEP_NUM", "SEP_HIS"

         !--- do bond analysis
             allocate(BondInfo(VSIZ), LSIAnum(1), SIAnum(1), VACnum(1), SEP(1,1))
             NCFG = 0
             SEPFLAG = 0
             do while(.true.)  !--- loop for time steps
                rTCNUM0     = 0.D0
                rTCNUM      = 0.D0
                rLSIA       = 0.D0
                rSIA        = 0.D0
                rVAC        = 0.D0

                rbSIA_SIA   = 0.D0
                rbSIA_SIA_C = 0.D0
                rbSIA_SIA_A = 0.D0
                rbSIA_SIA_M = 0.D0

                rbSIA_VAC   = 0.D0
                rbSIA_VAC_C = 0.D0
                rbSIA_VAC_A = 0.D0
                rbSIA_VAC_M = 0.D0

                rbVAC_VAC   = 0.D0
                rbVAC_VAC_C = 0.D0
                rbVAC_VAC_A = 0.D0
                rbVAC_VAC_M = 0.D0

                SEPHIS = 0

                ENDFLAG = 0
                NBOX    = 0
                NCFG    = NCFG + 1
                write(*, fmt="(A, I)") "To extract mean bond dis. for configuration", NCFG
                do IB = m_CtrlParam%JOBID0, m_CtrlParam%JOBID1, m_CtrlParam%JOBIDSTEP
                   if(SEPFLAG(IB) .gt. 0) cycle

                   NBOX = NBOX + 1
                   call Load_ClusterCfg(IB, ICFG, ITIME, TIME, LINE(IB), Clusters)

                   !--- determine if have reach the end of cluster sequence
                   if(Clusters%NPRT .eq. 0) then
                       ENDFLAG = ENDFLAG + 1
                       cycle
                   end if
                   !---  to start the ananlysis
                   call NumberPart_PartcleClusters(Clusters, CNUM)
                   if(CNUM .ne. size(SIAnum)) then
                      deallocate(BondInfo, LSIAnum, SIAnum, VACnum, SEP)
                      allocate(BondInfo(CNUM*VSIZ), LSIAnum(CNUM), SIAnum(CNUM), VACnum(CNUM), SEP(CNUM, CNUM))
                   end if
                   call NumberCluster_PartcleClusters(Clusters, CNUM)

                   !--- NOTE: we have filter out the initially seperated cluster
                   !          if we use this program to analyse the caacade clusters
                   !          this part should be deleted
                   if(NCFG .eq. 1) then
                      if(CNUM .gt. 1) SEPFLAG(IB) = 1
                   end if
                   if(SEPFLAG(IB) .gt. 0) cycle
                   !------


                   rTCNUM0 = rTCNUM0 + 1
                   rTCNUM  = rTCNUM + CNUM

                   !--- collect the bond information
                   call DefectBondInfo_HCP(Clusters, LSIAnum, VACnum, SIAnum, BondInfo, FLAG)

                   !--- collect the summary number
                      LSIA    = sum(LSIAnum)
                      SIA     = sum(SIAnum)
                      VAC     = sum(VACnum)
                      rLSIA   = rLSIA + LSIA
                      rSIA    = rSIA + SIA
                      rVAC    = rVAC + VAC

                      tbSIA_SIA    =  0.D0
                      tbSIA_SIA_C  =  0.D0
                      tbSIA_SIA_A  =  0.D0
                      tbSIA_SIA_M  =  0.D0

                      tbSIA_VAC     = 0.D0
                      tbSIA_VAC_C   = 0.D0
                      tbSIA_VAC_A   = 0.D0
                      tbSIA_VAC_M   = 0.D0

                      tbVAC_VAC     = 0.D0
                      tbVAC_VAC_C   = 0.D0
                      tbVAC_VAC_A   = 0.D0
                      tbVAC_VAC_M   = 0.D0
                      do I=1, CNUM
                         SHFIT = (I-1)*VSIZ
                         bSIA_SIA    =  sum(BondInfo(SHFIT+1:SHFIT+4))
                         bSIA_SIA_C  =  BondInfo(SHFIT+4)
                         bSIA_SIA_A  =  BondInfo(SHFIT+1) + BondInfo(SHFIT+2) + BondInfo(SHFIT+3)
                         bSIA_SIA_M  =  BondInfo(SHFIT+1)

                         bSIA_VAC     = sum(BondInfo(SHFIT+5:SHFIT+8))
                         bSIA_VAC_C   = BondInfo(SHFIT+8)
                         bSIA_VAC_A   = BondInfo(SHFIT+5) + BondInfo(SHFIT+6) + BondInfo(SHFIT+7)
                         bSIA_VAC_M   = BondInfo(SHFIT+5)

                         bVAC_VAC     = sum(BondInfo(SHFIT+9:SHFIT+12))
                         bVAC_VAC_C   = BondInfo(SHFIT+12)
                         bVAC_VAC_A   = BondInfo(SHFIT+9) + BondInfo(SHFIT+10) + BondInfo(SHFIT+11)
                         bVAC_VAC_M   = BondInfo(SHFIT+9)

                         tbSIA_SIA   = tbSIA_SIA   + bSIA_SIA
                         tbSIA_SIA_C = tbSIA_SIA_C + bSIA_SIA_C
                         tbSIA_SIA_A = tbSIA_SIA_A + bSIA_SIA_A
                         tbSIA_SIA_M = tbSIA_SIA_M + bSIA_SIA_M

                         tbSIA_VAC   = tbSIA_VAC   + bSIA_VAC
                         tbSIA_VAC_C = tbSIA_VAC_C + bSIA_VAC_C
                         tbSIA_VAC_A = tbSIA_VAC_A + bSIA_VAC_A
                         tbSIA_VAC_M = tbSIA_VAC_M + bSIA_VAC_M

                         tbVAC_VAC   = tbVAC_VAC   + bVAC_VAC
                         tbVAC_VAC_C = tbVAC_VAC_C + bVAC_VAC_C
                         tbVAC_VAC_A = tbVAC_VAC_A + bVAC_VAC_A
                         tbVAC_VAC_M = tbVAC_VAC_M + bVAC_VAC_M
                      end do !--- end loop for current clusters

                     !--- accumulate for all box
                      rbSIA_SIA   = rbSIA_SIA   + tbSIA_SIA
                      rbSIA_SIA_C = rbSIA_SIA_C + tbSIA_SIA_C
                      rbSIA_SIA_A = rbSIA_SIA_A + tbSIA_SIA_A
                      rbSIA_SIA_M = rbSIA_SIA_M + tbSIA_SIA_M

                      rbSIA_VAC   = rbSIA_VAC   + tbSIA_VAC
                      rbSIA_VAC_C = rbSIA_VAC_C + tbSIA_VAC_C
                      rbSIA_VAC_A = rbSIA_VAC_A + tbSIA_VAC_A
                      rbSIA_VAC_M = rbSIA_VAC_M + tbSIA_VAC_M

                      rbVAC_VAC   = rbVAC_VAC   + tbVAC_VAC
                      rbVAC_VAC_C = rbVAC_VAC_C + tbVAC_VAC_C
                      rbVAC_VAC_A = rbVAC_VAC_A + tbVAC_VAC_A
                      rbVAC_VAC_M = rbVAC_VAC_M + tbVAC_VAC_M

                   !-------------------------------------------
                   !--- collect the seperation information
                    !print *, ICFG, IB, CNUM
                    call SeperationOfClusterList(Clusters, SEP)
                    if(CNUM .gt. 1) then
                       write(hFile1, fmt="(7x, I10, 2x, 1PE12.6, 2x, 100(1x, I9,1x))")   &
                             ITIME, TIME, ICFG, IB, CNUM, (SEP(IC, IC+1:CNUM), IC=1, CNUM-1)
                    else
                       write(hFile1, fmt="(7x, I10, 2x, 1PE12.6, 2x, 100(1x, I9,1x))")   &
                             ITIME, TIME, ICFG, IB, CNUM, 0
                    end if

                    do IC = 1, CNUM-1
                       do IC1 = IC+1, CNUM
                          IH = SEP(IC, IC1)
                          if(IH .gt. p_SEPHISBINS) IH = p_SEPHISBINS
                          SEPHIS(IH) = SEPHIS(IH) +1
                       end do
                    end do
                   !-------------------------------------------

                end do !--- end loop for box
                if(ENDFLAG .eq. NBOX) exit
                !--- put out the Bond Information
                write(hFile, fmt="(7x, I10, 2x, 1PE12.6, 2x, 30(1x, I9,1x))")        &
                                  ITIME, TIME, rtCNUM, rLSIA, rSIA, rVAC,            &
                                  rbSIA_SIA, rbSIA_SIA_C, rbSIA_SIA_A, rbSIA_SIA_M,  &
                                  rbSIA_VAC, rbSIA_VAC_C, rbSIA_VAC_A, rbSIA_VAC_M,  &
                                  rbVAC_VAC, rbVAC_VAC_C, rbVAC_VAC_A, rbVAC_VAC_M


                write(hFile2, fmt="(7x, I10, 2x, 1PE12.6, 2x, 100(1x, I9,1x))")        &
                                  ITIME, TIME, rtCNUM0, rtCNUM, sum(SEPHIS), SEPHIS(1:p_SEPHISBINS)



             end do
             if(hFile .gt. 0) close(hFile)
             if(hFile1.gt. 0) close(hFile1)
             if(hFile2.gt. 0) close(hFile2)
             if(allocated(BondInfo)) deallocate(BondInfo)
             if(allocated(LSIAnum))  deallocate(LSIAnum)
             if(allocated(SIAnum))   deallocate(SIAnum)
             if(allocated(VACnum))   deallocate(VACnum)
             if(allocated(LINE))     deallocate(LINE)
             if(allocated(SEP))      deallocate(SEP)

             return
   end subroutine DefectBondAnalysis
  !**********************************************************************************


  !**********************************************************************************
  subroutine MyCleaner()
  !***  PURPOSE:  to deallocate the memories allocated
  !    INPUT:     SimBox,    the simulation box, useless here
  !               CtrlParam, the control parameter, useless here
  !   OUTPUT:
  !
          call Clear()
          return
  end subroutine MyCleaner
  !**********************************************************************************

 end module DefectCluster_BondDis_hcp


 !**********************************************************************************
 Program DefectCluster_BondDis_hcp_Main
 use DefectCluster_BondDis_hcp
 implicit none


       call Initialize()
       call DefectBondAnalysis()
       call MyCleaner()

       stop
 End program DefectCluster_BondDis_hcp_Main
