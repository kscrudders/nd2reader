function [FilePointer, ImagePointer, ImageReadOut] = ND2Open(FileName)

    if not(libisloaded('Nd2ReadSdk'))
        warning('off', 'MATLAB:loadlibrary:cppoutput')
        [~, ~] = loadlibrary('Nd2ReadSdk', 'Nd2ReadSdk.h');
    end

    FileID = libpointer('voidPtr', [int8(FileName) 0]);
    [FilePointer] = calllib('Nd2ReadSdk', 'Lim_FileOpenForReadUtf8', FileID);
%     CoordSize = calllib('Nd2ReadSdk', 'Lim_FileGetCoordSize', FilePointer);
%     numImages = calllib('Nd2ReadSdk', 'Lim_FileGetSeqCount', FilePointer);
    % The attributes JSON is only a couple of hundred bytes, so the fixed
    % 500-byte read ran off the end of the SDK allocation on every call.
    Attibutes = calllib('Nd2ReadSdk', 'Lim_FileGetAttributes', FilePointer);
    AttibutesJson = ND2ReadString(Attibutes, 'uint8Ptr');
    AttibutesStru = jsondecode(AttibutesJson);

    % Metadata = calllib('Nd2ReadSdk','Lim_FileGetMetadata',FilePointer);
    % setdatatype(Metadata,'uint8Ptr',5000)
    % MetadataValue=Metadata.Value';
    % Metadatalength=find(MetadataValue==0,1);
    % MetadataJson=char(MetadataValue(1:Metadatalength-1));

    ImageStru.uiBitsPerComp = AttibutesStru.bitsPerComponentInMemory;
    ImageStru.uiComponents = AttibutesStru.componentCount;
    ImageStru.uiWidthBytes = AttibutesStru.widthBytes;
    ImageStru.uiHeight = AttibutesStru.heightPx;
    ImageStru.uiWidth = AttibutesStru.widthPx;
          
    if ImageStru.uiWidthBytes==ImageStru.uiWidth*ImageStru.uiComponents*ImageStru.uiBitsPerComp/8
    else
        warning('off','backtrace')
        warning('Image width is not fit the bytes of width. Reset image width.')
        warning('on','backtrace')
        ImageStru.uiWidth=ImageStru.uiWidthBytes/ImageStru.uiComponents/(ImageStru.uiBitsPerComp/8);
    end
    
    ImagePointer = libpointer('s_LIMPICTUREPtr', ImageStru);

    calllib('Nd2ReadSdk', 'Lim_InitPicture', ImagePointer, ImageStru.uiWidth, ImageStru.uiHeight, ImageStru.uiBitsPerComp, ImageStru.uiComponents);

    [~, ~, ImageReadOut] = calllib('Nd2ReadSdk', 'Lim_FileGetImageData', FilePointer, uint32(0), ImagePointer);
    setdatatype(ImageReadOut.pImageData, 'uint16Ptr', ImageStru.uiWidth * ImageStru.uiHeight * ImageStru.uiComponents)
end
