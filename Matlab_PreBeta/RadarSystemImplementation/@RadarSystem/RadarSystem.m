classdef RadarSystem < handle

    %% methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        % This is the constructor. You must provide the name of a COM port.
        function obj = RadarSystem(sPortName)
            % create an object to access the com port
            obj.hSerialPort = serial(sPortName);

            % open the serial connection:
            try
                obj.hSerialPort.InputBufferSize = 65536*8;
                obj.hSerialPort.OutputBufferSize = 65536*8;
                obj.hSerialPort.Timeout = 5; % s
                fopen(obj.hSerialPort);
            catch
                disp('[RadarSystem.RadarSystem] Error: serial connection problem!');
                fclose(obj.hSerialPort);
                delete(obj.hSerialPort);
                return
            end

            % find radar system endpoints
            endpointIDs = obj.findEndpointID(hex2dec('69524452'));
            if (isempty(endpointIDs))
                disp('[RadarSystem.RadarSystem] Error: Connected device is not a radar system.')
                fclose(obj.hSerialPort);
                delete(obj.hSerialPort);
                return
            end

            % use the first endpoint that is a radar system
            obj.cEndpointID = endpointIDs(1);
            
            % query and display basic information
            obj.getDeviceInfo;
            obj.dispDeviceInfo;
            obj.setAutomaticFrameTrigger(0);

            % query all settings
            obj.getRFConfiguration;
            obj.getADCConfiguration;
            obj.getFrameFormat;
            obj.getTXMode;
            obj.getChirpTiming;
        end

        % This is the destructor. It closes the COM port and deletes the internal serial object.
        function delete(obj)
            if isvalid(obj.hSerialPort)
                fclose(obj.hSerialPort);
                delete(obj.hSerialPort);
            end
        end

        % These functions pass through the functions of the RadarSystem module of the Firmware.
        dispDeviceInfo(obj)
        startRadarOperation(obj)
    end % methods

    methods (Hidden) % Explicit useage with sParams object is prohibited with API 5.0
        % These functions pass through the functions of the RadarSystem module of the Firmware.
        getFrameData(obj)
        setAutomaticFrameTrigger(obj, fFrameInterval)
        setRFConfiguration(obj)
        setADCConfiguration(obj)
        setFrameFormat(obj)
        setTXMode(obj)
        % baseband configuration functions <PK>
        setBaseBandConfiguration(obj) 
    end % methods, hidden
    
    methods (Access = private)
        % This function sends the payload through the COM port. A message header and message tail is added.
        sendMessage(obj, payload,EndPointID)
        
        % This is the data receive and process functions.
        bError = receiveMessage(obj)
        processPayload(obj, payload, EndPointID)
        waitForStatus(obj)
        
        % These functions query parameters from the board to fill the object's member variables
        getDeviceInfo(obj)
        getRFConfiguration(obj)
        getADCConfiguration(obj)
        getFrameFormat(obj)
        getTXMode(obj)
        getChirpTiming(obj)
          
        % baseband configuration functions <PK>
        getBaseBandConfiguration(obj) 
              
        % allocate memory for the queried raw data
        % allocRawDataField(obj)

        % this function retrieves the endpoint table from the connected
        % device and returns the IDs of the endpoints that match the given
        % endpoint type
        endpointID = findEndpointID(obj, uEndpointType);

        % 
        flushSendError(obj)
    end % methods
    
    methods (Static, Access = private) % These return readable error messages for received error codes
        message = getProtocolErrorMessage(payload);
        message = getRadarSystemErrorMessage(payload);
    end % methods
    
    %% properties
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    properties (SetAccess = private)
        % device info
        sDeviceDescription % A string describing the device
        uMajorVersionHW % Major version of hardware
        uMinorVersionHW % Minor version of hardware
        uMajorVersionFW % Major version of firmware
        uMinorVersionFW % Minor version of firmware
        uNumberOfAntennasTX % Number of TX antennas present on hardware
        uNumberOfAntennasRX % Number of RX antennas present on hardware
        fMinFMCWFrequency % The minimum frequency for FMCW chirps in MHz supported by the hardware
        fMaxFMCWFrequency % The maximum frequency for FMCW chirps in MHz supported by the hardware
        uNumberOfPowerSteps
    end % properties, read only
    
    properties (Dependent)
        % RF config
        fLoFrequency % The lower FMCW frequency in GHz
        fHiFrequency % The upper FMCW frequency in GHz
        sDirection % % {'up-chirp' 'u' 0}: upchirp only, {'alternating' 'a' 1}: alternating up down
        fTXPower % The amount of sending energy (0...1)

        % ADC Config
        fSamplingRate % ADC sampling rate in Hz for IF signal sampling
        uResolution % Resolution of the ADC in bit
        uCalibrationMode % Turns on post calibration of ADC
        
        % RX Baseband Setting <PK>
        uHP_Gain; % HP_Gain for LNA: takes value of either 0:(18dB) or 1:(30dB).
        uHP_Cutoff; % HP filter cutoff freq: takes values from {0,1,2,3}, representing {35,75,120,150} in KHz.
        uVGA_Gain; % VGA Gain: takes values from {0,1,2,3,4,5,6}, representing {0,5,10,15,20,25,30} in dB.

    end % properties, dependent

