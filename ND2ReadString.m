function [String] = ND2ReadString(StringPointer, DataType)
% ND2ReadString reads a NUL-terminated LIMSTR returned by the ND2 SDK.
%
%   String = ND2ReadString(StringPointer, DataType) copies the C string
%   referenced by StringPointer into a MATLAB character vector. Pass the
%   lib.pointer returned by any SDK function that Nd2ReadSdk.h documents as
%   returning a LIMSTR, i.e. Lim_FileGetAttributes, Lim_FileGetTextinfo,
%   Lim_FileGetMetadata, Lim_FileGetFrameMetadata and Lim_FileGetExperiment.
%   A null pointer returns an empty character vector.
%
%   DataType is the pointer type to read the bytes as, and defaults to
%   'uint8Ptr'. It only affects how bytes above 127 reach char(): 'uint8Ptr'
%   maps them to their Latin-1 characters, while 'int8Ptr' makes them negative
%   so that char() silently turns them into NUL. Each caller passes whichever
%   type it used before this function existed, so text handling is unchanged.
%
%   This function does not release the buffer. The SDK requires that the
%   caller do so with Lim_FileFreeString; see ND2FreeString. On return the
%   declared extent of StringPointer is left small enough to pass safely back
%   across calllib.
%
%   Why the terminator is found one byte at a time
%   ----------------------------------------------
%   The SDK allocates these buffers to exactly strlen+1 bytes and offers no
%   size query. setdatatype(p, type, n) only records the declared extent, but
%   the p.Value that follows memcpys all n bytes out of the raw address. Any n
%   larger than the real allocation therefore reads past the end of the heap
%   block. Such a read usually lands on a mapped page and appears to work,
%   which is why guessing a length seemed to work, but when the block happens
%   to sit near the end of a committed region the read faults and kills the
%   whole MATLAB process with an access violation.
%
%   Reading byte k only after bytes 0..k-1 have all been shown to be non-NUL
%   proves the allocation holds at least k+1 bytes, so no read below is ever
%   out of bounds.

    if nargin < 2
        DataType = 'uint8Ptr';
    end

    String = '';

    if ~isa(StringPointer, 'lib.pointer') || StringPointer.isNull
        return
    end

    % A terminator is expected long before this. It is only a runaway guard.
    MaxLength = 4194304;

    % Declaring a large extent costs nothing because setdatatype issues no
    % read. It exists so the pointer arithmetic below stays inside the declared
    % bounds. Every actual read is a single byte.
    setdatatype(StringPointer, DataType, MaxLength);

    Length = 0;
    while Length < MaxLength
        Probe = StringPointer+Length;
        setdatatype(Probe, DataType, 1);

        if Probe.Value(1) == 0
            break
        end

        Length = Length+1;
    end

    % Never leave the pointer declared as MaxLength. calllib marshals the full
    % declared extent of a lib.pointer argument, so a large extent would make
    % MATLAB itself read past the buffer when the caller frees it.
    if Length >= MaxLength
        setdatatype(StringPointer, DataType, 1);
        error('ND2ReadString:NoTerminator', ...
            ['The ND2 SDK returned a string with no terminator in the first %d bytes. ', ...
            'Check that Nd2ReadSdk.dll matches the Nd2ReadSdk.h used by loadlibrary ', ...
            'and that the ND2 file is not truncated.'], MaxLength);
    end

    % Length is now known to be in bounds, so the payload can be taken in a
    % single read that stops exactly at the terminator.
    if Length > 0
        setdatatype(StringPointer, DataType, Length);
        String = char(StringPointer.Value(:)');
    else
        setdatatype(StringPointer, DataType, 1);
    end

end
