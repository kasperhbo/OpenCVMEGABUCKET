
im1 = imread('dst_left.png');
im2 = imread('dst_right.png');
imshow([im1 im2])
%%
im1 = im2double(im1);
im1_gray = rgb2gray(im1);

im2 = im2double(im2);
im2_gray = rgb2gray(im2);
%%
pts1 = detectHarrisFeatures(im1_gray);
pts2 = detectHarrisFeatures(im2_gray);

[features1, valid_pt1] = extractFeatures(im1_gray, pts1);
[features2, valid_pt2] = extractFeatures(im2_gray, pts2);

indexPairs = matchFeatures(features1, features2);

matchedPt1 = valid_pt1(indexPairs(:,1),:);
matchedPt2 = valid_pt2(indexPairs(:,2),:);

showMatchedFeatures(im1_gray, im2_gray, matchedPt1, matchedPt2);
%%
n=2;
tforms(2) = projective2d(eye(3));
ImageSize = zeros(n, 2);
%%
% T(n)*T(n-1)*...*T(1)
%T(2)*T(1)
tforms(n) = estimateGeometricTransform2D(matchedPt2, matchedPt1,...
            'projective', 'Confidence', 99.9, 'MaxNumTrials', 1000);
        
        % Compute T(n) * T(n-1) * ... * T(1)
tforms(n).T = tforms(n).T * tforms(n-1).T;
%%
ImageSize(2,:) = size(im2_gray);
%%
for i = 1:numel(tforms)
        [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 ImageSize(i,2)], [1 ImageSize(i,1)]);
end
avgXLim = mean(xlim, 2);

[~, idx] = sort(avgXLim);

centerIdx = floor((numel(tforms)+1)/2);

centerImageIdx = idx(centerIdx);
Tinv = invert(tforms(centerImageIdx));

for i = 1:numel(tforms)
    tforms(i).T = tforms(i).T * Tinv.T;
end
for i = 1:numel(tforms)           
    [xlim(i,:), ylim(i,:)] = outputLimits(tforms(i), [1 ImageSize(i,2)], [1 ImageSize(i,1)]);
end

maxImageSize = max(ImageSize);
%%
% Find the minimum and maximum output limits
xMin = min([1; xlim(:)]);
xMax = max([maxImageSize(2); xlim(:)]);

yMin = min([1; ylim(:)]);
yMax = max([maxImageSize(1); ylim(:)]);
%%
% Width and height of panorama.
width  = round(xMax - xMin);
height = round(yMax - yMin);

% Initialize the "empty" panorama.
panorama = zeros([height width 3], 'like', im2);
blender = vision.AlphaBlender('Operation', 'Binary mask', ...
'MaskSource', 'Input port');  

% Create a 2-D spatial reference object defining the size of the panorama.
xLimits = [xMin xMax];
yLimits = [yMin yMax];
panoramaView = imref2d([height width], xLimits, yLimits);
%%
% Create the panorama.
i=1;
I = im1;

% Transform I into the panorama.
warpedImage = imwarp(I, tforms(1), 'OutputView', panoramaView);

% Generate a binary mask.
mask = imwarp(true(size(I,1),size(I,2)), tforms(1), 'OutputView', panoramaView);
panorama = step(blender, panorama, warpedImage, mask);
%%
i=2;
I = im2;

% Transform I into the panorama.
warpedImage = imwarp(I, tforms(2), 'OutputView', panoramaView);

% Generate a binary mask.
mask = imwarp(true(size(I,1),size(I,2)), tforms(2), 'OutputView', panoramaView);
panorama = step(blender, panorama, warpedImage, mask);
%%
imshow(panorama);