function filelist_of_urls = getASFUrl4CoSeismic(basetimeDate,csvFilePath)





% Read CSV file and replace with your actual CSV file path
dataTable = readtable(csvFilePath, 'Delimiter', ',');
save('dataTable.mat', 'dataTable');

% Given input time
% originTime = '';                                                         % Please type the earthquake time by yyyy-mm-ddThh-MM-ss-SSSZ
% origin_timeDate = datetime(originTime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z'); 
origin_timeDate = basetimeDate;
% Read the End Time from asf-datapool-results_xxxx.csv to make sure it's latest time.
asf_endtime = (dataTable{:, 13}); 
asf_endtimeData = datetime(asf_endtime, 'InputFormat', 'yyyy-MM-dd''T''HH:mm:ss.SSS''Z');
% Read the Track or Path number of Sentinel-1A 
path_number_column = (dataTable{:, 7}); 
path_numbers = unique(path_number_column);

% Compare the time between origin time and asf end_time, choose out the closest
% data, and if some path have 2 frames, keep them all.
closest_data = struct();
for i = 1:length(path_numbers)
    % Make an index of path/track, this step is to make sure each
    % path's/track's data will be correctly capture.
    path_data_idx = path_number_column == path_numbers(i);  
    path_data = dataTable(path_data_idx, :);   
    path_time = asf_endtimeData(path_data_idx);  
    time_diff = path_time - origin_timeDate;                               % Calculate the difference between origin time and asf end_time
    master_idx = find(time_diff < 0);                                      % Master image's index
    slave_idx = find(time_diff > 0);                                       % Slave image's index
   
    % Detect the difference between the time of the master image and the
    % origin time, and provide that is closest to and before the origin
    % time. Considering that there may be cases where 2 feames are
    % involved, we will take the image(s) whose time diff doesnot above
    % 5 mins compared with the closest time.
    if ~isempty(master_idx)
    % Find 2 images if there are more than 1 frame in a track.
    [sorted_diff, sorted_indices] = sort(abs(time_diff(master_idx)));      % Sort the time difference
    master_closest_idx = master_idx(sorted_indices(1));                    % Find the 1st close to the origin time
        if length(sorted_diff) > 1
        second_closest_idx = master_idx(sorted_indices(2));                % Find the 2nd close to the origin time
            if minutes(sorted_diff(2) - sorted_diff(1)) <= 5               % Compare the difference between top 2 close to the origin time,
            master_idx = [master_closest_idx, second_closest_idx];         % and keep index if the dff are not above 5 mins
            else
            master_idx = master_closest_idx;                        
            end
        else
        % 
        master_idx = master_closest_idx;                                   % Keep only the closest index if the time diff is above 5 mins
        end
    else
    master_idx = [];
    end

    % As same as above but for slave time.
    if ~isempty(slave_idx)
    [sorted_diff, sorted_indices] = sort(abs(time_diff(slave_idx))); 
    slave_closest_idx = slave_idx(sorted_indices(1));   
        if length(sorted_diff) > 1
        second_closest_idx = slave_idx(sorted_indices(2)); 
            if minutes(sorted_diff(2) - sorted_diff(1)) <= 5
            slave_idx = [slave_closest_idx, second_closest_idx];
            else
            slave_idx = slave_closest_idx;
            end
        else
        slave_idx = slave_closest_idx;
        end
    else
    slave_idx = [];  
    end   
    
    % Save
    if ~isempty(master_idx) || ~isempty(slave_idx)
    closest_data(i).PathNumber = path_numbers(i);
        if ~isempty(master_idx)
%         closest_data(i).MasterTime = path_time(master_idx);
        closest_data(i).MasterRow = path_data(master_idx, :);
        elseif numel(master_idx) == 2
%             closest_data(i).SlaveTime = path_time(slave_idx); 
            closest_data(i).MasterRow = path_data(master_idx, :); 
        else
%         closest_data(i).MasterTime = NaT;
        closest_data(i).MasterRow = [];
        end
        if ~isempty(slave_idx)
            if numel(slave_idx) == 1
%             closest_data(i).SlaveTime = path_time(slave_idx);
            closest_data(i).SlaveRow = path_data(slave_idx, :);   
            elseif numel(slave_idx) == 2
%             closest_data(i).SlaveTime = path_time(slave_idx); 
            closest_data(i).SlaveRow = path_data(slave_idx, :); 
            else
%             closest_data(i).SlaveTime = path_time(slave_idx(1));
            closest_data(i).SlaveRow = path_data(slave_idx(1), :);
            end
        else
        closest_data(i).SlaveTime = NaT;
        closest_data(i).SlaveRow = [];
        end
    end

end

save('closest_data.mat', 'closest_data');
load('closest_data.mat'); 

% Make a new filelist to save the url
fileID = fopen('filelist', 'a');
filelist_of_urls = {};
for i = 1:length(closest_data)
    master_row = closest_data(i).MasterRow;
    slave_row = closest_data(i).SlaveRow; 
    if ~isempty(master_row)
        master_col26 = table2array(master_row(:, 26));
        for j = 1:length(master_col26)
            if iscell(master_col26) 
                fprintf(fileID, '%s\n', master_col26{j});
            else  
                fprintf(fileID, '%s\n', string(master_col26(j)));
            end
        end
    end
    
    if ~isempty(slave_row)
        slave_col26 = table2array(slave_row(:, 26));  
        for j = 1:length(slave_col26)
            if iscell(slave_col26) 
                fprintf(fileID, '%s\n', slave_col26{j});
            else  
                fprintf(fileID, '%s\n', string(slave_col26(j)));
            end
        end
    end
end
fclose(fileID);
    

  % Report completion
  fprintf('Output has been successfully saved to "filelist".\n');
end

