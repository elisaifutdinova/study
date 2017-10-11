function barplot_with_std(means, stds, params)
    %% means and stds are matrices N by M
    % where N is number of metrics and M is number of measurements
    [N, M] = size(means);
    
    %% params contains names:
    % .title - title of the figure
    % .names - names of metrics
    % .xlabel - xlabel
    % .ylabel - ylabel
    title_ = params.title;
    names_ = params.names;
    experiments_ = params.experiments;
    xlabel_ = params.xlabel;
    ylabel_ = params.ylabel;
    
    figure;
    hold on;
    set(gcf,'color','w');
    colors = colormap(winter(M));
    border_color = 'k';
    
    for metrics_i = 1:N
        for measurement_i = 1:M
            x = (metrics_i-1)*(M+1) + (measurement_i-1);
            y = means(metrics_i, measurement_i);
            s = stds(metrics_i, measurement_i);
            middle = x+0.55;
            
            rectangle('Position',[ x+0.1, 0, 1-0.1, y],...
            'FaceColor', colors(measurement_i,:),'EdgeColor', border_color)
        
            plot([middle middle], [y-s y+s], border_color)
            plot([middle-0.05 middle+0.05], [y-s y-s], border_color)
            plot([middle-0.05 middle+0.05], [y+s y+s], border_color)
            
            t = text(middle,0.01, experiments_(measurement_i));
            set(t, 'rotation', 90)
        end
    end
    xlabel(xlabel_)
    ylabel(ylabel_)
    title(title_)
    
    set(gca,'XTick',M/2:M+1:(M+1)*N);
    set(gca,'XTickLabel',names_);
   
end
