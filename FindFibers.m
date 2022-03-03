%*************************************************************************%
%
% Created on July, 2020
%
% Author: Thiago Assis Dutra
%
% Contact: thiagoassis.dutra@gmail.com
%
% Release version: 1.0
%
% This function is used at Crop_Images.m
%
% If you use or edit this code, please cite the appropriate reference:
% https://doi.org/10.3390/polym14050972
% 
%*************************************************************************%

function [R,G,B] = FindFibers(radius,center,R,G,B)

    % Computing integer parts of the centers
    icenter = round(center); 
    [r,c] = size(R);
	
    % Loop through array containing centers
    for i = 1:size(icenter,1)  
        row = max(icenter(i,2) - radius,1):min(icenter(i,2) + radius,r);
        col = max(icenter(i,1) - radius,1):min(icenter(i,1) + radius,c);
        for k = row
            for l = col
                dist = sqrt( ( double(k) - center(i,2) )^2 + ...
                             ( double(l) - center(i,1) )^2 );
                if (dist <= radius)
                    R(k,l) = 255;
                    G(k,l) = 0;
                    B(k,l) = 0;
                end;
            end;
        end;
    end;
end