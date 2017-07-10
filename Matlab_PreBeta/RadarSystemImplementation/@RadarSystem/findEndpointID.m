function endpointID = findEndpointID(obj, uEndpointType)

    try
        % send message to query endpoint list from the device
        % ---------------------------------------------------
        message = [ ...
            typecast(cast(obj.cStartbyteMessage,    'uint8'),'uint8'),  ... % Every message starts with this data
            typecast(cast(0,                        'uint8'),'uint8'),  ... % Send endpoint ID as 8 bit integer
            typecast(cast(1,                        'uint16'),'uint8'), ... % Send size of payload as 16 bit integer (so maximum payload size is 64kb)
            typecast(cast(0,                        'uint8'),'uint8'),  ... % Send payload
            typecast(cast(obj.cEndOfMessage,        'uint16'),'uint8'), ... % Every message ends with this data
            ];

        fwrite(obj.hSerialPort, message, 'uint8'); % write message to serial port

        % read endpoint table from device
        % -------------------------------
        % receive header data
        RX_startbyte = fread(obj.hSerialPort, 1, 'uint8');
        if isempty(RX_startbyte) % e.g. by timeout
            disp('[RadarSystem.findEndpointID] Error: Could not get endpoint table!')
            return
        end

        RX_endpointID = fread(obj.hSerialPort, 1, 'uint8');

        if ((RX_startbyte == obj.cStartbyteMessage) && (RX_endpointID == 0))
        
            % receive payload of message
            RX_payloadSize	= fread(obj.hSerialPort, 1, 'uint16');
            RX_payload = cast(fread(obj.hSerialPort, RX_payloadSize, 'uint8'),'uint8')';

            % receive end of message sequence and check if it is correct
            endOfMessageSequence = fread(obj.hSerialPort, 1, 'uint16');
            
            if (endOfMessageSequence ~= obj.cEndOfMessage)
                disp('[RadarSystem.findEndpointID] Error: Bad message end sequence received')
                return;
            end

            % now parse the payload, check command byte and size
            numEndpoints = RX_payload(2);

            if ((RX_payload(1) ~= 0) && (RX_payloadSize == 2 + 6 * numEndpoints))
                disp('[RadarSystem.findEndpointID] Error: Could not get endpoint table!')
                return;
            end
                
            EndpointTypes = zeros(1,numEndpoints);
            EndpointVersions = zeros(1, numEndpoints);
            
            for i = 1:numEndpoints
                baseindex = (i-1)*6 + 2;
                EndpointTypes(i) = typecast(RX_payload( baseindex + 1: baseindex + 4), 'uint32');
                EndpointVersions(i) = typecast(RX_payload( baseindex + 5: baseindex + 6), 'uint16');
            end

            endpointID = find(EndpointTypes == uEndpointType);
        end
        
        % flush serial buffer, because there should be a status message
        % available now
        fread(obj.hSerialPort, obj.hSerialPort.BytesAvailable, 'uint8');

    catch
        disp('[RadarSystem.findEndpointID] Error: Unable to write to USB!')
    end

end

