%% Plot QOL MVI Each Survey
%This script will load the most recent Pooled Data file and plot any of the
%requested scores or subscores.
[~,all_results,~,MVI_path] = QOL(1);
subjects = unique(all_results(2:end,1));
surveys = all_results(1,4:end);
plot_marker_all = 'xdo^ps+hv<*';
if length(subjects)>length(plot_marker_all)
    disp('Not enough defined plot markers for the number of subjects')
    return;
end
%Select subjects to plot
inds = 1:length(subjects);
% [inds,tf1] = listdlg('PromptString','Select the subjects to plot:',...
%     'SelectionMode','multiple',...
%     'InitialValue',1:length(subjects),...
%     'ListString',subjects);
% if ~tf1
%     error('No subjects selected')
% end
rm_sub = ~contains(all_results(:,1),subjects(inds));
all_results(rm_sub,:) = [];
subjects = subjects(inds);
sub_num = cellfun(@(x) num2str(str2num(x(4:6))),subjects,'UniformOutput',false);
plot_marker = plot_marker_all(inds);
%Select subjects to make blue
ind_blue = listdlg('PromptString','Select the subjects to bold:',...
    'SelectionMode','multiple',...
    'ListString',subjects);
color = repmat({'k'},length(subjects),1);
color(ind_blue) = {'b'};
%Select surveys to plot
[ind_surv,tf2] = listdlg('PromptString','Select the surveys to plot:',...
    'SelectionMode','multiple',...
    'ListString',surveys,...
    'InitialValue',find(contains(surveys,{'Utility','Overall'})&contains(surveys,{'DHI','HUI','SF-36','VADL'})));
if ~tf2
    error('No surveys selected')
end
%Find indecies that correspond to visits of interest--must be one Vis 0 per
%subject
% Make all relevant matricies
v0_ind = find(cellfun(@(x) strcmp(x,'0'),all_results(:,3)));
if length(v0_ind)~=length(subjects)
    error('Mismatch in number of subjects and Visit 0 data points found')
end
all_scores_mat = cell2mat(all_results(:,4:end));
[~,val] = ismember(all_results(:,1),subjects);
all_scores_diff_mat = all_scores_mat - all_scores_mat(v0_ind(val),:);
all_scores_diff_mat(:,contains(surveys,'SF-36 Health Change')) = all_scores_mat(:,contains(surveys,'SF-36 Health Change'))-50;
vis = {'9x','10x','11x'}; %0.5, 1, 2 yr visit
diff_yr_mat = NaN(length(subjects),length(vis),length(surveys)); 
for i = 1:length(vis)
    diff_yr_mat(ismember(subjects,all_results(cellfun(@(x) strcmp(x,vis{i}),all_results(:,3)),1)),i,:) = all_scores_diff_mat(cellfun(@(x) strcmp(x,vis{i}),all_results(:,3)),:);
end
%% Plot Over Time and Change From Vis0 at 0.5, 1, and 2 years
% Set plot defaults
years2plot = [-0.1,0,0.2,0.5,1,2,4];
xtick2plot = [21,years2plot(2:end)*365.25+30];
sublinewid = 0.5;
sublinecol = 0*[1,1,1];
submarkwid = 0.5;
submarksize= 8;
XLim1 = [17 2600];
XLim2 = [0.35 length(vis)+0.35];
x1 = 0.10;
wid_x1 = 0.65;
x2 = 0.8;
wid_x2 = 0.19;
y1 = 0.09;
height_y = 0.86;
offs = 0.05*randn(length(subjects),1);
ylabsize = 12;
for i = 1:length(ind_surv)
    Score = surveys{ind_surv(i)};
    sub_surv = all_results(:,[1:3,ind_surv(i)+3]);
    sub_mat = all_scores_mat(:,ind_surv(i));
    sub_diff_mat = reshape(diff_yr_mat(:,:,ind_surv(i)),length(subjects),length(vis));  
    %Display stats
    disp([Score,': '])
    for j = 1:length(vis)
        if sum(~isnan(sub_diff_mat(:,j)))<6
            disp(['No stats available at Visit ',vis{j},' because n=',num2str(sum(~isnan(sub_diff_mat(:,j))))])
        else
            disp(['At Visit ',vis{j},' two-tailed signrank test: ',num2str(signrank(sub_diff_mat(:,j)),2),', n=',num2str(sum(~isnan(sub_diff_mat(:,j))))])        
        end
    end
    %Open the figure
    fig = figure(i);
    set(fig,'Color',[1,1,1],'Units','inches','Position',[5 4 7 5])
    ha(1) = subplot(2,1,1);
    ha(2) = subplot(2,1,2);
    set(ha(1),'Position',[x1,y1,wid_x1,height_y])
    set(ha(2),'Position',[x2,y1,wid_x2,height_y])
    h = gobjects(length(subjects),1);
    % Plot the Score Over Time first
    axes(ha(1))
    hold on
    for j=1:length(subjects)
        sub_rel_inds = find(contains(all_results(:,1),subjects{j}));
        sub_rel_inds(sub_rel_inds<v0_ind(j)) = [];
        sub_t = days(datetime(all_results(sub_rel_inds,2))-datetime(all_results(v0_ind(j),2)));
        sub_t(1) = 21; %Shift visit 0
        rel_mat = all_scores_mat(sub_rel_inds,ind_surv(i));
        plot(sub_t,rel_mat,plot_marker(j),'Color',color{j},'LineWidth',submarkwid,'MarkerSize',submarksize)
        plot(sub_t,rel_mat,'-','Color',color{j},'LineWidth',sublinewid)
        h(j) = plot(NaN,NaN,plot_marker(j),'Color',color{j},'LineWidth',submarkwid,'MarkerSize',submarksize);
    end
    hold off
    axes(ha(2))
    plot(NaN,NaN)
    hold on
    plot(XLim2,[0,0],'k:')
    b = boxplot(sub_diff_mat,'Colors','k','Width',0.2,'Symbol','');
    set(b,'LineWidth',1.25,'LineStyle','-')
    for j = 1:length(subjects) %plot each subject
        for v = 1:length(vis)
            plot(v+offs(j)-0.25,sub_diff_mat(j,v),plot_marker(j),'Color',color{j},'LineWidth',submarkwid,'MarkerSize',submarksize);
        end
    end
    hold off
    set(ha,'FontSize',10)
    set(ha(1),'XLim',XLim1,'XScale','log','box','on',...
        'xtick',xtick2plot,'xticklabel',years2plot,'xminortick','off')
    set(ha(2),'XTick',1:3,'XTickLabel',{'0.5','1','2'},...
        'XLim',XLim2)
    title(ha(1),'Score Over Time','FontSize',12,'FontWeight','bold')
    title(ha(2),'Change','FontSize',12,'FontWeight','bold')  
    xlabel(ha(1),'Years Since Activation','FontSize',10)
    xlabel(ha(2),'Years','FontSize',10)
    ylabel(ha(1),Score,'FontSize',20)
    if contains(Score,{'DHI','VADL','VSS','OVAS','VAS'})
        set(ha,'YDir','reverse') %Better scores on top
    end
    leg = legend(ha(1),h,sub_num,'NumColumns',length(subjects),'box','off','Location','southeast');
    leg.ItemTokenSize(1) = 7;
    fig_name = [datestr(now,'yyyymmdd'),'_QOL_',strrep(Score,' ','')];
    savefig(fig,[MVI_path,filesep,'Summary Figures',filesep,fig_name,'.fig'])
    saveas(fig,[MVI_path,filesep,'Summary Figures',filesep,fig_name,'.png'])
end