function [] = ND2FreeString(StringPointer)
% ND2FreeString releases a LIMSTR returned by the ND2 SDK.
%
%   ND2FreeString(StringPointer) calls Lim_FileFreeString on the buffer
%   referenced by StringPointer, which Nd2ReadSdk.h requires for every string
%   returned by Lim_FileGetAttributes, Lim_FileGetTextinfo,
%   Lim_FileGetMetadata, Lim_FileGetFrameMetadata and Lim_FileGetExperiment.
%   A null pointer is ignored.
%
%   The pointer is always re-declared as a single int8 before the call, and
%   the type is deliberately not a parameter. Two separate things are easy to
%   confuse here:
%
%     * How the bytes are read back into MATLAB. 'int8Ptr' and 'uint8Ptr'
%       differ there, because char() folds a negative int8 to NUL. That is a
%       real choice and it belongs to the caller, so ND2ReadString takes it.
%
%     * What type this argument must be. Lim_FileFreeString takes a LIMSTR,
%       which is char*, so calllib accepts only a matching int8Ptr or a
%       generic voidPtr. Handing it a uint8Ptr fails with "Pointer types must
%       match data type", whatever type the string was read as. That is not a
%       choice at all.
%
%   The extent is shrunk to one element because calllib marshals the full
%   declared extent of a lib.pointer argument. Leaving it at the string length
%   would make MATLAB copy the whole buffer just to pass the argument, and
%   leaving it larger than the allocation would read past the end of it.

    if ~isa(StringPointer, 'lib.pointer') || StringPointer.isNull
        return
    end

    setdatatype(StringPointer, 'int8Ptr', 1);
    calllib('Nd2ReadSdk', 'Lim_FileFreeString', StringPointer);

end
