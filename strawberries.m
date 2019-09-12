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
 threshold_bin = double(min((multithresh(im2, 5))));
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
    plot(boundary(:,2), boundary(:,1), 'r','LineWidth',1);
 end
 
 figure; imshow(im1);
 hold on
  for k = 1:n
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r','LineWidth',1);
  end
 
 %% Isolation of cards
 %  All cards are of size 56 x 87mm. Thus the aspect ratio is
 %  1:1.55357142857. Allowing for 5% error:
 aspect_ratio_range = [((87/56)-(87/56)*0.05), ((87/56)+(87/56)*0.05)];
 %cards = bwpropfilt(im1, 
 stats = regionprops(im,'MajorAxisLength','MinorAxisLength','PixelList','Image');
 pixel_list={};
 image_pixels = L(1)*L(2);
 cards = bwareaopen(im,image_pixels);
 figure; imshow(cards)
 for k = 1:n
     major = stats(k).MajorAxisLength;
     minor = stats(k).MinorAxisLength;
     aspect_ratio = major/minor;
     if aspect_ratio >= aspect_ratio_range(1) && aspect_ratio <= aspect_ratio_range(2)
         pixel_list(k,:) = {stats(k).PixelList(k,1),stats(k).PixelList(k,2)};
         cards = imoverlay(cards,bwselect(im,pixel_list{k,1},pixel_list{k,2}));
         figure; imshow(cards);
     end
     
 end
