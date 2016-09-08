# CICS Explorer Access Level Policing

This is a sample program to help ensure that only approved and tested versions of
CICS Explorer can be used to access a given CICS TS region.

`DFHWBAAX` can be used to compare the user-agent string that Explorer adds to the HTTP
header against user-specified strings, ensuring that only user-agent strings issued by
allowed versions of Explorer lead to successful connections.

## How it works

Firstly, an `EXEC CICS READ HTTPHEADER` command is used to extract the user-agent string
from the HTTP header that CICS has received. The return code is tested to check that the
command ran successfully. If it didn't then there isn't a user-agent string in the header
and the access request didn't come from Explorer, so control is passed to the label
`MAINLINE` and processing continues normally.

If the `EXEC CICS READ` command is successful, then there exists a user-agent
string which can be tested using commands that look like this:

    CLC 0(L`SUPEXPL1,R5),SUPEXPL1

Where the user-agent string, addressed by register 5, is tested against the
string `SUPEXPL1`.

Further details of this module can be found in the associated [CICSDev article][c].

## License

This project is licensed under [Apache License Version 2.0](LICENSE).

[github]: https://github.com/cicsdev/cics-explorer-access-level-policing
[c]: https://developer.ibm.com/cics
