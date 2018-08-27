%Calculates Peak Signal-to-Noise Ratio (PSNR)

function psnr = psnr(imgRef, img)

% INPUT:
%   imgRef - reference image
%   img    - image whose PSNR are to be calculated
%
% OUTPUT:
%   psnr   - PSNR value in dB

%Cropping the reference image if the concealed one has been cropped %%%%%%%
[rows cols] = size(img);
imgRef = imgRef(1:rows,1:cols);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

MSE = sum(sum(((double(imgRef) - double(img)).^2))) / (rows*cols);
psnr = 10*log10(255^2/MSE);

end
