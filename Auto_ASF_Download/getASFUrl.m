clear all; clc;
% The getASFUrl.m provide a simple sloution to download Sentinel-1 InSAR
% data offered by ASF(The Alaska Satellite Facility), The script features 
% four different modes(flag1~4);
% flag = 1 enable you to download single-event coseismic data. (closest data
% before&after the earthquake occured)
% flag = 2 batch process coseismic data.
% flag = 3 download post-seismicdata for single coordinate.
% flag = 4 download and interseismic data for polygonal regions.

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Update 20241126
% The 

flag = 1;    

% Basic URL offered by ASF

baseURL = 'https://api.daac.asf.alaska.edu/services/search/param?platform=%s&processingLevel=SLC&beamMode=IW&start=%s&end=%s&intersectsWith=polygon((%f %f,%f %f,%f %f,%f %f,%f %f))&output=csv';
% baseURL = 'https://api.daac.asf.alaska.edu/services/search/param?platform=%s&processingLevel=SLC&beamMode=IW&start=%s&end=%s&bbox=%f,%f,%f,%f&output=csv';
%Define the satelite platform, you can choose any platform 
platform = 'Sentinel-1A';                                                  % Example: platform = 'Sentinel-1A' or 'Sentinel-1', 'Sentinel-1A', 'SA', 'Sentinel-1B','ALOS'...


