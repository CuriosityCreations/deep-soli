function message = getProtocolErrorMessage(errorCode)

switch (errorCode)
    
    case hex2dec('0000')
        message = 'Everything is allright.';
        
    case hex2dec('0001')
        message = 'A timeout has occurred.';
        
    case hex2dec('0002')
        message = 'The start byte of the message was incorrect.';
        
    case hex2dec('0003')
        message = 'There is no module with the requested ID';
        
    case hex2dec('0004')
        message = 'There is no instance with the requested ID.';
        
    case hex2dec('0005')
        message = 'A message with no payload is not supported.';
        
    case hex2dec('0006')
        message = 'There is not enough memory to store the payload.';
        
    case hex2dec('0007')
        message = 'The message did not end with the expected sequence.';
        
    otherwise
        message = 'Unknown error';
end
end

