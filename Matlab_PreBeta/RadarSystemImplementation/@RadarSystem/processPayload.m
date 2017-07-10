
function processPayload(obj, payload, EndPointID)

if(nargin==2)
    switch (payload(1))

        % FrameData
        % ---------------
        case MessageType.FrameData
            % remove first byte from payload
            payload = payload(2:end);

    %         if(length(payload)==4) %<PK> baseband processing
    %             for i=1:4        
    %                 p(i)=typecast(payload(i), 'uint8');
    %             end
    %             obj.m_uHP_Gain=floor(p/128);
    %             obj.m_uHP_Cutoff=floor((p-128*obj.m_uHP_Gain)/16);
    %             obj.m_uVGA_Gain=p-128*obj.m_uHP_Gain-16*obj.m_uHP_Cutoff;
    %         end

            if (length(payload) >= 10)
                uFrameIndex = typecast(payload(1:4), 'uint32');
                uNumChirps = typecast(payload(5:6), 'uint16');
                uNumSamplesPerChirp = typecast(payload(7:8), 'uint16');
                uNumRXAntennas = typecast(payload(9:9), 'uint8');
                uResolution = typecast(payload(10:10), 'uint8');

                % calculate expected message size
                uTotalSamples = uNumChirps * uNumSamplesPerChirp * cast(uNumRXAntennas,'uint16');

                uExpectedMessageSize = 10 + bitshift(uTotalSamples * cast(uResolution,'uint16'), -3)...
                    + cast(bitand(uTotalSamples * cast(uResolution,'uint16'), 7)>0 ,'uint16');
                if (length(payload) == uExpectedMessageSize)
                    payload = payload(11:end);

                    capture.uFrameIndex = uFrameIndex ;
                    capture.uNumChirps = uNumChirps ;
                    capture.uNumSamplesPerChirp = uNumSamplesPerChirp ;
                    capture.uNumRXAntennas = uNumRXAntennas ;
                    capture.uResolution = uResolution ;

                    % convert received data to float (real and imaginary part are interleaved -> convert to complex)
                    data(1:2:uTotalSamples) = cast(payload(1:3:end), 'double') + cast(bitand(payload(2:3:end), 15, 'uint8'), 'double') * 256;
                    data(2:2:uTotalSamples) = cast(bitand(payload(2:3:end), 240, 'uint8'), 'double') / 16 + cast(payload(3:3:end), 'double') * 16;
                    data = reshape(data, uNumSamplesPerChirp, uNumRXAntennas, uNumChirps);
                    capture.data = data ./ 4095;

                    obj.frameData(obj.m_uFrameCounter) = capture;
                    obj.m_uFrameCounter = obj.m_uFrameCounter+1;
                end
            end

        % SetDeviceInfo
        % ---------------
        case MessageType.SetDeviceInfo
            % remove first byte from payload
            payload = payload(2:end);

            if (length(payload) >= 16)
                % read version number
                obj.uMajorVersionHW = typecast(payload( 1: 1), 'uint8');
                obj.uMinorVersionHW = typecast(payload( 2: 2), 'uint8');
                obj.uMajorVersionFW = typecast(payload( 3: 3), 'uint8');
                obj.uMinorVersionFW = typecast(payload( 4: 4), 'uint8');

                % read device properties
                obj.uNumberOfAntennasTX = typecast(payload( 5: 5), 'uint8');
                obj.uNumberOfAntennasRX = typecast(payload( 6: 6), 'uint8');
                obj.fMinFMCWFrequency = typecast(payload( 7:10), 'single');
                obj.fMaxFMCWFrequency = typecast(payload(11:14), 'single');
                obj.uNumberOfPowerSteps = typecast(payload(15:15), 'uint8');

                obj.sDeviceDescription = char(payload(16:end-1));

            end

        % SetRFConfig
        % ------------------
        case MessageType.SetRFConfig
            if (length(payload) == 14)
                payload = payload(2:end);
                obj.m_fLoFrequency = typecast(payload( 1: 4), 'single');
                obj.m_fHiFrequency = typecast(payload( 5: 8), 'single');
                obj.m_uDirection = typecast(payload(9:9), 'uint8');
                obj.m_fTXPower = typecast(payload(10:13), 'single');
            end

        % SetADCConfig
        % ------------------
        case MessageType.SetADCConfig
            if (length(payload) == 7)
                payload = payload(2:end);
                obj.m_fSamplingRate = typecast(payload(1:4), 'single');
                obj.m_uResolution = typecast(payload(5:5), 'uint8');
                obj.m_uCalibrationMode = typecast(payload(6:6), 'uint8');
            end

        % SetFrameFormat
        % ------------------
        case MessageType.SetFrameFormat
            if (length(payload) == 6)
                payload = payload(2:end);
                obj.m_uNumChirpsPerFrame = typecast(payload(1:2), 'uint16');
                obj.m_uNumSamplesPerChirp = typecast(payload(3:4), 'uint16');
                obj.m_uRXMask = typecast(payload(5:5), 'uint8');
            end

        % SetTXMode
        % ------------------
        case MessageType.SetTXMode
            if (length(payload) == 2)
                payload = payload(2:end);
                obj.m_uTXMode = typecast(payload(1:1), 'uint8');
            end

        % SetChirpTiming
        % ------------------
        case MessageType.SetChirpTiming
            if (length(payload) == 9) || (length(payload) == 13)
                payload = payload(2:end);
                obj.fChirpDuration = typecast(payload(1:4), 'single');
                obj.fBandwidthPerSecond = typecast(payload(5:8), 'single');
                if (length(payload) == 12)
                    obj.fMinFrameInterval = typecast(payload(9:12), 'single');
                end
            end
    end
else
    switch (payload(1))

        case MessageType.FrameData
            % remove first byte from payload
            payload = payload(2:end);
            if((length(payload)==4)&&(EndPointID==2))
                for i=1:4        
                    p(i)=typecast(payload(i), 'uint8');
                end
                obj.m_uHP_Gain=floor(p/128);
                obj.m_uHP_Cutoff=floor((p-128*obj.m_uHP_Gain)/16);
                obj.m_uVGA_Gain=p-128*obj.m_uHP_Gain-16*obj.m_uHP_Cutoff;
            end  
    end
end


