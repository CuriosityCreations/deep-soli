function message = getRadarSystemErrorMessage(errorCode)

switch (errorCode)
    
    case hex2dec('0000')
        message = 'Everything is allright.';
       
    case hex2dec('0001')
        message = 'Device does not exist.';

    case hex2dec('0002')
        message = 'Device already open.';

    case hex2dec('0003')
        message = 'Connection lost.';

    case hex2dec('0004')
        message = 'Unknown configuration type.';

    case hex2dec('0005')
        message = 'Read only configuration type.';

    case hex2dec('0006')
        message = 'Write only configuration type.';

    case hex2dec('0007')
        message = 'Antenna does not exist.';
    
    case hex2dec('0008')
        message = 'Frequency out of range.';
    
    case hex2dec('0009')
        message = 'Power out of range.';
    
    case hex2dec('000A')
        message = 'Unknown direction type.';
    
    case hex2dec('000B')
        message = 'Samplerate out of range.';
    
    case hex2dec('000C')
        message = 'Unsupported resolution.';
    
    case hex2dec('000D')
        message = 'Unsupported calibration mode.';
    
	
    case hex2dec('000E')
        message = 'Out of Memory.';
	  
    case hex2dec('000F')
        message = 'Unknown TX type.';
    
    case hex2dec('0010')
        message = 'Unsupported frame interval.';
    
    case hex2dec('0011')
        message = 'Bad frame format.';
    
    case hex2dec('0012')
        message = 'Busy.';
    
    case hex2dec('0013')
        message = 'Time out.';
    
    case hex2dec('0014')
        message = 'Bad expert settings.';

    case hex2dec('0015')
        message = 'Calibration failed.';
    
    case hex2dec('FFFE')
        message = 'Unknown error.';
        
    case hex2dec('FFFF')
        message = 'Invalid command.';
end
end
