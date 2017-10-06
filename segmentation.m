function adapt_borders = segmentation(data, settings)

    % upload settings
    window_length = settings.window_lenght; %(in seconds)
    step = settings.window_step; % in samples
    fs = settings.sample_frequency; % samples per second


    % moving windows segemntation algorithm
    window = ceil( window_length * fs); % (samples)
    window_subnum = ceil(window/step); % (samples)

    % buffering
    data_buffered = buffer(data, window, [window-step], 'nodelay');
    total_segmments = size(data_buffered, 2);

    % statistic function
    func_std = std(data_buffered);
    clear data_buffered;

    % indexes for two windows
    first_window_indexes = 1 : total_segmments-window_subnum;
    second_window_indexes = first_window_indexes + window_subnum;

    % difference between two windows
    func_std_diff = abs(func_std(first_window_indexes) - func_std(second_window_indexes));
    func_std_diff = func_std_diff/max(func_std_diff);
    
    %find peaks
    MPH = std(func_std_diff);
    MPD = ceil(window/step);
    [~, locs] = findpeaks(func_std_diff, 'MINPEAKDISTANCE', MPD, 'MINPEAKHEIGHT', MPH);
    adapt_borders = window + (locs-1)*step;
end

