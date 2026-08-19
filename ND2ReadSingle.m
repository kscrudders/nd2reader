function [Image] = ND2ReadSingle(FileName, varargin)

[FilePointer, ImagePointer, ImageReadOut] = ND2Open(FileName);

if isempty(varargin)
    numImages = calllib('Nd2ReadSdk', 'Lim_FileGetSeqCount', FilePointer);
    Num=1:numImages;
else
    Num=varargin{1};
end

[Image] = ND2Read(FilePointer, ImagePointer, ImageReadOut, Num);

% Lim_InitPicture (called by ND2Open) allocates a full frame buffer that the SDK
% only releases on Lim_DestroyPicture. Image already holds a MATLAB copy, so the
% picture can be destroyed here. Without this every call leaks one frame worth
% of native memory, which adds up quickly when looping over many files.
calllib('Nd2ReadSdk', 'Lim_DestroyPicture', ImagePointer);

ND2Close(FilePointer)
clear('FilePointer')

end
