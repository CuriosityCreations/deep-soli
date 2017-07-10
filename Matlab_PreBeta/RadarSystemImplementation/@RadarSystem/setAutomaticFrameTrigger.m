function setAutomaticFrameTrigger(obj, fFrameInterval)

if nargin<2
    fFrameInterval = obj.fFrameInterval;
end

message = [typecast(cast(MessageType.SetAutomaticTrigger, 'uint8'),'uint8'), ...
    typecast(cast(fFrameInterval, 'single'),'uint8')];

obj.sendMessage(message);
obj.waitForStatus;
