function [ImageInfo] = ND2Info(FileName)

if not(libisloaded('Nd2ReadSdk'))
    warning('off', 'MATLAB:loadlibrary:cppoutput')
    [~, ~] = loadlibrary('Nd2ReadSdk', 'Nd2ReadSdk.h');
end

FileID = libpointer('voidPtr', [int8(FileName) 0]);
[FilePointer] = calllib('Nd2ReadSdk', 'Lim_FileOpenForReadUtf8', FileID);
numImages = calllib('Nd2ReadSdk', 'Lim_FileGetSeqCount', FilePointer);
CoordSize = calllib('Nd2ReadSdk', 'Lim_FileGetCoordSize', FilePointer);
% 'int8Ptr' is passed explicitly at every call site in this file so the existing
% text handling is preserved byte for byte. char() maps a negative int8 to 0, so
% bytes above 127 become NUL here, which is what CheckInfo's
% Description(Description == 0) = ' ' already compensates for.
Attributes = calllib('Nd2ReadSdk', 'Lim_FileGetAttributes', FilePointer);
AttributesJson = ND2ReadString(Attributes, 'int8Ptr');
AttributesStru = jsondecode(AttributesJson);

TextInfo = calllib('Nd2ReadSdk', 'Lim_FileGetTextinfo', FilePointer);
TextInfoJson = ND2ReadString(TextInfo, 'int8Ptr');
TextInfoStru = jsondecode(TextInfoJson);

Metadata = calllib('Nd2ReadSdk', 'Lim_FileGetMetadata', FilePointer);

if Metadata.isNull
    MetadataStru=[];
else
    MetadataJson = ND2ReadString(Metadata, 'int8Ptr');
    MetadataStru = jsondecode(MetadataJson);
    
end


Experiment = calllib('Nd2ReadSdk', 'Lim_FileGetExperiment', FilePointer);
if Experiment.isNull
    ExperimentStru=[];
    NumInCoord=[];
else
    ExperimentJson = ND2ReadString(Experiment, 'int8Ptr');
    ExperimentStru=jsondecode(ExperimentJson);
    
    
    NumInCoord=zeros(1,CoordSize);
    for i = 1:CoordSize
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

ND2Close(FilePointer)
clear('FilePointer')

end
