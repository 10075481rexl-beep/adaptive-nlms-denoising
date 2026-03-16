clc;
clear;
close all;

%% 1. 输入信号生成模块
fs = 1000;                  % 采样频率
N = 1000;                   % 采样点数
t = (0:N-1)/fs;             % 时间轴
f0 = 10;                    % 信号频率
d = sin(2*pi*f0*t);         % 原始信号（期望信号）

%% 2. 噪声叠加模块
snr_in = 10;                                % 输入信噪比(dB)
x = awgn(d, snr_in, 'measured');            % 加入高斯白噪声后的信号

%% 3. NLMS滤波器模块参数设置
M = 16;                     % 滤波器阶数
mu = 0.8;                   % 步长参数
delta = 1e-6;               % 正则化项，防止除零

w = zeros(M,1);             % 初始化权值
y = zeros(1,N);             % 滤波器输出信号
e = zeros(1,N);             % 误差信号

%% 4. NLMS算法主循环
for n = M:N
    x_n = x(n:-1:n-M+1)';                   % 当前输入向量
    y(n) = w' * x_n;                        % 滤波器输出
    e(n) = d(n) - y(n);                     % 误差
    w = w + (mu / (delta + x_n' * x_n)) * x_n * e(n);   % 权值更新
end

%% 5. 性能评估模块
noise_before = x - d;                       % 加噪后的噪声
snr_before = 10*log10(sum(d.^2) / sum(noise_before.^2));
snr_after  = 10*log10(sum(d.^2) / sum((d - y).^2));

mse_before = mean((d - x).^2);
mse_after  = mean((d - y).^2);

disp('----- 仿真结果 -----');
fprintf('去噪前 SNR = %.2f dB\n', snr_before);
fprintf('去噪后 SNR = %.2f dB\n', snr_after);
fprintf('去噪前 MSE = %.6f\n', mse_before);
fprintf('去噪后 MSE = %.6f\n', mse_after);

%% 6. 可视化模块
figure;

subplot(4,1,1);
plot(t, d, 'LineWidth', 1);
title('原始信号');
xlabel('时间 / s');
ylabel('幅值');
grid on;

subplot(4,1,2);
plot(t, x, 'LineWidth', 1);
title('加噪信号');
xlabel('时间 / s');
ylabel('幅值');
grid on;

subplot(4,1,3);
plot(t, y, 'LineWidth', 1);
title('NLMS滤波输出信号');
xlabel('时间 / s');
ylabel('幅值');
grid on;

subplot(4,1,4);
plot(t, abs(d-y), 'LineWidth', 1);
title('误差曲线');
xlabel('时间 / s');
ylabel('误差');
grid on;

%% 7. 原始信号与去噪信号对比图
figure;
plot(t, d, 'b', 'LineWidth', 1.2); hold on;
plot(t, y, 'r--', 'LineWidth', 1.2);
legend('原始信号', '去噪后信号');
title('原始信号与去噪后信号对比');
xlabel('时间 / s');
ylabel('幅值');
grid on;

%% 8. 参数扫描模块（一）：扫描步长 mu
mu_list = [0.1 0.3 0.5 0.8];
snr_mu = zeros(length(mu_list),1);
mse_mu = zeros(length(mu_list),1);

for k = 1:length(mu_list)
    mu_temp = mu_list(k);
    w_temp = zeros(M,1);
    y_temp = zeros(1,N);
    e_temp = zeros(1,N);

    for n = M:N
        x_n = x(n:-1:n-M+1)';
        y_temp(n) = w_temp' * x_n;
        e_temp(n) = d(n) - y_temp(n);
        w_temp = w_temp + (mu_temp/(delta + x_n'*x_n)) * x_n * e_temp(n);
    end

    snr_mu(k) = 10*log10(sum(d.^2) / sum((d - y_temp).^2));
    mse_mu(k) = mean((d - y_temp).^2);
end

%% 9. 绘制步长参数对性能影响
figure;
plot(mu_list, snr_mu, '-o', 'LineWidth', 1.5);
title('步长参数对输出SNR的影响');
xlabel('步长参数 \mu');
ylabel('输出信噪比 SNR / dB');
grid on;

figure;
plot(mu_list, mse_mu, '-o', 'LineWidth', 1.5);
title('步长参数对MSE的影响');
xlabel('步长参数 \mu');
ylabel('均方误差 MSE');
grid on;

%% 10. 参数扫描模块（二）：扫描滤波器阶数 M
M_list = [4 8 16 32 64];
snr_M = zeros(length(M_list),1);
mse_M = zeros(length(M_list),1);

mu_fixed = 0.8;     % 固定步长参数用于阶数扫描

for k = 1:length(M_list)
    M_temp = M_list(k);
    w_temp = zeros(M_temp,1);
    y_temp = zeros(1,N);
    e_temp = zeros(1,N);

    for n = M_temp:N
        x_n = x(n:-1:n-M_temp+1)';
        y_temp(n) = w_temp' * x_n;
        e_temp(n) = d(n) - y_temp(n);
        w_temp = w_temp + (mu_fixed/(delta + x_n'*x_n)) * x_n * e_temp(n);
    end

    snr_M(k) = 10*log10(sum(d.^2) / sum((d - y_temp).^2));
    mse_M(k) = mean((d - y_temp).^2);
end

%% 11. 绘制滤波器阶数对性能影响
figure;
plot(M_list, snr_M, '-o', 'LineWidth', 1.5);
title('滤波器阶数对输出SNR的影响');
xlabel('滤波器阶数 M');
ylabel('输出信噪比 SNR / dB');
grid on;

figure;
plot(M_list, mse_M, '-o', 'LineWidth', 1.5);
title('滤波器阶数对MSE的影响');
xlabel('滤波器阶数 M');
ylabel('均方误差 MSE');
grid on;

%% 12. 输出参数扫描结果到命令窗口
disp('----- 步长参数扫描结果 -----');
disp(table(mu_list', snr_mu, mse_mu, 'VariableNames', {'mu', 'SNR_dB', 'MSE'}));

disp('----- 滤波器阶数扫描结果 -----');
disp(table(M_list', snr_M, mse_M, 'VariableNames', {'M', 'SNR_dB', 'MSE'}));