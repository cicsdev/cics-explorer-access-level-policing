# A customised web analyser program to police CICS Explorer access levels

A requirement was received from a customer for a way of policing which versions of
Explorer could connect to CICS TS. The acceptable versions of Explorer could, for
example, be those which had been tested by the customer and confirmed as being safe to
use on the production CICS regions.

This could be achieved through the use of a custom written web analyser program. The
supplied web analyser program is `DFHWBAAX`, which is merely a skeleton to provide a
starting point for writing a custom program to perform a useful function or functions.

The analyser program was changed as discussed below. The updated code can be seen on
[GitHub][github].

The user-agent string is checked to determine whether an attempt to connect to CICS is
coming from an authorised version of Explorer. This string is a character string added to
the HTTP header by Explorer. The string uniquely identifies the version of Explorer which
added the string.

## How it works

Firstly, some working storage is required for the EXEC CICS calls which are to be used.

    *---------------------------------------------------------------------*
    *    Working storage needed for EXEC CICS call                        *
    *---------------------------------------------------------------------*
    USERAGNT DS    CL127
    USERAGNTL DS   F
    RCODE    DS    F
    RCODE2   DS    F
             DFHEIEND ,
    *---------------------------------------------------------------------*

The majority of the code was added to the "User-replaceable code" section of the sample
module. The code is shown below:

    *=====================================================================*
    *    User-replaceable code below                                      *
    *=====================================================================*
             SPACE 5
             MVC   USERAGNTL,=A(L'USERAGNT)
             EXEC CICS WEB READ HTTPHEADER('User-Agent')                   X
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

An `EXEC CICS WEB READ HTTPHEADER` command is used to extract the user-agent string from
the HTTP header which has been received. The return code is tested to determine whether
the command worked successfully. If it did not, then there is no user-agent string in the
header, so the request did not come from Explorer. Control passes to the label `MAINLINE`
and processing continues normally.

If the `EXEC CICS WEB READ` does succeed, it means that there is a user-agent string
which can be tested. The tests are performed using commands such as:

    CLC 0(L`SUPEXPL1,R5),SUPEXPL1

which compares a user-agent string, addressed by register 5, against a test string,
`SUPEXPL1`. The string `SUPEXPL1` is defined later in `DFHWBAAX` in a section headed
"Supported explorer levels" as shown below. Note that `SUPEXPL1` is 85 characters long
and requires more than one line to declare.

    *---------------------------------------------------------------------*
    *    Supported Explorer levels                                        *
    *---------------------------------------------------------------------*
    SUPEXPL1 DC    CL85'IBM_CICS_Explorer/5.3.2.201604061614 IBM_zOS_Explor*
                   er/3.0.0.201512020512 JRE/1.8.0_74'
    SUPEXPL2 DC    CL37'IBM_CICS_Explorer/5.2.0.20150115-1247'
    *---------------------------------------------------------------------*

The [code][github] associated with this article tests for two supported Explorer strings:
`SUPEXPL1` and `SUPEXPL2`. If neither match the input that has been received from
Explorer, an invalid response is returned and the connection will fail. If a match is
found, control passes to the `MAINLINE` label and the connection succeeds.

## Easy, extensible, and available on in-service releases

It is clear that this technique can be easily extended to test for any number of Explorer
levels. All that is required is to add a new test for a new character string and to
define a new character string to test against. It is also easy to have a small number of
different web analyser programs testing for different character strings in the user-agent
string. It might be useful, for example, to have one analyser for test CICS regions and a
different analyser for production regions. Which analyser is to be used can be specified
on a TCPIPSERVICE definition, so this is straightforward to tailor to requirements.

Another advantage of using this simple technique is that it is available on all
in-service releases of CICS TS. Please note that this analyser runs for every CMCI
request and may affect the performance time of requests. If you are noticing a
performance slow-down, remove your custom web analyser and check that this is not the
cause before raising a PMR with IBM.

[github]: https://github.com/cicsdev/cics-explorer-access-level-policing
