function [] = ND2FreeString(StringPointer, DataType)
% ND2FreeString releases a LIMSTR returned by the ND2 SDK.
%
%   ND2FreeString(StringPointer, DataType) calls Lim_FileFreeString on the
%   buffer referenced by StringPointer, which Nd2ReadSdk.h requires for every
%   string returned by Lim_FileGetAttributes, Lim_FileGetTextinfo,
%   Lim_FileGetMetadata, Lim_FileGetFrameMetadata and Lim_FileGetExperiment.
%   A null pointer is ignored. DataType defaults to 'uint8Ptr'.
%
%   The declared extent is shrunk to one element first. calllib marshals the
%   full declared extent of a lib.pointer argument, so passing a pointer that
%   is still declared as thousands of elements makes MATLAB read past the end
%   of the buffer while marshalling the argument, which can fault.

    if nargin < 2
        DataType = 'uint8Ptr';
    end

    if ~isa(StringPointer, 'lib.pointer') || StringPointer.isNull
        return
    end

    setdatatype(StringPointer, DataType, 1);
    calllib('Nd2ReadSdk', 'Lim_FileFreeString', StringPointer);

end
