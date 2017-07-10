function setFrameFormat(obj)

message = [typecast(cast(MessageType.SetFrameFormat, 'uint8'),'uint8'), ...
    typecast(cast(obj.m_uNumChirpsPerFrame, 'uint16'),'uint8'), ...
    typecast(cast(obj.m_uNumSamplesPerChirp, 'uint16'),'uint8'), ...
    typecast(cast(obj.m_uRXMask, 'uint8'),'uint8')];

obj.sendMessage(message);
obj.waitForStatus;

% if (nargin>1)
%     obj.queryFrameSettings;
% end
