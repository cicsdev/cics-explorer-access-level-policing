*ASM XOPTS(NOPROLOG NOEPILOG)
***********************************************************************
*                                                                     *
* MODULE NAME = DFHWBAAX                                              *
*                                                                     *
* DESCRIPTIVE NAME = CICS TS  (WB) Default Analyzer program           *
*                                                                     *
* Licensed Materials - Property of IBM                                *
*                                                                     *
* SAMPLE                                                              *
*                                                                     *
* (c) Copyright IBM Corp. 2016 All Rights Reserved                    *
*                                                                     *
* US Government Users Restricted Rights - Use, duplication or         *
* disclosure restricted by GSA ADP Schedule Contract with IBM Corp    *
*                                                                     *
* FUNCTION = Default Analyzer used to analyze an HTTP request         *
*            when the incoming URL does not match a URIMAP.           *
*                                                                     *
* NOTES:                                                              *
*                                                                     *
*    THIS IS A PRODUCT SENSITIVE SAMPLE.                              *
*    REFER TO PRODUCT DOCUMENTATION.                                  *
*                                                                     *
*    DEPENDENCIES = S/390                                             *
*    MODULE TYPE = Executable                                         *
*    PROCESSOR = Assembler                                            *
*    ATTRIBUTES = Read only, Serially Reusable                        *
*                                                                     *
*---------------------------------------------------------------------*
*                                                                     *
* ENTRY POINT = DFHWBAAX                                              *
*                                                                     *
*     PURPOSE = All functions                                         *
*                                                                     *
*     LINKAGE =                                                       *
*         This entry point is called by the CWS Web Send/Receive      *
*         program DFHWBSR via EXEC CICS LINK.                         *
*                                                                     *
*     INPUT =                                                         *
*         The parameters are passed to the exit program via the       *
*         commarea. The mapping for this parameter list is in         *
*         DFHWBTDD.                                                   *
*                                                                     *
*     OUTPUT =                                                        *
*                                                                     *
*     EXIT-NORMAL = Exit is via an EXEC CICS RETURN command.          *
*         The following return codes may be returned via the          *
*         commarea:                                                   *
*            URP_OK = 0                                               *
*                                                                     *
*     EXIT-ERROR = Exit is via an EXEC CICS RETURN command.           *
*         The following return codes may be returned via the          *
*         commarea:                                                   *
*            URP_EXCEPTION = 4                                        *
*            URP_INVALID   = 8                                        *
*            URP_DISASTER  = 12                                       *
*                                                                     *
*---------------------------------------------------------------------*
*                                                                     *
* EXTERNAL REFERENCES =                                               *
*         None.                                                       *
*                                                                     *
*     ROUTINES =                                                      *
*         EXEC CICS RETURN - return to the calling program.           *
*                                                                     *
*     CONTROL BLOCKS =                                                *
*         The CWS Analyzer parameter list is defined in DFHWBTDD,     *
*         along with a description of the parameters.                 *
*                                                                     *
*---------------------------------------------------------------------*
*                                                                     *
* DESCRIPTION                                                         *
*                                                                     *
*        This program is the default but user-replaceable version     *
*        of the CICS Web Support Analyzer program.                    *
*        The program is invoked when an HTTP request is received by   *
*        CICS Web support if it is specified as the URM in the        *
*        TCPIPSERVICE definition and one of the following is true:    *
*          o The incoming URL does not match against any              *
*            installed URIMAP definition                              *
*            -- In this case, the error application program           *
*               DFHWBERX is scheduled                                 *
*          o The incoming URL matches an installed URIMAP,            *
*            but the URIMAP specifies ANALYZER(YES).                  *
*            -- In this case, no action is taken.                     *
*               It is assumed that the URIMAP has provided all        *
*               the necessary CICS resource names.                    *
*                                                                     *
*        A parameter list as defined in the DFHWBTDD copybook is      *
*        provided as input to this program.                           *
*        The parameter list is addressed by the program using the     *
*        normal conventions for a commarea.                           *
*                                                                     *
*        This program does *not* expect the previously expected       *
*        "standard" CICS URL format of                                *
*          http://hostname/cics/cwba/program?token                    *
*        It assumes that most URL decoding will be handled by         *
*        URIMAP processing and that this routine will only be         *
*        entered on an exception basis. Neither does it attempt       *
*        to schedule the unescaping program DFHWBUN. These features   *
*        are now deprecated, but for an example of how to use them,   *
*        see the obsolete sample program DFHWBADX.                    *
*                                                                     *
* CHANGE ACTIVITY :                                                   *
*        $MOD(DFHWBAAX),COMP(CICSWEB),PROD(CICS TS ):                 *
*                                                                     *
*   PN= REASON REL YYMMDD HDXXIII : REMARKS                           *
*  $P0= D10527 640 050119 HD2JPEH : Default Analyzer program          *
*                                                                     *
***********************************************************************
         TITLE 'DFHWBAAX - Default CICS Web Support Analyzer Program'
