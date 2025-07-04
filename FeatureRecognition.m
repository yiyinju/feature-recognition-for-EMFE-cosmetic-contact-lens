function [Centroids, NumberofGreenCircles] = FeatureRecognition(img,ROI,HThreshold,SThreshold,VThreshold)
% This function aims to recognize the green circles in the EMFE cosmetic
% contact lens

% Input: img: Initial image acquired by head-mounted eye tracker, RGB, 2560×1440×3 uint8
%        ROI: Ocular region,1×4 uint8
%        HThreshold: Threshold of hue channel for green circle recognition, 1×2 double
%        SThreshold: Threshold of saturation channel for green circle recognition, 1×2 double
%        VThreshold: Threshold of value channel for green circle recognition, 1×2 double

% Output: Centroids: Centroids of the green circles，n×2 uint8
%         NumberofGreenCircles: Number of the green circles, uint8

% Authors: Hengtian Zhu, et. al.

Centroids_ROI = [];
NumberofGreenCircles = 0;
%% Cosmetic contact lens recognition
img_crop = imcrop(img,ROI);
% HSV filter
img_HSV = rgb2hsv(img_crop);
% Define thresholds for channel 1 based on histogram settings
channel1Min = 0.2;
channel1Max = 0.8;
% Define thresholds for channel 2 based on histogram settings
channel2Min = 0.25;
channel2Max = 1.000;
% Define thresholds for channel 3 based on histogram settings
channel3Min = 0;
channel3Max = 1.000;
% Create mask based on chosen histogram thresholds
mask_HSV = (img_HSV(:,:,1) >= channel1Min ) & (img_HSV(:,:,1) <= channel1Max) & ...
    (img_HSV(:,:,2) >= channel2Min ) & (img_HSV(:,:,2) <= channel2Max) & ...
    (img_HSV(:,:,3) >= channel3Min ) & (img_HSV(:,:,3) <= channel3Max);
mask_HSV(:,1) = 0;
mask_HSV(:,ROI(3)) = 0;

% Morphology Operations
BW = imfill(mask_HSV,'holes');
BW1 = 1-BW;
BW2 = 1-imfill(BW1,'holes');
BW3 = BW-BW2;

% The largest connected region
imLabel = bwlabel(BW3);
stats = regionprops(imLabel,'Area');
area = cat(1,stats.Area);
index = find(area == max(area));
img_mask_CCL = ismember(imLabel,index);


%% Green circles recognition

% HSV filter
% Define thresholds for channel 1 based on histogram settings
channel1Min = HThreshold(1);
channel1Max = HThreshold(2);
% Define thresholds for channel 2 based on histogram settings
channel2Min = SThreshold(1);
channel2Max = SThreshold(2);
% Define thresholds for channel 3 based on histogram settings
channel3Min = VThreshold(1);
channel3Max = VThreshold(2);
% Create mask based on chosen histogram thresholds
mask_HSV = (img_HSV(:,:,1) >= channel1Min ) & (img_HSV(:,:,1) <= channel1Max) & ...
    (img_HSV(:,:,2) >= channel2Min ) & (img_HSV(:,:,2) <= channel2Max) & ...
    (img_HSV(:,:,3) >= channel3Min ) & (img_HSV(:,:,3) <= channel3Max);
mask_HSV = mask_HSV.*img_mask_CCL;

% Connected region filter
BW = imclose(mask_HSV,strel(20));
BW = imfill(BW);
CC = bwconncomp(BW);
S = regionprops(CC, 'Area');
L = labelmatrix(CC);
BW = ismember(L, find([S.Area] >= 500 & [S.Area] <= 20000));
BW = bwpropfilt(BW, 'Eccentricity', [0 1]);
BW = bwpropfilt(BW, 'Solidity', [0.7 1]);

% DOI filter
BW2 = zeros(size(img_mask_CCL));
CC_filtered = bwconncomp(BW);
stats_init = regionprops('table', CC_filtered, 'Centroid', 'MajorAxisLength', 'MinorAxisLength', 'Orientation', 'Area');% 识别所有连通区域
number = height(stats_init);
L_filtered = labelmatrix(CC_filtered);     
for n = 1:1:number
    L_single = zeros(size(L_filtered));
    [idx_y_L_single,idx_x_L_single] = find(L_filtered==n);
    if min(idx_x_L_single)>1 && min(idx_y_L_single)>1 && max(idx_x_L_single)<1400 && max(idx_y_L_single)<1400 
        L_single(find(L_filtered==n)) = 1;
        EllipseParam.X0_in = stats_init.Centroid(n,1);
        EllipseParam.Y0_in = stats_init.Centroid(n,2);
        EllipseParam.a = stats_init.MajorAxisLength(n)/2;
        EllipseParam.b = stats_init.MinorAxisLength(n)/2;
        EllipseParam.phi = stats_init.Orientation(n)/180*pi;
        DOI(n) = XOR_ellipses(L_single,EllipseParam);
        if DOI(n) < 0.5
            BW2 = BW2+L_single;
            Centroids_ROI(end+1,:) = stats_init.Centroid(n,:);
            NumberofGreenCircles = NumberofGreenCircles+1;
        end
    end
end
img_mask_GC = BW2;
Centroids(:,1) = Centroids_ROI(:,1)+ROI(1);
Centroids(:,2) = Centroids_ROI(:,2)+ROI(2);

end

