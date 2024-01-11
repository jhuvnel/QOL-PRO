%% Rerun script to generate REDCAP struct and load in the most recent MVI data
%Right now, this script generates but doesn't save the figure
function MVI_path = plotQOL_MVI_Candidate(MVI_path)
%% Style of the 2021 FDA Report graphs 
%Editted for 2022 FDA report
%% Reruns MVI all results
if nargin < 1 || isempty(MVI_path)
    [~,all_results,scores,MVI_path] = processQOL(3);
else
    [~,all_results,scores,MVI_path] = processQOL(3,MVI_path);
end
temp = split(scores{1,2},' | ');
Rnum = temp(1);
Rdate = strrep(strrep(strrep(temp{end},'-',''),' ','-'),':','');
subjects = [unique(all_results(2:end,1));Rnum];
sub_num = [cellfun(@(x) num2str(str2double(x(4:6))),unique(all_results(2:end,1)),'UniformOutput',false);Rnum];
plot_marker_all = 'xdo^ps+hv<>|_*';
plot_marker = plot_marker_all([1:(length(subjects)-1),length(plot_marker_all)]);
if length(subjects)>length(plot_marker)
    disp('Not enough defined plot markers for the number of subjects')
    return;
end
color = repmat({'k'},length(subjects),1);
color(end) = {'b'};
surv_ind1 = [find(contains(all_results(1,:),'DHI Overall')),...
    find(contains(all_results(1,:),'VADL Overall')),...
    find(contains(all_results(1,:),'SF-36 Utility')),...
    find(contains(all_results(1,:),'HUI3 Overall'))];
surv_ind2 = [find(contains(scores(:,1),'DHI Overall')),...
    find(contains(scores(:,1),'VADL Overall')),...
    find(contains(scores(:,1),'SF-36 Utility')),...
    find(contains(scores(:,1),'HUI3 Overall'))];
v0_resp = [cell2mat(all_results(cellfun(@(x) strcmp(x,'0'),all_results(:,3)),surv_ind1));cell2mat(scores(surv_ind2,2))'];
offs = zeros(length(subjects),4);
spread = 0.10;
base_offs = repmat([0,-spread,spread],1,ceil(length(subjects)/3));
base_offs = base_offs(1:length(subjects));
for i = 1:4
    [~,sind] = sort(v0_resp(:,i));
    offs(sind,i) = base_offs;
end
submarkwid = 0.5;
submarksize = 8;
fig = figure(1);
clf;
set(fig,'Color',[1,1,1],'Units','inches','Position',[1 1 5 5]);
h = gobjects(length(subjects),1);
ha = gobjects(1,4);
for i = 1:4
    ha(i) = subplot(1,4,i);
end
%Size the axes
x_min = 0.08;
x_max = 0.99;
x_space = 0.07;
y_min = 0.1;
y_max = 0.95;
x_wid = (x_max-x_min-3*x_space)/4;
y_height = y_max-y_min;
x = x_min:(x_space+x_wid):x_max;
for i = 1:4
    ha(i).Position = [x(i) y_min x_wid y_height];
    axes(ha(i))
    plot(NaN,NaN)
    hold on
    for j = 1:length(subjects)
        h(j) = plot(1+offs(j),v0_resp(j,i),plot_marker(j),'Color',color{j},'LineWidth',submarkwid,'MarkerSize',submarksize);
    end
    hold off   
end
set(ha,'XLim',[0.8 1.2],'XTick',[],'XTickLabel',[])
set(ha(1:2),'YDir','reverse')
set(ha(1),'YLim',[-10 110])
set(ha(2),'YLim',[0.1 10.9])
set(ha(3),'YLim',[0.23 0.97])
set(ha(4),'YLim',[-0.1 1.1])
title(ha(1),'DHI')
title(ha(2),'VADL')
title(ha(3),'SF36U')
title(ha(4),'HUI3')
leg = legend(ha(1),h,sub_num,'NumColumns',length(subjects),'box','off');
leg.ItemTokenSize(1) = 7;
leg.Position = [0,0,0.99,0.1];
title(leg,'Subjects')
disp([Rnum{:},'-',Rdate,'-SurveyResponses'])
end