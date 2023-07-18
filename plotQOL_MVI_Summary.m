function MVI_path = plotQOL_MVI_Summary(MVI_path)
%% Style of the 2021 FDA Report graphs 
%Editted for 2022 FDA report
%% Reruns MVI all results
if nargin < 1 || isempty(MVI_path)
    [~,all_results,~,MVI_path] = processQOL(1);
else
    [~,all_results,~,MVI_path] = processQOL(1,MVI_path);
end
fig_path = [MVI_path,filesep,'Summary Figures'];
subjects = unique(all_results(2:end,1));
sub_mark = 'xdo^ps+hv<>|_'; %MVI001-MVI010
survs = {'DHI Overall','SF-36 Utility','VADL Overall','HUI3 Overall'};
MCIDs = [18,0.03,0,0.03];
%Find indecies that correspond to visits of interest
v0_ind = NaN(1,length(subjects));
v1_ind = NaN(1,length(subjects));
v3_ind = NaN(1,length(subjects));
v9x_ind = NaN(1,length(subjects));
v10x_ind = NaN(1,length(subjects));
v11x_ind = NaN(1,length(subjects));
v0_ind(ismember(subjects,all_results(cellfun(@(x) strcmp(x,'0'),all_results(:,3)),1))) = find(cellfun(@(x) strcmp(x,'0'),all_results(:,3)));
v1_ind(ismember(subjects,all_results(cellfun(@(x) strcmp(x,'1'),all_results(:,3)),1))) = find(cellfun(@(x) strcmp(x,'1'),all_results(:,3)));
v3_ind(ismember(subjects,all_results(cellfun(@(x) strcmp(x,'3'),all_results(:,3)),1))) = find(cellfun(@(x) strcmp(x,'3'),all_results(:,3)));
v9x_ind(ismember(subjects,all_results(cellfun(@(x) strcmp(x,'9x'),all_results(:,3)),1))) = find(cellfun(@(x) strcmp(x,'9x'),all_results(:,3)));
v10x_ind(ismember(subjects,all_results(cellfun(@(x) strcmp(x,'10x'),all_results(:,3)),1))) = find(cellfun(@(x) strcmp(x,'10x'),all_results(:,3)));
v11x_ind(ismember(subjects,all_results(cellfun(@(x) strcmp(x,'11x'),all_results(:,3)),1))) = find(cellfun(@(x) strcmp(x,'11x'),all_results(:,3)));
%Make matrix with the data from the 4 main surveys at the time points of 0,
%0.5, 1, and 2 yrs post-implantation
surv_mat = NaN(4,length(subjects),length(survs));
surv_mat(1,:,:) = 0; %v0-v0 = 0
for j = 1:length(survs)
    surv_ind = find(contains(all_results(1,:),survs{j}));
    for i = 1:length(subjects)
        if ~isnan(v9x_ind(i))
            surv_mat(2,i,j) = all_results{v9x_ind(i),surv_ind}-all_results{v0_ind(i),surv_ind}; 
        end
        if ~isnan(v10x_ind(i))
            surv_mat(3,i,j) = all_results{v10x_ind(i),surv_ind}-all_results{v0_ind(i),surv_ind}; 
        end
        if ~isnan(v11x_ind(i))
            surv_mat(4,i,j) = all_results{v11x_ind(i),surv_ind}-all_results{v0_ind(i),surv_ind}; 
        end
    end
end
%% Scores Over Time Every Subject
fig1 = figure(1);
clf;
set(fig1,'Units','inches','Position',[1 1 7 7],'Color',[1,1,1])
xmin = 0.07;
xmax = 0.98;
xspc = 0.08;
ymin = 0.07;
ymax = 0.96;
yspc = 0.03;
sublinewid = 0.5;
sublinecol = 0*[1,1,1];
submarkwid = 0.5;
submarksize= 8;
labfontsize = 9;
color = repmat({'k'},length(subjects),1);
%Initialize axes
ha = gobjects(4,1);
h1 = gobjects(length(subjects),1);
for i = 1:4
    ha(i) = subplot(2,2,i);
