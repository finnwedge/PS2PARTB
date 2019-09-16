 %% Set up workspace
 clc
 clear vars
 clear all
 close all

 
 %% Importing image for card detection
 addpath(genpath("PS2 Images")) %adds folder containing basic images to current path
 num_images = 25;
 image_names{num_images} = {};
 for n = 1:num_images
     image_names{n} = ['Simple',num2str(n),'.png'];
 end
 image_number = input('What basic image (1-25) would you like to test?  ');
 if isempty(image_number)
     return
 end
 im1 = imread(image_names{image_number});
 
 
 
 figure(1);
 imshow(im1);
 
 %% Pre-edge dectection image 
 im2 = rgb2gray(im1); %creates a grayscale version of the image
 [counts, locations] = imhist(im2); %creates a histogram of the image
 % counts - number of pixels in location
 % location range - 0-256
 %creates a threshold based on the histogram peaks
 threshold_bin = double(min((multithresh(im2, 5))));
 threshold = threshold_bin/255;
 figure; imshow(im2); 
 
 %% Edge detection
 im = edge(im2, 'canny', threshold); %detects the edges of the image using the canny method and the threshold calculated above
 figure; imshow(im);
 
 se = strel('disk', 5,0); %creates a structual element
 im = imdilate(im,se);
 figure; imshow(im)
 im = imerode(im,se);
 figure; imshow(im)
 im = imfill(im,'holes');
 figure; imshow(im)
 
 %% Border Overlay
 [B,L,n,A] = bwboundaries(im); 
 %finds the boundaries of connected objects inside image
 hold on
 for k = 1:n
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r','LineWidth',1);
 end
 %plots the boundaries over the binary image
 
 figure; imshow(im1);
 hold on
  for k = 1:n
    boundary = B{k};
    plot(boundary(:,2), boundary(:,1), 'r','LineWidth',1);
  end
 %plots the boundaries over the original image
 
 %% Isolation of cards
 %  All cards are of size 56 x 87mm. Thus the aspect ratio is
 %  1:1.55357142857. Allowing for 5% error:
 aspect_ratio_range = [((87/56)-(87/56)*0.05), ((87/56)+(87/56)*0.05)];
 %cards = bwpropfilt(im1, 
 stats = regionprops(im,'MajorAxisLength','MinorAxisLength','PixelList','Image');
 pixel_list={};
 image_size = size(L);
 card = zeros(image_size,'uint8');
 for k = 1:n
     major = stats(k).MajorAxisLength;
     minor = stats(k).MinorAxisLength;
     aspect_ratio = major/minor;
     if aspect_ratio >= aspect_ratio_range(1) && aspect_ratio <= aspect_ratio_range(2)
         pixel_list(k,:) = {stats(k).PixelList(k,1),stats(k).PixelList(k,2)};
         card = imoverlay(card,bwselect(im,pixel_list{k,1},pixel_list{k,2}),'w');
     end
 end
 card = card(:,:,1);
 figure; imshow(card);
 stats2 = regionprops(card,'Orientation','Centroid');
 centroids = cat(1,stats2.Centroid);
 
 
%% Border Overlay With Cards
 [B,L,n,A] = bwboundaries(card);
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
    h = text(centroids(k,1)-15,centroids(k,2)-10, num2str(k));
    set(h,'Color', 'r','FontSize',24,'FontWeight','bold','BackgroundColor','black');
  end
 
  %% Finding the minimum distance between each card
  min_distances = {};
  for k = 1:(n) 
      % Chooses the card boundary to be checked against
      boundary_1 = B{k};
      boundary_1x = boundary_1(:,2);
      boundary_1y = boundary_1(:,1);
      b_x1 = 1;
      b_y1 = 1;
      b_x2 = 1;
      b_y2 = 1;
      for i = k+1:n 
          % Chooses the second card boundary to be compared with
          if i == k 
              % If comparing with own boundary, skip to next boundary
              continue 
          end
          boundary_2 = B{i};
          current_min_distance = inf;
          for ii = 1 : size(boundary_2,1)
              % Chooses a pixel location on the border of boundary 2
              boundary_2x = boundary_2(ii,2);
              boundary_2y = boundary_2(ii,1);
              boundary_distances = sqrt((boundary_2x - boundary_1x).^2 + (boundary_2y - boundary_1y).^2);
              % Calculates the distance between the point specified on
              % boundary 2, and every point on boundary 1
              [minDistance(ii), index] = min(boundary_distances);
              if minDistance(ii) < current_min_distance
                  current_min_distance = minDistance(ii);
                  b_x2 = boundary_2x;
                  b_y2 = boundary_2y;
                  b_x1 = boundary_1x(index);
                  b_y1 = boundary_1y(index);
                  location = k*10+i;
                  min_distances(location,:) = {b_x1,b_y1,b_x2,b_y2,minDistance(ii),k,i,ii};
                  %min_distances(location,:) = {minDistance(ii)};
                  % Stores the minimum distance between each card in an
                  % array, in the location of boundary 1 boundary 2. For
                  % example, the distance between boundary 2 and boundary 6
                  % would be found at 26. This assumes that no more than 9
                  % cards will be in an image.
              end
          end
      end
  end
  num_min_distances = (n^2-n)/2;
  
%   min_distances_sorted = min_distances(~cellfun('isempty',min_distances))
%   i = 2;
%   for 
%       
  i = 2;
  x = 10;
  for k = 1:num_min_distances
      hold on
      cell = x+i;
      line([min_distances{cell,1}, min_distances{cell,3}], [min_distances{cell,2}, min_distances{cell,4}], 'Color', 'y', 'LineWidth', 3);
      fprintf('The minimum distance between card %d and card %d is %.2f pixels.\n',cell,cell,cell);
      i = i+1;
      if i == n + 1
          x = x + 10;
          i = i-1;
      end
  end 
                  