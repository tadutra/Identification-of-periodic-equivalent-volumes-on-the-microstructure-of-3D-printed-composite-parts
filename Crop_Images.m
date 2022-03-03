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
% This routine requires the function FindFibers.m
%
% If you use or edit this code, please cite the appropriate reference:
% https://doi.org/10.3390/polym14050972
% 
%*************************************************************************%

warning('off','all');
tic;

%*************************************************************************%
%
% INPUT DATA
%
%*************************************************************************%

% Defines the name of image file to be read
nmImage = 'Image-name.jpg';

% Defines the imput mode
% 0 - keep current image and current cropped region
% 1 - read a new image and capture a new cropped region
% 2 - read a new image which is also the new cropped region
% 99 - end script
readImage = 99;

% Sensitivity factor is the sensitivity for the circular Hough transform 
% accumulator array. As you increase the sensitivity factor, imfindcircles 
% detects more circular objects, including weak and partially obscured 
% circles. Higher sensitivity values increase the risk of false detection.
sensH = 0.95;

% Function detects more circular objects (with both weak and strong 
% edges) when you set the threshold to a lower value. It detects fewer 
% circles with weak edges as you increase the value of the threshold.
edgeH = 0.4;

% Defines the average radius for the fiber
radius = 5;

% Range of radii for the circular objects
radrng = [1 10];

% Size of captured image where L = del x radius
del = 10;

% Maximum number of captured images
imgMax = 10;

% Maximum number of trials
tryMax = 5e5;

% Inferior and superior limits for the objective fiber volume fraction
Vfmin = 0.315;
Vfmax = 0.32;

%*************************************************************************%
%
% READ FILE
%
%*************************************************************************%

switch readImage
    case 0
        if (exist('imgCrop','var') == 0)
            display('No cropped image available');
            return
        elseif (isempty(imgCrop))
            display('No cropped image available');
            return
        end;
    case 1
        if (isempty(nmImage))
            display('No file image available');
            return
        end;
        imgFile = imread(nmImage);
        [imgCrop,rect] = imcrop(imgFile);
        if (isempty(imgCrop))
            display('No cropped image available');
            return
        end;
    case 2
        if (isempty(nmImage))
            display('No file image available');
            return
        end;
        imgFile = imread(nmImage);
        imgCrop = imgFile;
    case 99
        return
end;

%*************************************************************************%
%
% INITIALIZE VARIABLES
%
%*************************************************************************%

l = size(imgCrop,1);
w = size(imgCrop,2);

i = 1;
trial = 0;
box = [];
inBox = 0;
Vf = 0;

% Set waitbar and its position
wb = waitbar(0,'Capturing Images...');
set(wb, 'Units', 'Pixels', 'Position', [1150 500 375 100]);

%*************************************************************************%
%
% CAPTURE IMAGES
%
%*************************************************************************%

while ( i <= imgMax && trial < tryMax )
    
    % Initialize variables
    X0 = 1e5;
    Y0 = 1e5;
    
    % Compute the initial coordinates of the captured window
    while ( X0 + radius * del  > w || Y0 + radius * del > l )
        X0 = round( rand * (w - 1) ) + 1;
        Y0 = round( rand * (l - 1) ) + 1;
    end;
    
    % Copying captured window
    imgTrgt{i}= imgCrop(Y0:Y0 + radius*del,X0:X0 + radius*del,:);
    R = imgTrgt{i}(:,:,1);
    G = imgTrgt{i}(:,:,2);
    B = imgTrgt{i}(:,:,3);
    
    % Find each fiber center based on CHT (Circular Hough Transform)
    [center, radii] = imfindcircles(R,radrng,'ObjectPolarity',...
                      'bright','Sensitivity',sensH,'Method','TwoStage',...
                      'EdgeThreshold',edgeH);
    Area = size(imgTrgt{i},1) * size(imgTrgt{i},2);

    % Compute the pixels corresponding to fibers
    [RR,GG,BB] = FindFibers(radius,center,R,G,B);

    % Compute fiber volume fraction
    Vf(i) = size(RR(RR == 255),1) / Area;
    
    % Return the size of the cropped window
    [ll,ww] = size(RR);
    
    % Compute if the current cropped image is intersecting another
    for ii = 1:size(box,1)
            inBox(ii) = rectint([X0,Y0,radius*del,radius*del],...
                        [box(ii,1),box(ii,2),radius*del,radius*del]);
    end;

    % Check if volume fraction is comprised within the objective range
    % If so, the window is then computed and i is incremented
    if ( Vf(i) >= Vfmin && Vf(i) <= Vfmax && isempty(inBox(inBox ~= 0)))
        box(i,1:2) = [X0,Y0];
        
        % Print original cropped figure
        figure;
        imshow(cat(3,R,G,B),'Border','tight','InitialMagnification',300);
        set(gcf,'PaperUnits','inches','PaperSize',[ll/100 ww/100],...
            'PaperPosition', [0 0 ll/100 ww/100]);
        nmFile = strcat('del_',num2str(del),'_Ori_',num2str(i));
        print(nmFile,'-dpng','-r100');
        close;
        
        % Print cropped figure with fibers in red
        figure;
        imshow(cat(3,RR,GG,BB),'Border','tight','InitialMagnification',300);
        set(gcf,'PaperUnits','inches','PaperSize',[ll/100 ww/100],...
            'PaperPosition', [0 0 ll/100 ww/100]);
        nmFile = strcat('del_',num2str(del),'_Proc_',num2str(i));
        print(nmFile,'-dpng','-r100');
        close;
        
        % Create file with fiber arrangement
        nelem = ll * ww;
        fileID = fopen([nmFile,'_Mesh.txt'],'w');
        fprintf(fileID,'%d\n',ll);
        fprintf(fileID,'%d\n',ww);
        fprintf(fileID,'%d\n',nelem);
        cont = 0;
        for mm = 1:ww
            for nn = 1:ll
                if (RR(nn,mm) == 255)
                    fprintf(fileID,'%d\n',1);
                    cont = cont + 1;
                else
                    fprintf(fileID,'%d\n',0);
                end;
            end;
        end;
        fclose(fileID);
        
        waitbar(i/imgMax,wb);
        % Increment i
        i = i + 1;
    end;
    trial = trial + 1;

end;
close(wb);
close all;

%*************************************************************************%
%
% PLOT POSITION OF CAPTURED IMAGES
%
%*************************************************************************%

hFig = figure;
imshow(imgCrop); hold on;
if ~isempty(box)
    fprintf('\nImage  Volume Fraction\n');

    for ii = 1:size(box,1)
        xbox = [box(ii,1),box(ii,1) + radius*del,box(ii,1) + radius*del,box(ii,1),box(ii,1)];
        ybox = [box(ii,2),box(ii,2),box(ii,2) + radius*del,box(ii,2) + radius*del,box(ii,2)];
        plot(xbox,ybox,'r');
        fprintf('%d \t %10.4f%%\n', ii,Vf(ii)*100);
    end;
end;
print(['del_',num2str(del),'_MainCrop'],'-dpng','-r100');

%*************************************************************************%
%
% PRINT NUMBER OF TRIALS AND TOTAL ELAPSED TIME
%
%*************************************************************************%

t = toc;
fprintf('\nNumber of trials: %d\n', trial);
fprintf('\nElapsed time: %10.4fmin\n', t/60);


