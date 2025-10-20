% Test fft function (fft_float) 
% Added on 2025/07/02 by jihan 
 fft_mode = 1; % '0': ifft, '1': fft
 N = 512;

 [cos_float, cos_fixed] = cos_in_gen(fft_mode, N);

 [fft_out, module2_out] = fft_float(1, cos_float); % Floating-point fft (fft) : Cosine 

% 시각화 코드 추가
figure('Position', [100, 100, 1200, 800]);

% 1. 입력 신호 (실수부)
subplot(2,3,1);
plot(1:N, real(cos_float), 'b-', 'LineWidth', 1.5);
title('입력 신호 (실수부)');
xlabel('샘플 인덱스');
ylabel('진폭');
grid on;

% 2. 입력 신호 (허수부)
subplot(2,3,2);
plot(1:N, imag(cos_float), 'r-', 'LineWidth', 1.5);
title('입력 신호 (허수부)');
xlabel('샘플 인덱스');
ylabel('진폭');
grid on;

% 3. FFT 결과 크기 스펙트럼
subplot(2,3,3);
magnitude = abs(fft_out);
plot(1:N, magnitude, 'g-', 'LineWidth', 1.5);
title('FFT 결과 크기 스펙트럼');
xlabel('주파수 빈 (Frequency Bin)');
ylabel('크기 (Magnitude)');
grid on;

% 4. FFT 결과 위상 스펙트럼
subplot(2,3,4);
phase = angle(fft_out);
plot(1:N, phase, 'm-', 'LineWidth', 1.5);
title('FFT 결과 위상 스펙트럼');
xlabel('주파수 빈 (Frequency Bin)');
ylabel('위상 (Phase, rad)');
grid on;

% 5. FFT 결과 실수부
subplot(2,3,5);
plot(1:N, real(fft_out), 'c-', 'LineWidth', 1.5);
title('FFT 결과 (실수부)');
xlabel('주파수 빈 (Frequency Bin)');
ylabel('실수부');
grid on;

% 6. FFT 결과 허수부
subplot(2,3,6);
plot(1:N, imag(fft_out), 'y-', 'LineWidth', 1.5);
title('FFT 결과 (허수부)');
xlabel('주파수 빈 (Frequency Bin)');
ylabel('허수부');
grid on;

% MATLAB 내장 FFT와 비교
figure('Position', [100, 100, 1200, 400]);

% 내장 FFT 결과
matlab_fft = fft(cos_float);

subplot(1,3,1);
plot(1:N, abs(matlab_fft), 'b-', 'LineWidth', 2);
hold on;
plot(1:N, magnitude, 'r--', 'LineWidth', 2);
title('크기 스펙트럼 비교');
xlabel('주파수 빈');
ylabel('크기');
legend('MATLAB 내장 FFT', '사용자 정의 FFT');
grid on;

subplot(1,3,2);
plot(1:N, angle(matlab_fft), 'b-', 'LineWidth', 2);
hold on;
plot(1:N, phase, 'r--', 'LineWidth', 2);
title('위상 스펙트럼 비교');
xlabel('주파수 빈');
ylabel('위상 (rad)');
legend('MATLAB 내장 FFT', '사용자 정의 FFT');
grid on;

subplot(1,3,3);
error_magnitude = abs(abs(matlab_fft) - magnitude);
plot(1:N, error_magnitude, 'k-', 'LineWidth', 1.5);
title('크기 스펙트럼 오차');
xlabel('주파수 빈');
ylabel('오차');
grid on;

% 결과 요약 출력
fprintf('\n=== FFT 결과 요약 ===\n');
fprintf('입력 신호 길이: %d\n', N);
fprintf('최대 크기 값: %.6f\n', max(magnitude));
fprintf('최소 크기 값: %.6f\n', min(magnitude));
fprintf('MATLAB FFT와의 최대 오차: %.6f\n', max(error_magnitude));
fprintf('MATLAB FFT와의 평균 오차: %.6f\n', mean(error_magnitude));