%     properties
%         % frame format
%         fFrameInterval = 0.05; % in s
%     end % properties

    properties (Dependent)
        % frame format
%         uNumFrames % Number of frames per radar operation
        uNumChirpsPerFrame % Number of chirps in one frame
        uNumSamplesPerChirp % Number of samples per chirp (valid: 128, 256, 512, 1024, 2048)
        sRXMask % as a string i.e. 1010 starting with the highest antenna [RX4 RX3 RX2 RX1]

        % TX Mode
        sTXMode % {'single', 's' 0}: use only one TX, {'all', 'a' 1}: use all TX
    end % properties, dependent

    properties (SetAccess = private)
        % chirp timing
        fChirpDuration
        fBandwidthPerSecond % The change of frequency per second
        fMinFrameInterval
        
        % radar operation
        frameData = struct('uFrameIndex',{}, 'uNumChirps',{}, 'uNumSamplesPerChirp',{}, 'uNumRXAntennas',{}, 'uResolution',{}, 'data',{}) % Contains all recently received chirp data from the demo board, one block per chirp and antenna
    end
    
    % These properties the actual data to properties on the board
    properties (Access = private)
        % Automatic Frame Trigger
        m_fFrameInterval = 0;% Time from Chirp to Chirp in ms

        % RF config
        m_fLoFrequency % The lower FMCW frequency in GHz
        m_fHiFrequency % The upper FMCW frequency in GHz
        m_uDirection % 0: upchirp only, 1: alternating up down
        m_fTXPower % The amount of sending energy (0...1)

        % ADC Config
        m_fSamplingRate % ADC sampling rate in Hz for IF signal sampling
        m_uResolution % Resolution of the ADC in bit
        m_uCalibrationMode % Turns on post calibration of ADC

        % frame format
        m_uNumFrames = 1  % Number of frames per radar operation
        m_uNumChirpsPerFrame % Number of chirps in one frame
        m_uNumSamplesPerChirp % Number of samples per chirp (valid: 128, 256, 512, 1024, 2048)
        m_uRXMask % LSB is RX1, i.e. apply this bit pattern: RX4 RX3 RX2 RX1

        % TX Mode
        m_uTXMode % 0: use only one TX, 1: use all TX
                  
        % RX Baseband Setting <PK>
        m_uHP_Gain=[1 1 1 1]; % HP_Gain for LNA: takes value of either 0:(18dB) or 1:(30dB).
        m_uHP_Cutoff=[3 3 3 3]; % HP filter cutoff freq: takes values from {0,1,2,3}, representing {35,75,120,150} in KHz.
        m_uVGA_Gain=[6 6 6 6]; % VGA Gain: takes values from {0,1,2,3,4,5,6}, representing {0,5,10,15,20,25,30} in dB.

        % frame counter
        m_uFrameCounter % indicates next frame to be written during radar operation
    end % properties, private, hidden

    properties (Hidden)
        uGetFrameDataTimeOut = 1000*1000; % in us
        hSerialPort; % a handle to the serial port object used for communication
        cEndpointID;
    end

    properties (Access = private, Constant)
        uMajorVersionAPI = 5 % Major version of this API
        uMinorVersionAPI = 0 % Minor version of this API
        uProtocolVersion = 1 % Version number of protocol definiton, must be compatible to version on the board
        
        % constants that are part of protocol messages
        cStartbyteMessage = hex2dec('5A');
        cStartbyteError = hex2dec('5B');
        cEndOfMessage = hex2dec('E0DB');
    end % properties, private, constant, hidden
    
    
    %% set/get methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods % set/get
        % fLoFrequency
        function set.fLoFrequency(obj,val)
            obj.m_fLoFrequency = val;
            obj.setRFConfiguration;
            obj.getRFConfiguration;
        end
        
        function val = get.fLoFrequency(obj)
            val = obj.m_fLoFrequency;
        end
        
        % fHiFrequency
        function set.fHiFrequency(obj,val)
            obj.m_fHiFrequency = val;
            obj.setRFConfiguration;
            obj.getRFConfiguration;
        end
        
        function val = get.fHiFrequency(obj)
            val = obj.m_fHiFrequency;
        end
        
        % sDirection
        function set.sDirection(obj,val)
            switch(val)
                case{'up-chirp' 'u' 0}
                    obj.m_uDirection = 0;
                case{'alternating' 'a' 1}
                    obj.m_uDirection = 1;
                otherwise
                    return
            end
            obj.setRFConfiguration;
            obj.getRFConfiguration;
        end
        
        function val = get.sDirection(obj)
            if(obj.m_uDirection)
                val = 'alternating';
            else
                val = 'up-chirp';
            end
        end
        
        % fTXPower
        function set.fTXPower(obj,val)
            obj.m_fTXPower = val;
            obj.setRFConfiguration;
            obj.getRFConfiguration;
        end
        
        function val = get.fTXPower(obj)
            val = obj.m_fTXPower;
        end
        
        % fSamplingRate
        function set.fSamplingRate(obj,val)
            obj.m_fSamplingRate = val;
            obj.setADCConfiguration;
            obj.getADCConfiguration;
        end
        
        function val = get.fSamplingRate(obj)
            val = obj.m_fSamplingRate;
        end
        
        % uResolution
        function set.uResolution(obj,val)
            obj.m_uResolution = val;
            obj.setADCConfiguration;
            obj.getADCConfiguration;
        end
        
        function val = get.uResolution(obj)
            val = obj.m_uResolution;
        end
        
        % uCalibrationMode
        function set.uCalibrationMode(obj,val)
            obj.m_uCalibrationMode = val;
            obj.setADCConfiguration;
            obj.getADCConfiguration;
        end
        
        function val = get.uCalibrationMode(obj)
            val = obj.m_uCalibrationMode;
        end
        
        % uHP_Gain
        function set.uHP_Gain(obj,val)
            obj.m_uHP_Gain=val;
            obj.setBaseBandConfiguration;
            obj.getBaseBandConfiguration;
        end
             
        function val = get.uHP_Gain(obj)
            val = obj.m_uHP_Gain;
        end
             
        function set.uHP_Cutoff(obj,val)
            obj.m_uHP_Cutoff=val;
            obj.setBaseBandConfiguration;
            obj.getBaseBandConfiguration;
        end
             
        function val = get.uHP_Cutoff(obj)
            val = obj.m_uHP_Cutoff;
        end        
        
        function set.uVGA_Gain(obj,val)
            obj.m_uVGA_Gain=val;
            obj.setBaseBandConfiguration;
            obj.getBaseBandConfiguration;
        end
             
        function val = get.uVGA_Gain(obj)
            val = obj.m_uVGA_Gain;
        end                
        