end
%Set positions
xwid = (xmax-xmin-xspc)/2; %set for 2 cols
x = xmin:(xwid+xspc):xmax;
ywid = (ymax-ymin-yspc)/2; %set for 2 rows
y = ymin:(ywid+yspc):ymax;
ha(1).Position = [x(1) y(2) xwid ywid];
ha(2).Position = [x(2) y(2) xwid ywid];
ha(3).Position = [x(1) y(1) xwid ywid];
ha(4).Position = [x(2) y(1) xwid ywid];
%Plot
years2plot = [-0.1,0,0.2,0.5,1,2,4];
xtick2plot = [17,years2plot(2:end)*365.25+30];
XLim = [13 3000]; 
YLim = [-7 100; 0.43 0.93; -0.15 7.5; -0.14 1.05];
for i = 1:4
    surv_ind = find(contains(all_results(1,:),survs{i}));
    sub_surv = all_results(:,[1:3,surv_ind]); 
    axes(ha(i))
    plot(NaN,NaN)
    hold on
    for j = 1:length(subjects)
        sub_rel_inds = contains(sub_surv(:,1),subjects{j});
        %Remove Surveys before Visit 0
        if find(sub_rel_inds,1,'first') < v0_ind(j)
            sub_rel_inds(1:v0_ind(j)-1) = 0;
        end
        %If there was a Visit 1 survey, remove surveys before that
        if ~isnan(v1_ind(j))
            if find(sub_rel_inds,1,'first') < v1_ind(j)
                sub_rel_inds(1:v1_ind(j)-1) = 0;
            end
        end
        sub_t = days(datetime(sub_surv(sub_rel_inds,2))-datetime(sub_surv(v3_ind(j),2)))+30;
        sub_t(1) = 17; %Shift visit 0 
        rel_mat = [sub_surv{sub_rel_inds,4}];
        h1(j) = plot(sub_t,rel_mat,sub_mark(j),'Color',color{j},'LineWidth',submarkwid,'MarkerSize',submarksize);
        plot(sub_t,rel_mat,'-','Color',sublinecol,'LineWidth',sublinewid)
    end
    hold off
    ylabel(ha(i),survs{i}) 
    set(ha(i),'YLim',YLim(i,:))
end
set(ha,'XLim',XLim,'XScale','log','FontSize',labfontsize,...
    'xtick',xtick2plot,'xticklabel',years2plot,'xminortick','off')
set(ha(1:2),'xticklabel',[])
set(ha([1,3]),'YDir','reverse')
xlabel(ha(3:4),'Years Since Activation')  
title(ha(1),{'Vestibular Disability and Dizziness'})
title(ha(2),{'Health-Related Quality of Life'})
leg2_labs = {'1','2','3','4','5','6','7','8','9','10','11','12'};
leg2 = legend(ha(2),h1,leg2_labs,'Location','southeast','NumColumns',6,'box','off');
leg2.ItemTokenSize(1) = 5;
text(ha(2),1*365.25+30,0.52,'Subjects')
%Figure letter labels
annot_wid_x = 0.04;
annot_wid_y = 0.04;
annot_pos_x = [(x(1)+0.009)*ones(1,2),(x(2)+0.009)*ones(1,2)];
annot_pos_y = repmat([ymax-annot_wid_y-0.01,(ymin+ywid)-annot_wid_y-0.01],1,2);
annot_string = {'A','B','C','D'};
for i = 1:length(annot_string)
    annotation('textbox',[annot_pos_x(i),annot_pos_y(i),annot_wid_x,annot_wid_y],...
        'String',annot_string{i},'HorizontalAlignment','center',...
        'VerticalAlignment','middle','FontWeight','bold','FontSize',20,...
        'Fitboxtotext','off','BackgroundColor',[1,1,1]);
end 
fname1 = [fig_path,filesep,datestr(now,'yyyymmdd'),'_SummaryQOLOverTime_AllSub.fig'];
savefig(fig1,fname1)
saveas(fig1,strrep(fname1,'fig','png'))
%% Boxplot with year follow ups
line_norm = 0.5;
line_bold = 1.5;
mark_size_big = 25;
mark_size_med = 8;
offs1 = 0.2*rand(length(subjects),1)-0.1;
ha = gobjects(4,1);
h1 = gobjects(2,1);
h2 = gobjects(length(subjects),1);

