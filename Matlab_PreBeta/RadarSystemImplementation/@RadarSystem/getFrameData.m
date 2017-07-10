function getFrameData(obj)

message = [typecast(cast(MessageType.GetFrameData, 'uint8'),'uint8'), ...
           typecast(cast(obj.uGetFrameDataTimeOut, 'uint32'),'uint8')];

obj.sendMessage(message)
obj.receiveMessage;
obj.waitForStatus;
