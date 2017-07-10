function setBaseBandConfiguration(obj)

payload=128*obj.m_uHP_Gain+16*obj.m_uHP_Cutoff+obj.m_uVGA_Gain;
if(length(payload)~=4)
    error('length of payload needs to be 4');
end

message = [typecast(cast(MessageType.GetFrameData, 'uint8'),'uint8'), ...
    typecast(cast(payload(1), 'uint8'),'uint8'), ...
    typecast(cast(payload(2), 'uint8'),'uint8'), ...
    typecast(cast(payload(3), 'uint8'),'uint8'), ...
    typecast(cast(payload(4), 'uint8'),'uint8')];

obj.sendMessage(message,2);
obj.waitForStatus;
