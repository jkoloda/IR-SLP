function [r c y0 mask] = get_next_patch(blk, patchSize)

% Input:    blk - support area
%           patchSize - the size (in pixels) of a patch
%
% Output:   spatial context y0 along with its shape (mask) and location
%           of the next patch to conceal [row column] within blk

global reliabilityMask
coef = 0.1;
dim = length(reliabilityMask(1,:));
len = dim/3;
TH = 0;

% For every possible patch...
for i = len+1:patchSize:len+len
    for j = len+1:patchSize:len+len   
        % If it has not been reconstructed yet...
        if max(max(reliabilityMask(i:i+patchSize-1,j:j+patchSize-1))) < 0
            % Compute its reliability...
            reliability = 0;
            for p = -2:patchSize+2-1
                for q = -2:patchSize+2-1
                    if i+p>0 && j+q>0 && i+p<dim && j+q<dim && reliabilityMask(i+p,j+q) >= 0
                        reliability = reliability + reliabilityMask(i+p,j+q);
                    end
                end
            end
            % Keep the patch with the highest reliability
            if reliability > TH
                r = i;
                c = j;
                TH = reliability;
            end
        end
    end
end

y0 = zeros(1, (patchSize+2+2)^2 );
mask = zeros(patchSize+2+2);
counter = 1;
aux = 0;
for i = -2:patchSize+2-1
    for j = -2:patchSize+2-1
        if reliabilityMask(r+i,c+j) >= 0
            y0(counter) = blk(r+i,c+j);
            aux = aux + reliabilityMask(r+i,c+j);
            counter = counter + 1;
            mask(i+3,j+3) = 1;
        end
    end
end

% Update the reliability parameter
reliabilityMask(r:r+patchSize-1,c:c+patchSize-1) = (aux/(counter - 1) - coef)*ones(patchSize);
y0 = y0(1:counter-1);

end