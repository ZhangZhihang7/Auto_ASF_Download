function filelist_of_urls = getASFUrl4PostSeismic(csvFilePath,outputPath)
% Read CSV file and replace with your actual CSV file path
dataTable = readtable(csvFilePath, 'Delimiter', ',');
% dataTable = readtable('/data1/zhzhang/Auto_ASF_Download/csvfloder_post_seis/search_results.csv', 'Delimiter', ',');
save('dataTable.mat', 'dataTable');

uniquePath_data = table();

% Read the Track or Path number of Sentinel-1A 
path_number_column = (dataTable{:, 7}); 
path_numbers = unique(path_number_column);

for i = 1:length(path_numbers)
    % Make an index of path/track, this step is to make sure each
    % path's/track's data will be correctly capture.
    path_data_idx = path_number_column == path_numbers(i);  
    path_data = dataTable(path_data_idx, :);
    
    % Create an file name and floder name by track/path number.
    PathNum = path_data{1, 7};
    PathNum = sprintf('%03d', PathNum);  
    
    % Add the ASCENDING or DESCENDING suffix after track/path number.
    if strcmp(path_data{1, 25}, 'DESCENDING')
        suffix = 'dsc';
    elseif strcmp(path_data{1, 25}, 'ASCENDING')
        suffix = 'asc';
    else
        error('Unexpected value in column 25.'); 
    end
    track_Name = sprintf('t%s%s', PathNum, suffix);
    
    % Save 'PathNum', 'FrameNum', 'Direction', 'Urls', 'FileSize' to each
    % track/path floder as a table for future search.
    uniquePath_data = path_data(:, [7, 8, 25, 26, 27]);
    uniquePath_data.Properties.VariableNames = {'PathNum', 'FrameNum', 'Direction', 'Urls', 'FileSize'};
    
    % Create a output floder.
    subpath = [track_Name];
    outputPath_by_track = fullfile(outputPath,subpath);
    if ~exist(outputPath_by_track, 'dir')
    mkdir(outputPath_by_track);
    end
 
    save(track_Name, 'uniquePath_data');
    
    % Move the table to each floder named by path/track.
    movefile([track_Name,'.mat'],outputPath_by_track); 
    
    fileName = 'filelist';
    fileID = fopen(fileName, 'w');
    filelist_of_urls = {};
    for i = 1:length(uniquePath_data.Urls)
    
        fprintf(fileID, '%s\n', uniquePath_data.Urls{i});
    end
    
    % Move the filelist contain the urls to each floder named by path/track.
    movefile('filelist',outputPath_by_track); 
    
    fclose(fileID);

end

end