function sendMessage(obj, payload, EndPointID)
    try
        if(nargin==2)
            message = [ ...
                typecast(cast(obj.cStartbyteMessage,    'uint8'),'uint8'),  ... % Every message starts with this data
                typecast(cast(obj.cEndpointID,          'uint8'),'uint8'),  ... % Send endpoint ID as 8 bit integer
                typecast(cast(length(payload),          'uint16'),'uint8'), ... % Send size of payload as 16 bit integer (so maximum payload size is 64kb)
                typecast(cast(payload,                  'uint8'),'uint8'),  ... % Send payload
                typecast(cast(obj.cEndOfMessage,        'uint16'),'uint8'), ... % Every message ends with this data
                ];
        else
            message = [ ...
                typecast(cast(obj.cStartbyteMessage,    'uint8'),'uint8'),  ... % Every message starts with this data
                typecast(cast(EndPointID,               'uint8'),'uint8'),  ... % Send endpoint ID as 8 bit integer
                typecast(cast(length(payload),          'uint16'),'uint8'), ... % Send size of payload as 16 bit integer (so maximum payload size is 64kb)
                typecast(cast(payload,                  'uint8'),'uint8'),  ... % Send payload
                typecast(cast(obj.cEndOfMessage,        'uint16'),'uint8'), ... % Every message ends with this data
                ];
        end

        fwrite(obj.hSerialPort, message, 'uint8'); % write message to serial port
    catch
        disp('[RadarSystem.sendMessage] Error: Unable to write to USB!')
    end
end
