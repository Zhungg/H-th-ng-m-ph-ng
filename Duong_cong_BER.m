% ==========================================
% GIAI ĐOẠN 3: VÒNG LẶP BER & SO SÁNH LÝ THUYẾT
% ==========================================

% --- 1. THIẾT LẬP THÔNG SỐ (Giữ nguyên như cũ) ---
M = 16; k = log2(M);
numBits = 100000; % Tăng số bit lên 100,000 để đường cong mượt hơn
sps = 4; rollOff = 0.25; span = 6;

% Nguồn và Điều chế
dataIn = randi([0 1], numBits, 1);
dataSym = bit2int(dataIn, k);
txSig = qammod(dataSym, M);

% Lọc định hình xung phát
rrcFilter = rcosdesign(rollOff, span, sps, 'sqrt');
txSigFiltered = upfirdn(txSig, rrcFilter, sps);

% --- 2. VÒNG LẶP QUÉT MỨC NHIỄU (Eb/N0) ---
EbNoVec = 0:2:14; % Quét Eb/N0 từ 0 dB đến 14 dB (bước nhảy 2dB)
berSim = zeros(size(EbNoVec)); % Mảng lưu kết quả BER mô phỏng

for i = 1:length(EbNoVec)
    % Tính SNR cho từng mức Eb/N0
    snr = EbNoVec(i) + 10*log10(k) - 10*log10(sps);
    
    % Thêm nhiễu kênh truyền
    rxSig = awgn(txSigFiltered, snr, 'measured');
    
    % Lọc thu và downsample
    rxSigFiltered = upfirdn(rxSig, rrcFilter, 1, sps);
    
    % Loại bỏ trễ (Delay)
    rxSym = rxSigFiltered(span+1 : end-span);
    
    % Giải điều chế
    dataOutSym = qamdemod(rxSym, M);
    dataOut = int2bit(dataOutSym, k);
    
    % Tính BER
    [~, berSim(i)] = biterr(dataIn, dataOut);
end

% --- 3. TÍNH BER LÝ THUYẾT (THEORETICAL BER) ---
% Sử dụng hàm berawgn có sẵn của MATLAB để lấy mốc chuẩn
berTheory = berawgn(EbNoVec, 'qam', M);

% --- 4. VẼ ĐỒ THỊ BER SO SÁNH ---
figure;
semilogy(EbNoVec, berTheory, 'b-', 'LineWidth', 2); % Đường lý thuyết (Màu xanh)
hold on;
semilogy(EbNoVec, berSim, 'ro', 'MarkerSize', 8, 'LineWidth', 1.5); % Điểm thực nghiệm (Chấm đỏ)
hold off;

grid on;
title('Hiệu năng BER của hệ thống 16-QAM qua kênh AWGN');
xlabel('Eb/N0 (dB)');
ylabel('Tỷ lệ lỗi bit (BER)');
legend('Lý thuyết (berawgn)', 'Mô phỏng thực nghiệm');