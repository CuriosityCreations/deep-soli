function setTXMode(obj)

message = [typecast(cast(MessageType.SetTXMode, 'uint8'),'uint8'), ...
    typecast(cast(obj.m_uTXMode, 'uint8'),'uint8')];

obj.sendMessage(message);
obj.waitForStatus;
