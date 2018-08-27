function y = slpe(blk, mbSize, borderReduction, patchSize, bw)

% Input:    blk - support area
%           mbSize - macroblock size (in pixels)
%           borderReduction - indicates by how many pixels the support area
%           is shrinked
%           bw - bandwidth parameter


bw_initial = bw;
len = length(blk(1,:));
y = zeros(mbSize);

% While there are still unconcealed pixels...
while min(min(blk(mbSize+1:mbSize+mbSize,mbSize+1:mbSize+mbSize))) < 0

    
    if bw == bw_initial
        [r c y0 mask] = get_next_patch(blk, patchSize);
    end
    expo = zeros(1,5000);
    patches = zeros(patchSize,patchSize,5000);
    iterator = 1;
    
    % Scan the support area
    for i = 1+borderReduction:len-patchSize+1-borderReduction
        for j = 1+borderReduction:len-patchSize+1-borderReduction

            % If x_j available...
            x_j = blk(i:i+patchSize-1,j:j+patchSize-1);
            if min(x_j(:)) < 0
                continue
            end

            % If y_j available...
            y_j = zeros(1, (patchSize+2+2)^2 );
            counter = 1;
            for p = -2:patchSize+2-1
                for q = -2:patchSize+2-1
                    if i+p>0 && j+q>0 && i+p<=len && j+q<=len && mask(p+3,q+3) > 0
                        y_j(counter) = blk(i+p,j+q);                        
                        counter = counter + 1;
                    end
                end
            end

            y_j = y_j(1:counter-1);
            if length(y_j) == length(y0) && min(y_j) >= 0
                
                % Compute the exponential...
                aux = sum((y_j - y0).^2);               
                expo(iterator) = aux/length(y0);
                
                % ... and store the corresponding patch
                patches(:,:,iterator) = x_j;
                iterator = iterator + 1;                
            end
        end
    end

    expo = expo(1:iterator-1);
    patches = patches(:,:,1:iterator-1);
    
    % Compute the weights
    numerator = zeros(patchSize);
    denominator = 0;
    for k = 1:iterator-1
        numerator = numerator + patches(:,:,k)*exp(-expo(k)/bw);
        denominator = denominator + exp(-expo(k)/bw);
    end              

    patchBayes = numerator/denominator;
    
    % If the initial bw is to severe, increase it and repeat the
    % calculation
    if sum(isnan(patchBayes(:))) > 0    
       bw = bw + 4;
   % Otherwise conceal the patch and reset the bandwidth
    else        
        blk(r:r+patchSize-1,c:c+patchSize-1) = patchBayes;
        y = blk(mbSize+1:mbSize+mbSize,mbSize+1:mbSize+mbSize);
        bw = bw_initial;
    end    
    
end

end