%         % uNumFrames
%         function set.uNumFrames(obj,val)
%             obj.m_uNumFrames = val;
%         end
%         
%         function val = get.uNumFrames(obj)
%             val = obj.m_uNumFrames;
%         end
        
        % uNumChirpsPerFrame
        function set.uNumChirpsPerFrame(obj,val)
            obj.m_uNumChirpsPerFrame = val;
            obj.setFrameFormat;
            obj.getFrameFormat;
        end
        
        function val = get.uNumChirpsPerFrame(obj)
            val = obj.m_uNumChirpsPerFrame;
        end

        % uNumSamplesPerChirp
        function set.uNumSamplesPerChirp(obj,val)
            obj.m_uNumSamplesPerChirp = val;
            obj.setFrameFormat;
            obj.getFrameFormat;
        end
        
        function val = get.uNumSamplesPerChirp(obj)
            val = obj.m_uNumSamplesPerChirp;
        end
        
        % sRXMask
        function set.sRXMask(obj,val)
            if ischar(val)
                obj.m_uRXMask = bin2dec(val);
            else
                obj.m_uRXMask = val;
            end
            obj.setFrameFormat;
            obj.getFrameFormat;
        end
        
        function val = get.sRXMask(obj)
            val = dec2bin(obj.m_uRXMask,4);
        end
        
        % sTXMode
        function set.sTXMode(obj,val)
            switch(val)
                case{'single', 's' 0}
                    obj.m_uTXMode= 0;
                case{'all', 'a' 1}
                    obj.m_uTXMode= 1;
                otherwise
                    return
            end
            obj.setTXMode;
            obj.getTXMode;
        end
        
        function val = get.sTXMode(obj)
            if(obj.m_uTXMode)
                val = 'all';
            else
                val = 'single';
            end
        end
        
    end % set/get methods
    
end
