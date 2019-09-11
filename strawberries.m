 %% Set up workspace
 clc
 clear all
 close all

 
 %% Importing image for card detection
 im1=imread('C:\Users\Finn\Dropbox\THIRD YEAR\METR4202\Sandbox\images\Simple19.png');
 figure(1);
 imshow(im1);
 
 %% Pre-edge dectection image 
 im2 = rgb2gray(im1); %creates a grayscale version of the image
 [counts, locations] = imhist(im2); %creates a histogram of the image
 % counts - number of pixels in location
 % location range - 0-256
 % threshold = 155/256;
 % threshold = threshold(counts); %creates a threshold based on the histogram peaks
 threshold_bin = double(min((multithresh(im2, 3))));
 threshold = threshold_bin/255;
 %threshold = double(threshold_bin(2)) / 255;
 %threshold = (t/256);
 %im2 = histeq(im2);
 figure; imshow(im2); 
 
 %% Edge detection
 im = edge(im2, 'canny', threshold); %detects the edges of the image using the canny method and the threshold calculated above
 figure; imshow(im);
 
 se = strel('disk', 10,0); %creates a structual element
 im = imdilate(im,se);
 figure; imshow(im)
 im = imerode(im,se);
 figure; imshow(im)
 im = imfill(im,'holes');
 figure; imshow(im)
 
 %% Border Overlay
 [B,L,n,A] = bwboundaries(im);
 hold on
 for k = 1:n
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
 end
 
 figure; imshow(im1);
 hold on
  for k = 1:n
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
  end
 
 %% Making a small change
