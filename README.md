# CICS Explorer Access Level Policing

This is implemented by the use of a sample program which can ensure that only approved
versions of the CICS Explorer can be used to access a given CICS TS region.

A customised version of the sample program `DFHWBAAX` is able to provide this
functionality.

## How it works

The customised `DFHWBAAX` program analyses the user-agent string from the HTTP header
which CICS has received. Each release of Explorer includes a unique user-agent string in
the HTTP header. The received string is tested against user defined "approved" strings to
determine whether the connection attempt should be allowed to succeed.

Any number of "approved" strings can be defined, which enables a flexible policing method
which can be used with any in-service release of CICS TS.

Further details of this module can be found in the associated [CICSDev article][c].

## License

This project is licensed under [Apache License Version 2.0](LICENSE).

[c]: https://developer.ibm.com/cics/2016/09/12/a-customised-web-analyser-program-to-police-cics-explorer-access-levels