*---------------------------------------------------------------------*
*    Standard CWS definitions required                                *
*---------------------------------------------------------------------*
         COPY  DFHKEBRC           Relative branch definitions
         COPY  DFHWBTDD           Analyzer parameter list
         COPY  DFHWBUND           DFHWBUN parameter list
         DFHREGS ,                CICS Register definition
*
*---------------------------------------------------------------------*
*    Working storage definitions                                      *
*---------------------------------------------------------------------*
         DFHEISTG ,
*
*    Insert your own storage definitions here
*
*---------------------------------------------------------------------*
*    Working storage needed for EXEC CICS call                        *
*---------------------------------------------------------------------*
USERAGNT DS    CL127
USERAGNTL DS   F
RCODE    DS    F
RCODE2   DS    F
         DFHEIEND ,
*---------------------------------------------------------------------*
*    Start of program code                                            *
*---------------------------------------------------------------------*
DFHWBAAX CSECT
DFHWBAAX AMODE 31
DFHWBAAX RMODE ANY
         DFHEIENT CODEREG=0,                Use relative addressing    *
               STATREG=R10,STATIC=AASTATIC, Specify static addressing  *
               EIBREG=R11                   Specify EIB addressing
*
*  If there is no commarea, just return.
*  (There is nowhere to set return codes).
*
         ICM   R0,3,EIBCALEN
         BZ    RETURN
*
*  Address the parameter list
*
         L     R3,DFHEICAP
         USING WBRA_PARMS,R3
*
*  Validate the eyecatcher
*
         CLC   WBRA_EYECATCHER,ANALYZE_EYECATCHER_INIT
         BNE   RETURNIN            Return response=invalid
*---------------------------------------------------------------------*
*  Set the name to be used for codepage translation                   *
*  of the user data to 'DFHWBUD'.                                     *
*---------------------------------------------------------------------*
         MVC   WBRA_DFHCNV_KEY,CNV_USER_DATA_KEY
