% This enumeration defines IDs for all known protocol modules.
classdef MessageType < uint8
	enumeration
        FrameData           (hex2dec('00'))
        GetFrameData        (hex2dec('01'))
        SetAutomaticTrigger (hex2dec('02'))
        EnableTestMode      (hex2dec('03'))
        GetDeviceInfo       (hex2dec('10'))
        SetDeviceInfo       (hex2dec('11'))
        GetRFConfig         (hex2dec('12'))
        SetRFConfig         (hex2dec('13'))
        GetADCConfig        (hex2dec('14'))
        SetADCConfig        (hex2dec('15'))
        GetFrameFormat      (hex2dec('16'))
        SetFrameFormat      (hex2dec('17'))
        GetTXMode           (hex2dec('18'))
        SetTXMode           (hex2dec('19'))
        GetChirpTiming      (hex2dec('1A'))
        SetChirpTiming      (hex2dec('1B'))
        GetChipCondition    (hex2dec('1C'))
        SetChipCondition    (hex2dec('1D'))
	end
end	% end of class definition