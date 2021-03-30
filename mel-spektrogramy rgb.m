% Uses VOICEBOX
clear, close all, clc

inputSoundDir = 'C:/Users/User/Desktop/spektrogramy';
outputSpectrogramDir = 'C:/Users/User/Desktop/mel-spektrogramy rgb';
dataFileName = 'Spectrograms_Test.h5';

fs = 48000;

frame_dur = 0.04;   % Frame duration in sec.
frame_inc = 0.02;  % Hop duration in sec.
n_channels = 150;  % Number of channels in a filterbank
n_timeframes = 7/frame_inc - 1;

key = 'pchmdD'; % Mel-frequency spectrogram

f_low = 100;        % Low-frequency limit in Hz
f_high = 20000;     % High-frequency limit in Hz
db_range = 90;      % dB-range relative to peak

ninc=round(frame_inc*fs);   % Frame increment (in samples)
nwin=round(frame_dur*fs);   % Frame length (in samples)
win=hamming(nwin);          % Analysis window
k=0.5*fs*sum(win.^2);       % Scale factor to convert to power/Hz


% % Plot Gammatone filter-bank characteristics
% fl = f_low/fs;
% fh = f_high/fs;
% 
% v_melbankm(n_channels,1024,fs,fl,fh);


%% Identify File Names
[fileNames, N] = getFileNames(inputSoundDir);



%% Main Loop ==============================================================
tStart = tic;
disp('Generating spectrograms...')

images = zeros(N, n_channels, n_timeframes, 3);
labels = zeros(N,1);
parfor ii = 1:N % Loop across files

    fname = fullfile(inputSoundDir,fileNames{ii});
%     disp(' ' );
%     disp(['Progress: ',num2str(ii),' out of ',num2str(N)])
%     disp(fname);

    %% Open Audio File
    [xy, fs] = audioread(fname);
    xy = xy - ones(size(xy))*diag(mean(xy)); % Remove DC offset  
    x = xy(:,1);
    y = xy(:,2);    

    %% Mid-Side Processing   
    m = xy * [1; 1]; % m-signal
    s = xy * [1; -1]; % s-signal
    m = m - mean(m); % Remove DC offset

    % Test signal
    % t = 0:1/fs:7;
    % x = 0.3*(sin(2*pi*1000*t)+sin(2*pi*10000*t)+sin(2*pi*19500*t))+0.5;
    
    %% Spectrograms
  
    input_signal = x;
    % Calculate spectrum array                
    sf=abs(v_rfft(v_enframe(input_signal,win,ninc),nwin,2)).^2/k; 
    [t_x,f_x,b_x] = v_spgrambw(sf,[fs/ninc 0.5*(nwin+1)/fs fs/nwin],key,...
        200, [f_low (f_high-f_low)/(n_channels-1) f_high], ...
        db_range);  % Plot spectrum array - key 'g'
    % pbaspect([1 1 1])
    % axis normal % Revert aspec ration to normal
    
    input_signal = y;
    % Calculate spectrum array                
    sf=abs(v_rfft(v_enframe(input_signal,win,ninc),nwin,2)).^2/k; 
    [t_y,f_y,b_y] = v_spgrambw(sf,[fs/ninc 0.5*(nwin+1)/fs fs/nwin],key,...
        200, [f_low (f_high-f_low)/(n_channels-1) f_high], ...
        db_range);  % Plot spectrum array - key 'g'
    % pbaspect([1 1 1])
    % axis normal % Revert aspec ration to normal
 
    input_signal = m;
    % Calculate spectrum array                
    sf=abs(v_rfft(v_enframe(input_signal,win,ninc),nwin,2)).^2/k; 
    [t_m,f_m,b_m] = v_spgrambw(sf,[fs/ninc 0.5*(nwin+1)/fs fs/nwin],key,...
        200, [f_low (f_high-f_low)/(n_channels-1) f_high], ...
        db_range);  % Plot spectrum array - key 'g'
    % pbaspect([1 1 1])
    % axis normal % Revert aspec ration to normal    
    
    %% Convert to RGB Image
    
    % Scale
    max_val = max([max(b_x(:)),max(b_y(:)),max(b_m(:))]);
    min_val = min([min(b_x(:)),min(b_y(:)),min(b_m(:))]);
    
    r_ch = (b_x - min_val)/(max_val-min_val);
    g_ch = (b_y - min_val)/(max_val-min_val);
    b_ch = (b_m - min_val)/(max_val-min_val);
       
    imageRGB = cat(3,flipud(r_ch'),flipud(g_ch'),flipud(b_ch'));
        
    % Assign image to a 'big' matrix
    images(ii, :, :) = imageRGB;
    
    scene = fname(end-5:end-4);
    
    if scene == 'FB'
        labels(ii) = 0;
    end
    
    if scene == 'BF'
        labels(ii) = 1;
    end 
    
end % End of loop across files 



%% Save data

% Save spectrograms
h5create(fullfile(outputSpectrogramDir,dataFileName),...
    '/spectrograms', size(images))
h5write(fullfile(outputSpectrogramDir,dataFileName),... 
    '/spectrograms', images)

% Save-append labels
labels = int16(labels);
h5create(fullfile(outputSpectrogramDir,dataFileName),...
    '/labels', size(labels))
h5write(fullfile(outputSpectrogramDir,dataFileName),... 
    '/labels', labels)

%% Load data
% h5disp(fullfile(outputSpectrogramDir,dataFileName))


%% Finalize
tEnd = toc(tStart);

disp('Spectrograms generated.')
fprintf('%d minutes and %f seconds\n', floor(tEnd/60), rem(tEnd,60));
