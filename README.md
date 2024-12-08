# SFND_RADAR

## FMCW Waveform Design

Given input:
```octave
fc = 77e9;
R_max = 200;
d_res = 1;
v_max = 100;
v_res = 3;
```

Output for the given input parameters:
```octave
B=150000000 (Hz).
T_{chirp}=7.333333e-06 (sec).
Slope=2.045455e+13 (Hz/sec).
```

## Simulation loop

The loop can be replaced by in-place operations in Matlab:
```octave
t=linspace(0,Nd*Tchirp,Nr*Nd); %total time for samples
r_t = R_target + v_target * t; % target range using vel model
td = 2 * r_t / c; % propagate time
Tx = cos(2 * pi * (fc * t + (slope * t.^2) / 2));
Rx = cos(2 * pi * (fc * (t - td) + (slope * (t - td).^2) / 2) );
Mix = Tx.*Rx;
```

## Range-FFT

```octave
Mix_reshaped = reshape(Mix, [Nr, Nd]);
signal_fft = fft(Mix_reshaped, Nr); % FFT along the range bins
signal_fft = signal_fft / max(max(abs(signal_fft)));
signal_fft = abs(signal_fft);
signal_fft = signal_fft(1:Nr/2, :);
```

* After a proper adjustment of range axis, the mix peak matches the simulated value of the target.

1D-FFT for simulated target at `R=100`:

![image](https://github.com/user-attachments/assets/35b94d4a-ac68-4cf1-9336-db5ea72df5fe)

## Range-Doppler FFT (provided)

```octave
sig_fft2 = fft2(Mix_reshaped, Nr, Nd);
sig_fft2 = fftshift (sig_fft2(1:Nr/2, 1:Nd));
RDM = abs(sig_fft2);
RDM = 10*log10(RDM);
```

![image](https://github.com/user-attachments/assets/c3387a2b-7bdb-44fa-a03b-ba03c16fb7d6)

## 2D CFAR

The implementation rendered the following CFAR mask (example using one of many different parameters):

![image](https://github.com/user-attachments/assets/7164ca8f-7516-46d5-97d5-b6bb0701e4f6)

### Implementation steps

* Detect signals in a range-Doppler map by evaluating each point's power level against an adaptive threshold derived from its surrounding environment.
* Analyze the local noise around a point of interest while excluding a protective buffer zone to ensure accurate noise estimation.
* Dynamically adjust the detection threshold vs. local noise levels.
* Points exceeding the threshold are marked as detections using a binary mask to indicate signal of interest.

### Selection of Training, Guard cells and offset

When chosing the parameters we want to:
* minimize the size of the detected mask
* keep it detectable for the target

A good candidate, for example:
```octave
Tr = 14; % Number of Training Cells in Range
Td = 8;  % Number of Training Cells in Doppler
Gr = 8;  % Number of Guard Cells in Range
Gd = 2;  % Number of Guard Cells in Doppler
offset = 10; % SNR threshold, dB
```

Which achives the following result (zoomed-in):
![image](https://github.com/user-attachments/assets/37267c5c-8225-444d-a3ed-92ade0bbb4ab)


### Steps taken to suppress the non-thresholded cells at the edges

* Increase SNR threshold value will have the largest impact.
* Reduce the number of guard cells will help to eliminate noise if the SNR threshold should be kept lower.
* Adjustment of train cells for smaller area.
* Combinations of all of the above for best results.