xmin = 0.08;
xmax = 0.99;
ymin = 0.10;
ymax = 0.99;
yspac = 0.02;
xspac = 0.09; 
xwid = (xmax-xmin-xspac)/2;
ywid = (ymax-ymin-yspac)/2;
xpos = [xmin,xmin+xwid+xspac,xmin,xmin+xwid+xspac];
ypos = [ymax-ywid,ymax-ywid,ymin,ymin];

fig2 = figure(2);
clf;
set(fig2,'Color',[1,1,1],'units','inches','Position',[1 1 6 4])
for j = 1:4
   ha(j) = subplot(2,2,j); 
end
for j = 1:4
    axes(ha(j))
    h1(2) = fill([0.5 4.5 4.5 0.5],MCIDs(j)*[-1 -1 1 1],0.85*[1,1,1],'EdgeColor',0.85*[1,1,1]);
    hold on
    plot([0.5 4.5],[0,0],'k:')
    b = boxplot(surv_mat(:,:,j)','Color','k','Width',0.1,'Symbol','','ExtremeMode','clip');
    set(b,'LineWidth',1.25,'LineStyle','-')
    plot(1,0,'Color','k','Marker','.','MarkerSize',mark_size_big,'LineWidth',line_norm)
    h1(1) = plot(1:4,median(surv_mat(:,:,j),2,'omitnan'),'-','Color','k','LineWidth',line_bold);
    for i=1:length(subjects)
        h2(i) = plot((2:4)+offs1(i)-0.3,surv_mat(2:end,i,j),'.','Color','k','Marker',sub_mark(i),'MarkerSize',mark_size_med,'LineWidth',line_norm);
    end
    hold off 
    set(ha(j), 'Layer', 'top');
    ylabel(ha(j),['\Delta',survs{j}]) 
end

set(ha,'box','on','XTick',1:4,'XLim',[0.75 4.25])
set(ha(1),'YDir','reverse','YLim',[-70,50])
set(ha(2),'YLim',[-0.159,0.259])
set(ha(3),'YDir','reverse','YLim',[-4.5,0.5])
set(ha(4),'YLim',[-0.83,0.83])
set(ha(1:2),'XTickLabel',[])
set(ha(3:4),'XTickLabel',{'0','0.5','1','2'});
xlabel(ha(3:4),'Years After Implantation')
%Legends
leg1_labs = {'Median Change from Pre-Op','Minimally Important Difference'};
leg1 = legend(ha(1),h1,leg1_labs,'Location','southeast','NumColumns',1,'box','off');
leg1.ItemTokenSize(1) = 15;
leg2_labs = {'1','2','3','4','5','6','7','8','9','10','11','12'};
leg2 = legend(ha(2),h2,leg2_labs,'Location','southeast','NumColumns',6,'box','off');
leg2.ItemTokenSize(1) = 5;
text(ha(2),1,-0.09,'Subjects')
%Set axes position now
for j = 1:4
    ha(j).Position = [xpos(j) ypos(j) xwid ywid];
end
%Figure letter labels
annot_wid_x = 0.042;
annot_wid_y = 0.06;
annot_pos_x = [(xpos(1)+0.009)*ones(1,2),(xpos(2)+0.009)*ones(1,2)];
annot_pos_y = repmat([ymax-annot_wid_y-0.013,(ymin+ywid)-annot_wid_y-0.013],1,2);
annot_string = {'A','B','C','D'};
for i = 1:length(annot_string)
    annotation('textbox',[annot_pos_x(i),annot_pos_y(i),annot_wid_x,annot_wid_y],...
        'String',annot_string{i},'HorizontalAlignment','center',...
        'VerticalAlignment','middle','FontWeight','bold','FontSize',20,...
        'Fitboxtotext','off','BackgroundColor',[1,1,1]);
end 
fname2 = [fig_path,filesep,datestr(now,'yyyymmdd'),'_SummaryQOLPreOpChange_AllSub.fig'];
savefig(fig2,fname2)
saveas(fig2,strrep(fname2,'fig','png'))
end