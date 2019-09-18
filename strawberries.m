%% Set up workspace
clc
clear vars
clear all
close all
warning('off', 'Images:initSize:adjustingMag');
format bank; % Sets Command Window output to 2 decimal places for readibility


%% Importing image for card detection
addpath(genpath("PS2 Images")) %adds folder containing basic images to current path
num_images = 25;
image_names{num_images} = {};
for n = 1:num_images
    image_names{n} = ['Simple',num2str(n),'.png'];
end

image_number = input('What basic image (1-25) would you like to test? Press enter to cancel.  ');

run = true;
while run
    if isempty(image_number)
        close all
        clear all
        clc
        return
    end
    close all
    fprintf('\n                             NEW IMAGE\n\n')
    orig_image = imread(image_names{image_number});
    
    %% Task 1: Edge Extraction
    %% Task 1 - Pre-edge dectection image manipulation
    image_bw = rgb2gray(orig_image); %creates a grayscale version of the image
    [counts, locations] = imhist(image_bw); %creates a histogram of the image
    % counts - number of pixels in location
    % location range - 0-256
    %creates a threshold based on the histogram peaks
    threshold_bin = double(min((multithresh(image_bw, 3))));
    threshold = threshold_bin/255;
    
    %% Task 1 - Edge detection
    image_edge = edge(image_bw, 'canny', threshold); %detects the edges of the image using the canny method and the threshold calculated above.
    se = strel('disk', 5,0); %creates a structual element
    im_dilate = imdilate(image_edge,se);
    im_erode = imerode(im_dilate,se);
    im_all_edges = imfill(im_erode,'holes');
    
    %% Task 1 - Border Overlay
    [B_i,L_i,n_i,A_i] = bwboundaries(im_all_edges);
    % Finds the boundaries of all connected objects inside image
    
    %% Task 2: Bounding Box
    %% Task 2i - Isolation of cards
    %  All cards are of size 56 x 87mm. Thus the aspect ratio is
    %  1:1.55357142857. Allowing for 5% error, the measured aspect ratio
    %  should be within aspect_ratio_range:
    aspect_ratio_range = [((87/56)-(87/56)*0.05), ((87/56)+(87/56)*0.05)];
    props = regionprops(im_all_edges,'MajorAxisLength','MinorAxisLength','PixelList','Image');
    pixel_list={};
    image_size = size(L_i);
    card = zeros(image_size,'uint8');
    for k = 1:n_i
        major = props(k).MajorAxisLength;
        minor = props(k).MinorAxisLength;
        aspect_ratio = major/minor;
        if aspect_ratio >= aspect_ratio_range(1) && aspect_ratio <= aspect_ratio_range(2)
            pixel_list(k,:) = {props(k).PixelList(k,1),props(k).PixelList(k,2)};
            card = imoverlay(card,bwselect(im_all_edges,pixel_list{k,1},pixel_list{k,2}),'w');
        end
    end
    card = imbinarize(card(:,:,1));
    % Selects only the final layer as the imoverlay function adds a layer
    % everytime it is used. Then since the imoverlay function outputs a
    % greyscale image, imbinarize converts the greyscale image to back to
    % binary.
    
    %% Task 2ii - Border Overlay With Cards
    [B,L,n,A] = bwboundaries(card);
    
    %% Task 3: Pose Estimation
    %% Task 3i - Orientation Simplification
    card_props = regionprops(card,'Orientation','Centroid');
    for k = 1:n
        angle = card_props(k).Orientation;
        angle = angle + 90;
        if angle > 90
            angle = angle - 180;
        end
