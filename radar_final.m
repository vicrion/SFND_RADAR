%% Init and waveform gen
clear;
close all;
clc;

c = 3e8;

% input
fc = 77e9;
R_max = 200;
d_res = 1;
v_max = 100;
v_res = 3;

% sim target
R_target = 100;
v_target = 30;

% FMCW Waveform
Nd = 128;
Nr = 1024;

B = c / (2 * d_res);
fprintf("B=%d (Hz).\n", B);

Tchirp = 5.5 * 2 * R_max / c;
fprintf("T_{chirp}=%d (sec).\n", Tchirp);

slope = B / Tchirp;
fprintf("Slope=%d (Hz/sec).\n", slope);

t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples

r_t = R_target + v_target * t; % target range using vel model
td = 2 * r_t / c; % propagate time
Tx = cos(2 * pi * (fc * t + (slope * t.^2) / 2));
Rx = cos(2 * pi * (fc * (t - td) + (slope * (t - td).^2) / 2) );
Mix = Tx.*Rx;

f = linspace(0, Nr/2 - 1, Nr/2) * (1 / Tchirp);
range_axis = (c * f) / (2 * slope);

figure(1);
tmp_reshaped = reshape(Mix, [Nr, Nd]);
tmp = tmp_reshaped(:, 1);
tmp_fft = fft(tmp, Nr);
tmp_half = tmp_fft(1:Nr/2);
plot(range_axis, abs(tmp_half/max(tmp_half) ) );
xlabel("Range, m"); ylabel("Amplitude"); 
xlim([0, R_max]);
title("Debug: Range-FFT-1");

%% Range-FFT
Mix_reshaped = reshape(Mix, [Nr, Nd]);
signal_fft = fft(Mix_reshaped, Nr); % FFT along the range bins
signal_fft = signal_fft / max(max(abs(signal_fft)));
signal_fft = abs(signal_fft);
signal_fft = signal_fft(1:Nr/2, :);

figure(2);
plot(range_axis, signal_fft(:, 1)); % Plot range vs FFT output for the first chirp
title('Range from First FFT');
xlabel('Range (m)'); ylabel('Normalized Amplitude'); 
axis ([0 200 0 1]);

%% Range-Doppler-FFT (provided)
sig_fft2 = fft2(Mix_reshaped, Nr, Nd);
sig_fft2 = fftshift (sig_fft2(1:Nr/2, 1:Nd));
RDM = abs(sig_fft2);
RDM = 10*log10(RDM);

doppler_axis = linspace(-100,100,Nd);
range_axis = linspace(-200,200,Nr/2)*((Nr/2)/400);
figure(3);
imagesc(doppler_axis, range_axis, RDM);
xlabel("Doppler, m/s"); ylabel("Range, m");
title("Range-Doppler heatmap");
c = colorbar; c.Label.String = 'Amplitude (dB)';
set(gca,'YDir','normal');
ylim([0, R_max]);

%% CFAR
Tr = 10; % Number of Training Cells in Range
Td = 8;  % Number of Training Cells in Doppler
Gr = 4;  % Number of Guard Cells in Range
Gd = 4;  % Number of Guard Cells in Doppler
offset = 6; % SNR threshold, dB

CFAR_mask = zeros(size(RDM));
num_training_cells = (2*Tr + 2*Gr + 1) * (2*Td + 2*Gd + 1) - (2*Gr + 1) * (2*Gd + 1);
for i = Tr+Gr+1 : (Nr/2)-(Tr+Gr)
    for j = Td+Gd+1 : Nd-(Td+Gd)
        % Extract the region of interest around the CUT
        region = RDM(i-(Tr+Gr):i+(Tr+Gr), j-(Td+Gd):j+(Td+Gd));
        
        % Exclude the Guard Cells and CUT
        training_cells = region;
        training_cells(Tr+1:end-Tr, Td+1:end-Td) = 0;
        
        % Sum the noise level in training cells (convert from dB to linear)
        noise_level = sum(db2pow(training_cells), 'all') / num_training_cells;
        
        % Calculate the threshold (convert back to dB)
        threshold = pow2db(noise_level) + offset;
        
        % Compare CUT with threshold
        if RDM(i, j) > threshold
            CFAR_mask(i, j) = 1; % Signal detected
        else
            CFAR_mask(i, j) = 0; % No signal detected
        end
    end
end

figure(4);
imagesc(doppler_axis, range_axis, CFAR_mask);
title('2D CFAR Detection');
xlabel('Doppler Velocity (m/s)'); ylabel('Range (m)');
c = colorbar; c.Label.String = 'Detection (binary)';
set(gca,'YDir','normal');
ylim([0, R_max]);
