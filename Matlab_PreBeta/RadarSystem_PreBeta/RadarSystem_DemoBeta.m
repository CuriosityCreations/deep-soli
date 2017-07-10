% This simple example demos the usage of the Matlab Sensing Interface v5.0
% It currently runs with the BGT60TR24B v8 board.


%% cleanup and init
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
clc
disp('******************************************************************');
addpath('..\RadarSystemImplementation'); % add Matlab API 5.0
clear all %#ok<CLSCR>
close all
resetRS; % close and delete ports


%% setup object and show properties
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
szPort = findRSPort; % scan all available ports
oRS = RadarSystem(szPort); % setup object and connect to board
disp('oRS object - properties before set block:');
oRS %#ok<NOPTS>


%% Settings  -- Mike suggested 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
oRS.fLoFrequency = oRS.fMinFMCWFrequency+1000;    % 57Ghz
oRS.fHiFrequency = oRS.fMaxFMCWFrequency-0;       % 64Ghz
oRS.sDirection = 'up-chirp'; % 'up-chirp'/'alternating'
oRS.fTXPower = 0.33; % 10
oRS.fSamplingRate = 1000000;  % 1Mhz
oRS.uNumChirpsPerFrame = 16;
oRS.uNumSamplesPerChirp = 64;
oRS.sRXMask = '1111';
oRS.sTXMode = 'single';
oRS.uHP_Gain=[0 0 0 0];     % <0: 18db>, 1: 30db
oRS.uHP_Cutoff=[2 2 2 2];   % 000: 35db, 001: 75db, <010: 120db>, 011: 150db
oRS.uVGA_Gain=[3 3 3 3];    % 0000: 0, 0110: 30db
disp('oRS object - properties after set block:');
oRS %#ok<NOPTS>


%% process loop
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
hTime=figure;
data = [];
count = 0;
while ishandle(hTime) % while the output window is still open
    count = count+1
    % trigger radar chirp and get radar raw dat0a
    oRS.startRadarOperation;
    
    % plot received data
    mxRawData = oRS.frameData(1).data;
    data = [data, mxRawData];
    if (count==1000)
        break;
    end
    % plot the data
    figure(hTime)
    clf
    hold on
    plot([mxRawData(:,:,1),mxRawData(:,:,2),mxRawData(:,:,3)]);
    v=axis;
    axis([v(1:2) 0 1]);
    title('Time Data')
    drawnow
end % end loop
