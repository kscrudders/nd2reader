function [SeqTime,SeqPosition] = SeqInfo(FileName,Num)

if not(libisloaded('Nd2ReadSdk'))
    [~, ~] = loadlibrary('Nd2ReadSdk', 'Nd2ReadSdk.h');
end

FileID = libpointer('voidPtr', [int8(FileName) 0]);
[FilePointer] = calllib('Nd2ReadSdk', 'Lim_FileOpenForReadUtf8', FileID);

if FilePointer.isNull
    error('SeqInfo:CannotOpenFile', ...
        ['Lim_FileOpenForReadUtf8 could not open "%s". Check that the file exists, ', ...
        'is a readable ND2 file, and is not locked by another program.'], FileName);
end

% Close the file however this function exits.
CloseOnExit = onCleanup(@() ND2Close(FilePointer));

FrameMetadata = calllib('Nd2ReadSdk', 'Lim_FileGetFrameMetadata', FilePointer,0);
FrameMetadataJson = ND2ReadString(FrameMetadata, 'uint8Ptr');
FrameMetadataStru=jsondecode(FrameMetadataJson);

% The free was itself an overrun: re-declaring the string as 'voidPtr' with the
% same element count made calllib marshal eight bytes per element.
ND2FreeString(FrameMetadata, 'uint8Ptr');

if FrameMetadataStru.contents.channelCount==1
    SeqTime=zeros(size(Num,2),1);
    SeqPosition=zeros(size(Num,2),3);
elseif FrameMetadataStru.contents.channelCount>1
    SeqTime=cell(0);
    SeqPosition=cell(0);
    for j=1:FrameMetadataStru.contents.channelCount
        SeqTime{j}=zeros(size(Num,2),1);
        SeqPosition{j}=zeros(size(Num,2),3);
    end
else
end

for i=1:size(Num,2)
    
    % This loop also reused TestLength from the frame 0 probe above, so a frame
    % whose metadata was longer produced an empty index and an error out of
    % jsondecode. Finding the terminator per frame removes that too.
    FrameMetadata = calllib('Nd2ReadSdk', 'Lim_FileGetFrameMetadata', FilePointer,Num(i)-1);
    FrameMetadataJson = ND2ReadString(FrameMetadata, 'uint8Ptr');
    FrameMetadataStru=jsondecode(FrameMetadataJson);
    ND2FreeString(FrameMetadata, 'uint8Ptr');
 
    if FrameMetadataStru.contents.channelCount==1
        SeqTime(i)=FrameMetadataStru.channels.time.relativeTimeMs;
        SeqPosition(i,:)=FrameMetadataStru.channels.position.stagePositionUm';
    elseif FrameMetadataStru.contents.channelCount>1
        for j=1:FrameMetadataStru.contents.channelCount
            SeqTime{j}(i)=FrameMetadataStru.channels(j).time.relativeTimeMs;
            SeqPosition{j}(i,:)=FrameMetadataStru.channels(j).position.stagePositionUm';
        end
    else
    end
    
    DisplayBar(i, size(Num,2));
    
end

% CloseOnExit calls ND2Close(FilePointer) here. Do not add an explicit
% ND2Close as well; closing the same handle twice is undefined behaviour.

end