%         while angle < 0
%             angle = angle + 90;
%         end
%         while angle > 90
%             angle = angle-90
        card_props(k).Orientation = angle;
    end
    
    %% Task 3ii - Finding the Pose
    centroids = cat(1,card_props.Centroid);
    % Stores the centroids in an array, where the first column is the x
    % location, the second column is the y and the rows are each card.
    for k = 1:n
        theta = card_props(k).Orientation;
        x = centroids(k,1);
        y = centroids(k,2);
        general_transformation = [cos(theta) , -sin(theta) , x;
                                  sin(theta) , cos(theta)  , y;
                                  0          , 0           , 0];
        transformations(k)={general_transformation};
    end
        
    
    
    %% Task 4: Playing it Straight on the Queen's Crooked Ground
    %% Task 4i - Finding the scale of the image
    % Since the major axis of a playing card is 87mm, we can calculate the
    % relationship between mm and pixels as shown below:
    mm_per_pixel = 87/major;
    
    %% Task 4 ii - Finding the minimum distance between each card
    % The cards have now been isolated and we
    min_distances = {};
    minimum_distances = struct;
    num_min_distances = (n^2-n)/2;
    struct_index = 0;
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
            struct_index = struct_index + 1;
            for ii = 1 : size(boundary_2,1)
                % Chooses a pixel location on the border of boundary 2
                boundary_2x = boundary_2(ii,2);
                boundary_2y = boundary_2(ii,1);
                boundary_distances = sqrt((boundary_2x - boundary_1x).^2 + (boundary_2y - boundary_1y).^2);
                % Calculates the distance between the point 'ii' on
                % boundary 2, and every point on boundary 1.
                [minDistance(ii),index] = min(boundary_distances);
                if minDistance(ii) < current_min_distance
                    current_min_distance = minDistance(ii);
                    minimum_distances(struct_index).origin = k;
                    minimum_distances(struct_index).end = i;
                    minimum_distances(struct_index).pixels = current_min_distance;
                    minimum_distances(struct_index).distance = current_min_distance*mm_per_pixel;
                    minimum_distances(struct_index).x2 = boundary_2x;
                    minimum_distances(struct_index).y2 = boundary_2y;
                    minimum_distances(struct_index).x1 = boundary_1x(index);
                    minimum_distances(struct_index).y1 = boundary_1y(index);
                end
            end
        end
    end
    %% Outputing Processed Image
    figure; imshow(orig_image);
    hold on
    for k = 1:n
        boundary = B{k};
        plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
        h = text(centroids(k,1)-15,centroids(k,2)-10, num2str(k));
        set(h,'Color', 'r','FontSize',24,'FontWeight','bold','BackgroundColor','black');
    end
    hold on
    for k = 1:num_min_distances
        line([minimum_distances(k).x1, minimum_distances(k).x2], [minimum_distances(k).y1, minimum_distances(k).y2], 'Color', 'y', 'LineWidth', 3);
    end
    %% Outputing Data to Command Window
    fprintf('-------------------------------------------------------------------------\n')
    if n == 1 % Special case where there is only 1 card
        fprintf('There is 1 card in the image selected.\n')
        fprintf('-------------------------------------------------------------------------\n')
        fprintf('There is only 1 card, so there is no minimum distance to return.\n')
    else
        fprintf('There are %d cards in the image selected. \n', n);
        fprintf('-------------------------------------------------------------------------\n')
        for k = 1:num_min_distances
            fprintf('The minimum distance between card %d and card %d is %.2f mm.\n',minimum_distances(k).origin,minimum_distances(k).end,minimum_distances(k).distance);
        end
    end
    fprintf('-------------------------------------------------------------------------\n')
    fprintf('**Note that orientation is of the minor axis of the card with respect to the x axis of the image**\n')
    for k = 1:n
        fprintf('The orientation of card %d is %.2f degrees relative to the x axis. \n',k,card_props(k).Orientation);
    end
    fprintf('-------------------------------------------------------------------------\n')
    
    for k = 1:n
        fprintf('The centre coordinates (x,y) of card %d are at ( %.2f, %.2f ).\n',k,centroids(k,1),centroids(k,2));
    end
    fprintf('-------------------------------------------------------------------------\n')
        for k = 1:n
        fprintf('The transformation matrix of card %d is:\n',k);
        fprintf('%10.2f %10.2f %10.2f\n',transpose(transformations{k}))
    end
    fprintf('-------------------------------------------------------------------------\n')
    image_number = input('If you would like to watch the image being processed at every stage, press Y.\nIf you would like to test another image, please enter the number (1-25).\nOtherwise to exit, press enter:  ','s');
    fprintf('-------------------------------------------------------------------------\n')
    if image_number == 'Y'
        figure; imshow(orig_image);
        figure; imshow(image_bw);
        figure; imshow(image_edge);
        figure; imshow(im_dilate);
        figure; imshow(im_erode);
        figure; imshow(im_all_edges);
        hold on
        for k = 1:n_i %plots the boundaries over the binary image
            boundary = B_i{k};
            plot(boundary(:,2), boundary(:,1), 'r','LineWidth',1);
        end
        figure; imshow(orig_image);
        hold on
        for k = 1:n_i %plots the boundaries over the original image
            boundary = B_i{k};
            plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
        end
        figure; imshow(card);
        hold on
        for k = 1:n
            boundary = B{k};
            plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
        end
        figure; imshow(orig_image);
        hold on
        for k = 1:n
            boundary = B{k};
            plot(boundary(:,2), boundary(:,1), 'r','LineWidth',2);
            h = text(centroids(k,1)-15,centroids(k,2)-10, num2str(k));
            set(h,'Color', 'r','FontSize',24,'FontWeight','bold','BackgroundColor','black');
        end
        hold on
        for k = 1:num_min_distances
            line([minimum_distances(k).x1, minimum_distances(k).x2], [minimum_distances(k).y1, minimum_distances(k).y2], 'Color', 'y', 'LineWidth', 3);
        end
        image_number = input('If you would like to test another image, please enter the number (1-25).\nOtherwise to exit, press enter:  ');
    else
        if isempty(image_number)
            close all
            clear all
            clc
            return
        end
        image_number = str2double(image_number);
    end

end

