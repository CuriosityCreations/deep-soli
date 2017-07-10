% This simple example demos the usage of the Matlab Sensing Interface v5.0
% It currently runs with the BGT60TR24B v8 board.

% Using recorded data !!!
%% cleanup and init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
clear  %#ok<CLSCR>
close all

disp('******************************************************************');

%% process loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hTime=figure;
load('shake.mat');
load('none.mat');
data_index = 1;
chrip = 16;
channel = 4;
[c,dim,d] = size(shake);

% prepare for fft doppler
mxRawData_doppler=[];
for i = 1:16
    mxRawData_doppler = [mxRawData_doppler; shake(:,:,i)];
end

while ishandle(hTime) && data_index <= dim/4 % while the output window is still open
    % input recorded data
    mxRawData = shake(:,4*data_index-3:4*data_index,:);
    mxRawDatachirp = [];
    rangefft = [];
    dopplerfft = [];
    % processing
    for i = 1: channel 
        re_mxRawData = reshape(mxRawData(:,i,:),1,chrip * 64);
        mxRawDatachirp = [mxRawDatachirp; re_mxRawData];
        rangefft = [rangefft; getnormalize(log(abs(fftshift(fft(re_mxRawData))))).^2];
        dopplerfft = [dopplerfft; getnormalize(log(abs(fftshift(fft(mxRawData_doppler(data_index,(channel-1)*1000+1:channel*1000)))))).^2];
    end
    data_index = data_index + 1;
    
    % showing result
    figure(hTime)
    clf
    for i = 1: channel 
        subplot(2,2,1);
        hold on
        plot(mxRawDatachirp(i,:));
        v=axis;
        axis([v(1:2) 0 1]);
        title('Time Data')
        subplot(2,2,2);
        hold on
        plot(rangefft(1,:));
        %v=axis;
        %axis([v(1:2) 0 1]);
        title('FFT Data - Range')
        subplot(2,2,3);
        hold on
        plot(dopplerfft(1,:));
        %v=axis;
        %axis([v(1:2) 0 1]);
        title('FFT Data - Range')
    end
    
    drawnow
    
end % end loop
