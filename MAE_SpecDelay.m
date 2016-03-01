function y = MAE_SpecDelay(x,windowSize,delMat,mix)

% Length and number of chanels of input
[inLen,numChan] = size(x);
% Create periodic hamming window
window = MAA_HannWindows(windowSize,'p');
% hopsize is half the window size
hopSize = round(windowSize * 0.5);
% Calculate number of rows and columns for the base STFT matrix
nRow = ceil(windowSize/2);
nCol = fix((inLen-windowSize)/hopSize);
% Calculate extra columns/samples needed to account for more samples
% created by the delay
extraCols = max(delMat) * 10;
extraSamps = extraCols * windowSize;
% Set output as input, with the extra zeroed samples
y = [x;zeros(extraSamps,size(x,2))];
% STFT on one channel at a time
for chanIdx = 1:numChan
    % Create empty out STFT matrix, with the extra columns
    STFT = zeros(windowSize,nCol+extraCols);
    % Init Pointers
    idx = 1;
    colIdx = 1;
    
    % Compute STFT
    while (idx+windowSize) <= length(y)
        
        % --- STFT --- %        
        % segment and window input according to pointer
        windowedSig = y(idx:idx+(windowSize-1),chanIdx) .* window;
        % DFT
        Z = fft(windowedSig);
        % store DFT vector in STFT Matrix
        STFT(:,colIdx) = Z; 

        % --- Delays --- %      
        % empty DFT vector for the delayed spectral components
        
        ZDel = zeros(windowSize,1,'like',Z);
        % iterate over each bin value, if the delay time is valid 
        % (not referencing negative frames) and is not 0 then set the
        % output FFT Component to a previous component determined by delay
        % time in delMat
                
        for delIdx = 1:length(ZDel)              
        if colIdx - delMat(delIdx) > 0 && delMat(delIdx) ~= 0;  
            ZDel(delIdx) = STFT(delIdx,colIdx - delMat(delIdx));  
        end       
        end
        
        % --- ISTFT --- %        
        % inverse FFT
        delayedSig = real(ifft(ZDel));
                
        % combine delayed signal and original/overlap add, amp
        % set by user specified mix
        y(idx:idx+(windowSize-1),chanIdx) = ...
            (y(idx:idx+(windowSize-1),chanIdx)*(1-mix)) + delayedSig*mix;
        
        % --- Pointer Updates --- %
        idx = idx + hopSize;
        colIdx = colIdx+1;
        
    end

    
end
% y = y*(1-mix) + delOut*mix;
end