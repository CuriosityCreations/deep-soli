function RX_startbyte = receiveMessage(obj)

% receive header data
RX_startbyte = fread(obj.hSerialPort, 1, 'uint8');
if isempty(RX_startbyte) % e.g. by timeout
    return
end

RX_endpointID = fread(obj.hSerialPort, 1, 'uint8');

if (RX_startbyte == obj.cStartbyteMessage)
    % receive payload of message
    RX_payloadSize	= fread(obj.hSerialPort, 1, 'uint16');
    RX_payload = cast(fread(obj.hSerialPort, RX_payloadSize, 'uint8'),'uint8')';

    % receive end of message sequence and check if it is correct
    endOfMessageSequence = fread(obj.hSerialPort, 1, 'uint16');
    if (endOfMessageSequence == obj.cEndOfMessage)
        
        % check the module id for the received message
        if (RX_endpointID == obj.cEndpointID)
            obj.processPayload(RX_payload);
            return
        elseif (RX_endpointID == 2)
            obj.processPayload(RX_payload,2);
        else
            fprintf('[RadarSystem.receiveMessage] Received message from unknown Endpoint 0x%02x containing %i bytes.\n', ...
                RX_endpointID, RX_payloadSize);
        end
    
    else
        disp('[RadarSystem.receiveMessage] Error: Bad message end sequence received')
    end
    
elseif (RX_startbyte == obj.cStartbyteError)
    % if this is an error message, receive error code and wait for tail
    RX_errorCode	= fread(obj.hSerialPort, 1, 'uint16');

    if (RX_errorCode ~= 0)
        % check the endpoint id for the received error
        if (RX_endpointID == 0)
            errorMessage = RadarSystem.getProtocolErrorMessage(RX_errorCode);
        elseif (RX_endpointID == obj.cEndpointID)
            errorMessage = RadarSystem.getRadarSystemErrorMessage(RX_errorCode);
        else
            errorMessage = '[The endpoint is not known. No error text available.]';
        end
        
        fprintf('[RadarSystem.receiveMessage] Endpoint 0x%02x reported error code 0x%04x. -> %s\n', ...
            RX_endpointID, RX_errorCode, errorMessage);
    end

else
    % if the startbyte is unexpected, reset protocol state
    disp('[RadarSystem.receiveMessage] Error: Bad message start byte received')
    pause(.5);
    if (obj.hSerialPort.BytesAvailable)
        fread(obj.hSerialPort, obj.hSerialPort.BytesAvailable, 'uint8'); % flush serial buffer
    end
    return
end

end
