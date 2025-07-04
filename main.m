% Load the image
file_path = 'example\example img.jpg';
img = imread(file_path);

% Set recognition parameters
ROI = [800 0 1400 1400];
HThreshold = [0.15 0.6];
SThreshold = [0 1];
VThreshold = [0.3 0.65];

% Green circles recognition
[Centroids, NumberofGreenCircles] = FeatureRecognition(img,ROI,HThreshold,SThreshold,VThreshold);

% Draw results(option)
figure
imshow(img)
hold on
plot(Centroids(:,1),Centroids(:,2),'yo','MarkerSize',10)