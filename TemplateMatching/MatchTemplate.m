% This function does the template matching using ncc and scaled images
% (pyramid)
function MatchTemplate()
    close all;
    minsize = 25; % Choose the minimum pyramid size
    resizeRatio = 0.54; % Choose the template resize ratio
    pyramidRatio = 0.01; % Choose the pyramid ratio
    threshold = 0.38;    % Choose threshold to determine if pixel is a template match
    
    im = imread('Test_Photos\thecrew.jpg');
    if size(im,3)==3    % Check if image is rgb
        im = rgb2gray(im);
    end
    pyramid = MakePyramid(im, minsize, pyramidRatio);  % Make a pyramid of images

    template = imread('Test_Photos\template.jpg');
    template = imresize(template, resizeRatio);    % Resize template as 
                                            % correlation is expensive
    [newTemplateHeight,newTemplateWidth] = size(template);
                                            
    originalIm = pyramid{1};    % Get the original image, this is the one you draw rectangles on
    originalIm = cat(3,originalIm,originalIm,originalIm);  % Convert to rgb
    
    shapeInserter = vision.ShapeInserter('Shape','Rectangles','BorderColor','Custom',...
        'CustomBorderColor', uint8([255 0 0])); % Red rectangles
    
%     ShowPyramid(pyramid);

    for  index=1:size(pyramid,2)     % Iterate through the 1xn pyramid of images
%         im = NormalizeMatrix(im);   % Normalize the matrix
%         im = filter2(template,pyramid{index});  % Perform correlation
        im = pyramid{index};
        if size(im) > size(template)
            nccIm = normxcorr2(template,im);   % Perform cross normalization on the matrix
        else
            break;
        end
                
        rectWidth = newTemplateWidth*(pyramidRatio^(index-1));   % Update template rectangle size
        rectHeight = newTemplateHeight*(pyramidRatio^(index-1));    % Update template rectangle size
        [h,w] = size(nccIm);
        
        offset = size(nccIm) - size(im);    % Get the offset of the ncc image and the actual im

        % Loop through each pixel in the ncc image and see if it is above a
        % threshold, if it is, then draw a rectangle.
        % Make sure to loop from 1/2 template width/height to the
        % width/height of the image minus 1/2 template width/height
        for row=floor(newTemplateWidth/2):floor(h-newTemplateWidth/2) 
            for col=floor(newTemplateHeight/2):floor(w-newTemplateHeight/2)
                if nccIm(row,col)>threshold
                    x = uint32(col*((1/pyramidRatio)^(index-1)));  % Scale back the col value to the orig image
                    y = uint32(row*((1/pyramidRatio)^(index-1)));  % Scale back the row value to the orig image
                    xOffset = offset(2)/2*((1/pyramidRatio)^(index-1)); % Account for offset from matlab ncc
                    yOffset = offset(1)/2*((1/pyramidRatio)^(index-1)); % Account for offset from matlab ncc

                    % Add a rectangle
                    % -rectWidth/2 to account for x being the middle pixel
                    % -xOffset to account for the ncc offset
                    originalIm = step(shapeInserter, originalIm, [x-rectWidth/2-xOffset,y-rectHeight/2-yOffset,rectWidth,rectHeight]);
                end
            end
        end
    end
    imshow(originalIm);
    imwrite(originalIm,'thecrew_final.jpg');
end