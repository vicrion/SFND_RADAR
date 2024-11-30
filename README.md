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

![image](https://github.com/user-attachments/assets/35b94d4a-ac68-4cf1-9336-db5ea72df5fe)