if flag == 1  
    % Delete the former data. 
    % REMEMBER SAVE THE USEFUL DATA IMMEDIATELY.
    delete filelist;
    delete ./dataTable.mat
    delete ./closest_data.mat;
    delete ./csvfloder_single/*;
    % Define single location
    lat = [28.573]; 
    lon = [87.375]; 
    
    % We add a range of tolerance to capture a complete image of the 
    % earthquake deformation range as much as possible
    % Define the boundingbox location
      rot = 0.1;                                                              % Range of tolerance
    boundingbox_upper_right_lon   = lon+rot;
    boundingbox_upper_right_lat   = lat+rot;
    boundingbox_upper_left_lon    = lon-rot;
    boundingbox_upper_left_lat    = lat+rot;
    boundingbox_bottom_right_lon  = lon+rot;
    boundingbox_bottom_right_lat  = lat-rot;
    boundingbox_bottom_left_lon  = lon-rot;
    boundingbox_bottom_left_lat  = lat-rot;
      
    % Define the origin time
    originTime = '2025-01-07T01:05:30.470Z';                               % Please type the earthquake time by yyyy-mm-ddThh-MM-ss-SSSZ
    OrigintimeDate = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'); 
    % baseDate = datetime(originTime, 'InputFormat', 'yyyy-MM-dd');
    calculatedStartTime = OrigintimeDate - days(30);                         % Calculate 30 days before originTime to avoid time baseline above 12 days
    calculatedEndTime   = OrigintimeDate + days(30);                         % Calculate 30 days after originTime to avoid time baseline above 12 days
    
    % Change the data format from date-month-year(like 01-Jan-2020) to yyyy-mm-dd(2020-01-01)
    startTime = datestr(calculatedStartTime, 'yyyy-mm-ddTHH:MM:SSZ');
    endTime   = datestr(calculatedEndTime, 'yyyy-mm-ddTHH:MM:SSZ');

    % Generate URL
    url_of_csv = sprintf(baseURL,platform,startTime, endTime,...
        boundingbox_upper_left_lon,boundingbox_upper_left_lat,...
            boundingbox_upper_right_lon,boundingbox_upper_right_lat,...
                boundingbox_bottom_right_lon,boundingbox_bottom_right_lat,...
                    boundingbox_bottom_left_lon,boundingbox_bottom_left_lat,...
                        boundingbox_upper_left_lon,boundingbox_upper_left_lat);    
                    
    % Output the generated URL
    fprintf('###The url you wanted is: %s\n', url_of_csv);
    
    % Download the search results list
    SearchResults_Folder = './csvfloder_single';
    if ~exist(SearchResults_Folder, 'dir')
        mkdir(SearchResults_Folder);
    end
    csvFilePath = fullfile(SearchResults_Folder, 'search_results.csv');
    % 
    websave(csvFilePath, url_of_csv);
    disp(['###The csv_file has been saved to: ', csvFilePath]);
    filelist_of_urls = getASFUrl4CoSeismic(OrigintimeDate,csvFilePath);
    
    
elseif flag == 2
    SearchResults_Folder = './csvfloder_batch';
    if ~exist(SearchResults_Folder, 'dir')
        mkdir(SearchResults_Folder);
    end
    % Delete the former data. 
    % REMEMBER SAVE THE USEFUL DATA IMMEDIATELY.   
    delete filelist;
    delete ./dataTable.mat
    delete ./closest_data.mat;  
    delete ./csvfloder_batch/*;
    
    % Define the path of the csv file.
    tableData = readtable('listof5.5-6.0earthquake.csv');  
    
    % Traverse through all the times and locations appearing in the earthquake sequence tables.
    for i = 1:height(tableData)
        % Get the location(s) and origin time(s) of earthquake From csv
        % file which provide by USGS
        lat = tableData.latitude(i);
        lon = tableData.longitude(i);
        originTime = tableData.time{i};
        
        % We add a range of tolerance to capture a complete image of the 
        % earthquake deformation range as much as possible
        rot = 0.2;                                                         % Range of tolerance
        boundingbox_upper_right_lon   = lon+rot;
        boundingbox_upper_right_lat   = lat+rot;
        boundingbox_upper_left_lon    = lon-rot;
        boundingbox_upper_left_lat    = lat+rot;
        boundingbox_bottom_right_lon  = lon+rot;
        boundingbox_bottom_right_lat  = lat-rot;
        boundingbox_bottom_left_lon  = lon-rot;
        boundingbox_bottom_left_lat  = lat-rot;
        
        % baseDate = datetime(originTime, 'InputFormat', 'yyyy-MM-dd'); 
        OrigintimeDate = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'); 
        calculatedStartTime = OrigintimeDate - days(30);                     % Calculate 30 days before originTime to avoid time baseline above 12 days
        calculatedEndTime = OrigintimeDate + days(30);                       % Calculate 30 days after originTime to avoid time baseline above 12 days
        % Change the data format from date-month-year(like 01-Jan-2020) to yyyy-mm-dd(2020-01-01)
        startTime = datestr(calculatedStartTime, 'yyyy-mm-ddTHH:MM:SSZ');
        endTime = datestr(calculatedEndTime, 'yyyy-mm-ddTHH:MM:SSZ');
        % Generate URL
        url_of_csv = sprintf(baseURL,platform,startTime, endTime,...
            boundingbox_upper_left_lon,boundingbox_upper_left_lat,...
                boundingbox_upper_right_lon,boundingbox_upper_right_lat,...
                    boundingbox_bottom_right_lon,boundingbox_bottom_right_lat,...
                        boundingbox_bottom_left_lon,boundingbox_bottom_left_lat,...
                            boundingbox_upper_left_lon,boundingbox_upper_left_lat);

        csvFilePath = fullfile(SearchResults_Folder, sprintf('search_results_%d.csv', i));
        try
            websave(csvFilePath, url_of_csv);  
            disp(['### The CSV file has been saved to: ', csvFilePath]);
        catch
            disp(['### Failed to download CSV for lat: ', num2str(lat), ', lon: ', num2str(lon)]);
            continue;
        end
        getASFUrl4CoSeismic(OrigintimeDate, csvFilePath); 
        fprintf('### The URL for lat: %f, lon: %f is: %s\n', lat, lon, url_of_csv);
    end
    
    disp('### All CSV files have been downloaded and processed.');


elseif flag == 3 
     % Define a output floder.
    outputPath = '/data1/zhzhang/Auto_ASF_Download/test4post';

    
    % Delete the former data. 
    % REMEMBER SAVE THE USEFUL DATA IMMEDIATELY.
    delete ./dataTable.mat
    delete ./csvfloder_post_seis/*;
    
    % Define single location
    lat = [33.713]; 
    lon = [45.724]; 
    % We add a range of tolerance to capture a complete image of the 
    % earthquake deformation range as much as possible
    % Define the boundingbox location
    rot = 0.2;                                                              % Range of tolerance

    boundingbox_upper_right_lon   = lon+rot;
    boundingbox_upper_right_lat   = lat+rot;
    boundingbox_upper_left_lon    = lon-rot;
    boundingbox_upper_left_lat    = lat+rot;
    boundingbox_bottom_right_lon  = lon+rot;
    boundingbox_bottom_right_lat  = lat-rot;
    boundingbox_bottom_left_lon   = lon-rot;
    boundingbox_bottom_left_lat   = lat-rot;
    

    % Define the origin time
    originTime = '2018-01-11T06:59:30.470Z';                               % Please type the earthquake time by yyyy-mm-ddThh-MM-ss-SSSZ
    % TIME CHOOSE
    timeMode = 1;
    if timeMode == 1
        OrigintimeDate      = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'); 
        TimeRange_before    = 150;                       
        TimeRange_after     = 150;
        calculatedStartTime = OrigintimeDate - days(TimeRange_before);                         
        calculatedEndTime   = OrigintimeDate + days(TimeRange_after); 
        
    elseif timeMode == 2
        OrigintimeDate      = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
        currentTime         = datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
        TimeRange_before    = 150; 
        calculatedStartTime = OrigintimeDate - days(TimeRange_before);                         
        calculatedEndTime   = currentTime;
    end
    
    % Change the data format from date-month-year(like 01-Jan-2020) to yyyy-mm-dd(2020-01-01)
    startTime = datestr(calculatedStartTime, 'yyyy-mm-ddTHH:MM:SSZ');
    endTime   = datestr(calculatedEndTime, 'yyyy-mm-ddTHH:MM:SSZ');
    % Generate URL
    url_of_csv = sprintf(baseURL,platform,startTime, endTime,...
        boundingbox_upper_left_lon,boundingbox_upper_left_lat,...
            boundingbox_upper_right_lon,boundingbox_upper_right_lat,...
                boundingbox_bottom_right_lon,boundingbox_bottom_right_lat,...
                    boundingbox_bottom_left_lon,boundingbox_bottom_left_lat,...
                        boundingbox_upper_left_lon,boundingbox_upper_left_lat);

    
    % Output the generated URL
    fprintf('###The url you wanted is: %s\n', url_of_csv);
    
    % Download the search results list
    SearchResults_Folder = './csvfloder_post_seis';
    if ~exist(SearchResults_Folder, 'dir')
        mkdir(SearchResults_Folder);
    end
    csvFilePath = fullfile(SearchResults_Folder, 'search_results.csv');
    % 
    websave(csvFilePath, url_of_csv);
    disp(['###The csv_file has been saved to: ', csvFilePath]);
    filelist_of_urls = getASFUrl4PostSeismic(csvFilePath,outputPath);
    
elseif flag == 4
    % Define a output floder.
    outputPath = '/data1/zhzhang/Auto_ASF_Download/test4inter';
    
    
    % Define the origin time
    originTime = '2018-01-11T06:59:30.470Z';                               % Please type the earthquake time by yyyy-mm-ddThh-MM-ss-SSSZ
    % TIME CHOOSE
    timeMode = 1;
    if timeMode == 1
        OrigintimeDate      = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'); 
        TimeRange_before    = 150;                       
        TimeRange_after     = 150;
        calculatedStartTime = OrigintimeDate - days(TimeRange_before);                         
        calculatedEndTime   = OrigintimeDate + days(TimeRange_after); 
        
    elseif timeMode == 2
        OrigintimeDate      = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
        currentTime         = datetime('now', 'Format', 'yyyy-MM-dd''T''HH:mm:ss''Z''');
        TimeRange_before    = 30; 
        calculatedStartTime = OrigintimeDate - days(TimeRange_before);                         
        calculatedEndTime   = currentTime;
    end
    
    startTime = datestr(calculatedStartTime, 'yyyy-mm-ddTHH:MM:SSZ');
    endTime   = datestr(calculatedEndTime, 'yyyy-mm-ddTHH:MM:SSZ');
    
    
    % Choose points
    points = struct();
    figure;
    worldmap('World'); 
    load coastlines;   
    geoshow(coastlat, coastlon, 'DisplayType', 'line', 'Color', 'black'); 
    title('Please choose 4 points.');
    [lon, lat] = inputm(4);  
    hold on;
    for i = 1:4
        plotm(lat(i), lon(i), 'ro', 'MarkerSize', 10, 'MarkerFaceColor', 'r');  % 标记点
        textm(lat(i), lon(i) + 5, sprintf('P%d', i), 'Color', 'r', 'FontSize', 12);  % 标注点编号
        points(i).lat = lat(i);
        points(i).lon = lon(i);
    
    end
    boundingbox_upper_right_lon   = points(4).lon;
    boundingbox_upper_right_lat   = points(4).lat;
    boundingbox_upper_left_lon    = points(1).lon;
    boundingbox_upper_left_lat    = points(1).lat;
    boundingbox_bottom_right_lon  = points(3).lon;
    boundingbox_bottom_right_lat  = points(3).lat;
    boundingbox_bottom_left_lon   = points(2).lon;
    boundingbox_bottom_left_lat   = points(2).lat;
    close all;
    

    url_of_csv = sprintf(baseURL,platform,startTime, endTime,...
            boundingbox_upper_left_lon,boundingbox_upper_left_lat,...
                boundingbox_upper_right_lon,boundingbox_upper_right_lat,...
                    boundingbox_bottom_right_lon,boundingbox_bottom_right_lat,...
                        boundingbox_bottom_left_lon,boundingbox_bottom_left_lat,...
                            boundingbox_upper_left_lon,boundingbox_upper_left_lat);
    
     % Output the generated URL
    fprintf('###The url you wanted is: %s\n', url_of_csv);
    
    % Download the search results list
    SearchResults_Folder = './csvfloder_post_seis';
    if ~exist(SearchResults_Folder, 'dir')
        mkdir(SearchResults_Folder);
    end
    csvFilePath = fullfile(SearchResults_Folder, 'search_results.csv');
    % 
    websave(csvFilePath, url_of_csv);
    disp(['###The csv_file has been saved to: ', csvFilePath]);
    filelist_of_urls = getASFUrl4PostSeismic(csvFilePath,outputPath);
    
    
end
