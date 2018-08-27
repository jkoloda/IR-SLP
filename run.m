%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%                                                                  %
%   Copyright (c) 2011 by                                          %
%   Jan Koloda                                                     %
%   Universidad de Granada, Granada, Spain                         %
%   - all rights reserved -                                        %
%                                                                  %
%   This is an implementation of the algorithm described in:       %
%   Koloda, J., Ostergaard, J., Jensen, S.H., Sanchez, V. and      %
%   Peinado, A.M. "Sequential Error Concealment for Video/Images   %
%   by Sparse Linear Prediction", IEEE Transactions on Multimedia, %
%   June 2013.                                                     %
%                                                                  %
%   This program is free of charge for personal and scientific     %
%   use (with proper citation). The author does NOT give up his    %
%   copyright. Any commercial use is prohibited.                   %
%   YOU ARE USING THIS PROGRAM AT YOUR OWN RISK! THE AUTHOR        %
%   IS NOT RESPONSIBLE FOR ANY DAMAGE OR DATA-LOSS CAUSED BY THE   %
%   USE OF THIS PROGRAM.                                           %
%                                                                  %
%   If you have any questions please contact:                      %
%                                                                  %
%   Jan Koloda                                                     %
%   Dpt. Signal Theory, Networking and Communication               %
%   Universidad de Granada                                         %
%   Granada, Spain                                                 %
%                                                                  %
%                                                                  %
%   email: janko @ ugr.es                                          %
%                                                                  %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Loading the image and parsing it to grey level, if necessary

img = imread('foreman.png');
[r c d] = size(img);
if d > 1
    img = double(rgb2gray(img));
else
    img = double(img);
end

%% Generating losses

slice_to_be_lost = 1;
nSlices = 2;
mbSize = 16;
mode = 'default';

%Cropping the image so it is made of an integer number of macroblocks %%%%%
img = img(1:floor(r/mbSize)*mbSize,1:floor(c/mbSize)*mbSize);
[r c] = size(img);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[mask centers] = simuLoss(img, mbSize, nSlices, slice_to_be_lost, mode);
received_frame = mask;
[rows columns] = size(mask);

%% CONCEALMENT

global reliabilityMask
patchSize = 2;
borderReduction = 0;
bw = 20;
h = waitbar(0);
set(h,'Name','Processing')
for i = 1:length(centers(1,:))    
    reliabilityMask = 2*ones(3*mbSize);
    r = centers(1,i);
    c = centers(2,i);            
    
    % TOP-LEFT CORNER
    if r-mbSize<=0 && c-mbSize<=0
        blk = -ones(3*mbSize);
        blk(mbSize+1:end,mbSize+1:end) = received_frame(1:2*mbSize,1:2*mbSize);                   
        
    % BOTTOM-LEFT CORNER
    elseif r+mbSize+mbSize-1>rows && c-mbSize<=0
        blk = -ones(3*mbSize);
        blk(1:2*mbSize,mbSize+1:end) = received_frame(rows-2*mbSize+1:rows,1:2*mbSize);                                
    
    % TOP-RIGHT CORNER
    elseif r-mbSize<=0 && c+mbSize+mbSize-1>columns
        blk = -ones(3*mbSize);
        blk(mbSize+1:end,1:2*mbSize) = received_frame(r:r+mbSize+mbSize-1,c-mbSize:c+mbSize-1);
        
    % BOTTOM-RIGHT CORNER
    elseif r+mbSize+mbSize-1>rows && c+mbSize+mbSize-1>columns
        blk = -ones(3*mbSize);
        blk(1:2*mbSize,1:2*mbSize) = received_frame(r-mbSize:r+mbSize-1,c-mbSize:c+mbSize-1);
              
    % TOP SIDE
    elseif r-mbSize<=0        
        blk = -ones(3*mbSize);       
        blk(mbSize+1:end,:) = received_frame(r:r+mbSize+mbSize-1,c-mbSize:c+mbSize+mbSize-1);        
        
    % BOTTOM SIDE
    elseif r+mbSize+mbSize-1>rows
        blk = -ones(3*mbSize);
        blk(1:2*mbSize,:) = received_frame(r-mbSize:rows,c-mbSize:c+mbSize+mbSize-1);
        
    % RIGHT SIDE
    elseif c+mbSize+mbSize-1>columns
        blk = -ones(3*mbSize);
        blk(:,1:2*mbSize) = received_frame(r-mbSize:r+mbSize+mbSize-1,c-mbSize:c+mbSize-1);     
        
    % LEFT SIDE
    elseif c-mbSize<=0
        blk = -ones(3*mbSize);
        blk(:,mbSize+1:end) = received_frame(r-mbSize:r+mbSize+mbSize-1,c:c+mbSize+mbSize-1);
    
    % INTERIOR
    else        
        blk = received_frame(r-mbSize:r+mbSize+mbSize-1,c-mbSize:c+mbSize+mbSize-1);        
    end
            
    reliabilityMask(blk < 0) = -1;    
    y = slpe(blk, mbSize, borderReduction, patchSize, bw);
    
    waitbar(i/length(centers(1,:)),h,[num2str(round(100*i/length(centers(1,:)))) '% is done'])
    mask(r:r+mbSize-1,c:c+mbSize-1) = y;
    
end
close(h)

K = [0.01 0.03];
winsize = 8;
sigma = 0.25;
window = fspecial('gaussian', winsize, sigma);
level = 5;
weight = [0.0448 0.2856 0.3001 0.2363 0.1333];
method = 'wtd_sum';

figure
subplot(1,2,1),imshow(received_frame,[0 255])
subplot(1,2,2),imshow(mask,[0 255])
title(['PSNR = ' num2str(psnr(img,mask)) 'dB   |   MS-SSIM = ' num2str(ssim_mscale_new(img, mask, K, window, level, weight, method)*100)])




