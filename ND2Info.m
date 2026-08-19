function [ImageInfo] = ND2Info(FileName)

if not(libisloaded('Nd2ReadSdk'))
    warning('off', 'MATLAB:loadlibrary:cppoutput')
    [~, ~] = loadlibrary('Nd2ReadSdk', 'Nd2ReadSdk.h');
end

FileID = libpointer('voidPtr', [int8(FileName) 0]);
[FilePointer] = calllib('Nd2ReadSdk', 'Lim_FileOpenForReadUtf8', FileID);

% Lim_FileOpenForReadUtf8 returns NULL on failure. Reporting it here gives a
% caller something actionable instead of an error out of jsondecode further
% down, once the empty attributes string fails to parse.
if FilePointer.isNull
    error('ND2Info:CannotOpenFile', ...
        ['Lim_FileOpenForReadUtf8 could not open "%s". Check that the file exists, ', ...
        'is a readable ND2 file, and is not locked by another program.'], FileName);
end

% Close the file however this function exits, so an error partway through
% cannot leak an SDK file handle into the next file of a batch loop.
CloseOnExit = onCleanup(@() ND2Close(FilePointer));
numImages = calllib('Nd2ReadSdk', 'Lim_FileGetSeqCount', FilePointer);
CoordSize = calllib('Nd2ReadSdk', 'Lim_FileGetCoordSize', FilePointer);
% 'int8Ptr' is passed explicitly at every call site in this file so the existing
% text handling is preserved byte for byte. char() maps a negative int8 to 0, so
% bytes above 127 become NUL here, which is what CheckInfo's
% Description(Description == 0) = ' ' already compensates for.
Attributes = calllib('Nd2ReadSdk', 'Lim_FileGetAttributes', FilePointer);
AttributesJson = ND2ReadString(Attributes, 'int8Ptr');
ND2FreeString(Attributes, 'int8Ptr');
AttributesStru = jsondecode(AttributesJson);

TextInfo = calllib('Nd2ReadSdk', 'Lim_FileGetTextinfo', FilePointer);
TextInfoJson = ND2ReadString(TextInfo, 'int8Ptr');
ND2FreeString(TextInfo, 'int8Ptr');
TextInfoStru = jsondecode(TextInfoJson);

Metadata = calllib('Nd2ReadSdk', 'Lim_FileGetMetadata', FilePointer);

if Metadata.isNull
    MetadataStru=[];
else
    MetadataJson = ND2ReadString(Metadata, 'int8Ptr');
    ND2FreeString(Metadata, 'int8Ptr');
    MetadataStru = jsondecode(MetadataJson);
    
end


Experiment = calllib('Nd2ReadSdk', 'Lim_FileGetExperiment', FilePointer);
if Experiment.isNull
    ExperimentStru=[];
    NumInCoord=[];
else
    ExperimentJson = ND2ReadString(Experiment, 'int8Ptr');
    ND2FreeString(Experiment, 'int8Ptr');
    ExperimentStru=jsondecode(ExperimentJson);
    
    
    % CoordSize and the reported loop count can disagree on some files, so read
    % only as many loops as the experiment actually returned. CheckInfo
    % reconciles the two afterwards.
    NumInCoord=zeros(1,CoordSize);
    for i = 1:min(CoordSize, numel(ExperimentStru))
        NumInCoord(i)=ExperimentStru(i).count;
    end
    
end
ImageInfo.Attributes = AttributesStru;
ImageInfo.metadata = MetadataStru;
ImageInfo.Experiment = ExperimentStru;
ImageInfo.capturing = TextInfoStru.capturing;
ImageInfo.description = TextInfoStru.description;
ImageInfo.numImages = numImages;
ImageInfo.CoordSize = CoordSize;

% ImageInfo.NumInCoord = NumInCoord;
warning('off','backtrace')
if AttributesStru.widthBytes==AttributesStru.widthPx*AttributesStru.componentCount*AttributesStru.bitsPerComponentInMemory/8
    ImageInfo.ImageWidth = AttributesStru.widthPx;
    ImageInfo.ImageWidthOriginal = AttributesStru.widthPx;
else
    warning('Image width is not fit the bytes of width. Reset image width.')
    ImageInfo.ImageWidth=AttributesStru.widthBytes/AttributesStru.componentCount/(AttributesStru.bitsPerComponentInMemory/8);
    ImageInfo.ImageWidthOriginal = AttributesStru.widthPx;
end
warning('on','backtrace')


ImageInfo.ImageHeight = AttributesStru.heightPx;
ImageInfo.Component = AttributesStru.componentCount;


[ImageInfo] = CheckInfo(ImageInfo);
PrintInfo(ImageInfo);

% CloseOnExit calls ND2Close(FilePointer) here. Do not add an explicit
% ND2Close as well; closing the same handle twice is undefined behaviour.

end
