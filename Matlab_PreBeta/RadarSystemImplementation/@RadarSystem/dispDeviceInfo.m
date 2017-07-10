function dispDeviceInfo(obj)

    fprintf('\nMATLAB API Version:    %i.%i\n', obj.uMajorVersionAPI, obj.uMinorVersionAPI);
    fprintf('Device:                %s\n', obj.sDeviceDescription);
    fprintf('Hardware Version:      %i.%i\n', obj.uMajorVersionHW, obj.uMinorVersionHW);
    fprintf('Firmware Version:      %i.%i\n', obj.uMajorVersionFW, obj.uMinorVersionFW);
    fprintf('Number of TX antennas: %i\n', obj.uNumberOfAntennasTX);
    fprintf('Number of RX antennas: %i\n', obj.uNumberOfAntennasRX);
    fprintf('FMCW Frequency Range:  %g ... %g MHz\n', obj.fMinFMCWFrequency, obj.fMaxFMCWFrequency);
    fprintf('Number of Power Steps: %i\n\n', obj.uNumberOfPowerSteps);

end