*=====================================================================*
*    User-replaceable code below                                      *
*=====================================================================*
         SPACE 5
         MVC   USERAGNTL,=A(L'USERAGNT)
         EXEC CICS WEB READ HTTPHEADER('User-Agent')                   x
                 NAMELENGTH(10) VALUE(USERAGNT) VALUELENGTH(USERAGNTL) X
                 RESP(RCODE) RESP2(RCODE2)
         L     R5,RCODE
         C     R5,DFHRESP(NORMAL)
         BNE   MAINLINE                No user agent, so ignore
* If we get here, there is a user agent string to test
         LA    R5,USERAGNT
         CLC   0(L'SUPEXPL1,R5),SUPEXPL1 First supported string
         BE    MAINLINE                Yes, so carry on
         CLC   0(L'SUPEXPL2,R5),SUPEXPL2 Second supported string
         BE    MAINLINE                Yes, so carry on
         B     RETURNIN                Not supported, so invalid
MAINLINE DS    0H
         MVC   WBRA_ALIAS_TRANID,=C'CWBA'       Set default alias
         MVC   WBRA_SERVER_PROGRAM,=C'DFHWBERX' Set target program
         MVC   WBRA_CONVERTER_PROGRAM,=CL8' '   Set null converter
         B     RETURNOK             Exit normally
         SPACE 5
*=====================================================================*
*    User-replaceable code above                                      *
*=====================================================================*
         EJECT
*---------------------------------------------------------------------*
*    Return Disaster                                                  *
*---------------------------------------------------------------------*
RETURNDI DS    0H
         LHI   R15,URP_DISASTER
         B     RETURNRC
*---------------------------------------------------------------------*
*    Return Invalid                                                   *
*---------------------------------------------------------------------*
RETURNIN DS    0H
         LHI   R15,URP_INVALID
         B     RETURNRC
*---------------------------------------------------------------------*
*    Return Exception                                                 *
*---------------------------------------------------------------------*
RETURNEX DS    0H
         LHI   R15,URP_EXCEPTION
         B     RETURNRC
*---------------------------------------------------------------------*
*    Return OK                                                        *
*---------------------------------------------------------------------*
RETURNOK DS    0H
         LHI   R15,URP_OK
*---------------------------------------------------------------------*
*    Return point                                                     *
*---------------------------------------------------------------------*
RETURNRC ST    R15,WBRA_RESPONSE
RETURN   DS    0H
         EXEC  CICS RETURN
         EJECT
***********************************************************************
*                                                                     *
*  Program static data                                                *
*                                                                     *
***********************************************************************
AASTATIC DC    0AD(0)              Start of static data
         COPY  DFHWBUCD            CWS URP constant definitions
         EJECT
*---------------------------------------------------------------------*
*    Supported Explorer levels                                       *
*---------------------------------------------------------------------*
SUPEXPL1 DC    CL85'IBM_CICS_Explorer/5.3.2.201604061614 IBM_zOS_Explor*
               er/3.0.0.201512020512 JRE/1.8.0_74'
SUPEXPL2 DC    CL37'IBM_CICS_Explorer/5.2.0.20150115-1247'
*---------------------------------------------------------------------*
*    Translate table for upper case conversion                        *
*---------------------------------------------------------------------*
         DC    0AD(0)              Align to a doubleword
UCTAB    DC    256AL1(*-UCTAB)     ASIS by default
         ORG   UCTAB+C'a'
         DC    C'ABCDEFGHI'
         ORG   UCTAB+C'j'
         DC    C'JKLMNOPQR'
         ORG   UCTAB+C's'
         DC    C'STUVWXYZ'
         ORG   ,
         SPACE 2
*---------------------------------------------------------------------*
*    Translate table for hexadecimal to binary conversion             *
*---------------------------------------------------------------------*
HEXBIN   DC    256X'FF'
         ORG   HEXBIN+C'a'         Lower-case a-f
         DC    X'0A0B0C0D0E0F'
         ORG   HEXBIN+C'A'         Upper-case A-F
         DC    X'0A0B0C0D0E0F'
         ORG   HEXBIN+C'0'         Numerics
         DC    X'00010203040506070809'
         ORG   ,
         SPACE 2
*---------------------------------------------------------------------*
*    Translate table for ASCII (ISO-8859-1) to EBCDIC (IBM-037)       *
*---------------------------------------------------------------------*
EBCDIC   DC    X'00010203372D2E2F1605250B0C0D0E0F'
         DC    X'101112133C3D322618193F271C1D1E1F'
         DC    X'405A7F7B5B6C507D4D5D5C4E6B604B61'
         DC    X'F0F1F2F3F4F5F6F7F8F97A5E4C7E6E6F'
         DC    X'7CC1C2C3C4C5C6C7C8C9D1D2D3D4D5D6'
         DC    X'D7D8D9E2E3E4E5E6E7E8E9BAE0BBB06D'
         DC    X'79818283848586878889919293949596'
         DC    X'979899A2A3A4A5A6A7A8A9C04FD0A107'
         DC    X'202122232415061728292A2B2C090A1B'
         DC    X'30311A333435360838393A3B04143EFF'
         DC    X'41AA4AB19FB26AB5BDB49A8A5FCAAFBC'
         DC    X'908FEAFABEA0B6B39DDA9B8BB7B8B9AB'
         DC    X'6465626663679E687471727378757677'
         DC    X'AC69EDEEEBEFECBF80FDFEFBFCADAE59'
         DC    X'4445424643479C485451525358555657'
         DC    X'8C49CDCECBCFCCE170DDDEDBDC8D8EDF'
         SPACE 2
*---------------------------------------------------------------------*
*    Literal pool                                                     *
*---------------------------------------------------------------------*
         LTORG ,
         END   DFHWBAAX
