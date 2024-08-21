function MVI_path = plotQOL_MVI_Summary(MVI_path)
%% Reruns MVI all results
if nargin < 1 || isempty(MVI_path)
    [~,all_results,~,MVI_path] = processQOL(1);
else
    [~,all_results,~,MVI_path] = processQOL(1,MVI_path);
end
fig_path = [MVI_path,filesep,'Summary Figures'];
subjects = unique(all_results(2:end,1));
sub_mark = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'; 
survs = {'DHI Overall','SF-36 Utility','VADL Overall','HUI3 Overall'};
MCIDs = [18,0.03,0.65,0.03];
%Find indecies that correspond to visits of interest
main_vis = {'0','1','3','9x','10x','11x'};
ind = NaN(length(main_vis),length(subjects));
for i = 1:length(main_vis)
    ind(i,ismember(subjects,all_results(cellfun(@(x) strcmp(x,main_vis{i}),all_results(:,3)),1))) = ...
        find(cellfun(@(x) strcmp(x,main_vis{i}),all_results(:,3)));
end
%Make matrix with the data from the 4 main surveys at the time points of 0,
%0.5, 1, and 2 yrs post-implantation
surv_mat = NaN(4,length(subjects),length(survs));
surv_mat(1,:,:) = 0; %v0-v0 = 0
for j = 1:length(survs)
    surv_ind = find(contains(all_results(1,:),survs{j}));
    for i = 1:length(subjects)
        for k = 2:4
            if ~isnan(ind(k+2,i))
                surv_mat(k,i,j) = all_results{ind(k+2,i),surv_ind}-all_results{ind(1,i),surv_ind}; 
            end
        end
    end
end
%Plotting things applicable to both figures
sublinewid = 0.5;
sublinecol = 0*[1,1,1];
submarksize= 8;
labfontsize = 9;
line_norm = 0.5;
line_bold = 1.5;
mark_size_big = 25;
mark_size_med = 8;
offs1 = 0.2*rand(length(subjects),1)-0.1;
xlab = 'Years After Implantation';
leg1_labs = {'Median Change from Pre-Op','Minimally Important Difference'};
leg_cell = ['Participants   ',char(join(join([cellstr(sub_mark(1:length(subjects))'),...
    strrep(cellstr(num2str((1:length(subjects))')),' ','')],':'),' '))];
%% Fig 1: Scores Over Time Every Subject
%Inialize size and labels
xmin = 0.07; xmax = 0.99; xspc = 0.08;
xwid = (xmax-xmin-xspc)/2;
x = xmin:(xwid+xspc):xmax;
ymin = 0.11; ymax = 0.97; yspc = 0.03;
ywid = (ymax-ymin-yspc)/2;
y = ymin:(ywid+yspc):ymax;
years2plot = [-0.1,0,0.2,0.5,1,2,4,8];
xtick2plot = [17,years2plot(2:end)*365.25+30];
XLim = [13 3500]; 
YLim = [-7 100; 0.43 0.93; -0.15 7.5; -0.14 1.05];
%Initialize axes
ha = gobjects(4,1);
fig1 = figure(1);
clf;
set(fig1,'Units','inches','Position',[1 1 7 7],'Color',[1,1,1])
for i = 1:4
    sub_surv = all_results(:,contains(all_results(1,:),[all_results(1,1:3),survs(i)])); 
    ha(i) = subplot(2,2,i);
    plot(NaN,NaN)
    hold on
    for j = 1:length(subjects)
        sub_rel_inds = find(contains(sub_surv(:,1),subjects{j}));
        sub_rel_inds(sub_rel_inds<max(ind(1:2,j),[],'omitnan')) = []; %Remove surveys before visit 1 or 0
        rel_mat = [sub_surv{sub_rel_inds,4}];
        sub_t = days(datetime(sub_surv(sub_rel_inds,2))-datetime(sub_surv(ind(3,j),2)))+30;
        sub_t(1) = 17; %Shift visit 0 for plotting
        text(sub_t,rel_mat,sub_mark(j),'Color',sublinecol,'FontSize',submarksize,'HorizontalAlignment','center'); % plot subject labels
        plot(sub_t,rel_mat,':','Color',sublinecol,'LineWidth',sublinewid)
    end
    hold off
    ylabel(ha(i),survs{i}) 
    set(ha(i),'YLim',YLim(i,:))
end
%Set Position
ha(1).Position = [x(1) y(2) xwid ywid];
ha(2).Position = [x(2) y(2) xwid ywid];
ha(3).Position = [x(1) y(1) xwid ywid];
ha(4).Position = [x(2) y(1) xwid ywid];
%Set Properties
set(ha,'XLim',XLim,'XScale','log','FontSize',labfontsize,...
    'xtick',xtick2plot,'xticklabel',years2plot,'xminortick','off')
set(ha(1:2),'xticklabel',[])
set(ha([1,3]),'YDir','reverse')
xlabel(ha(3:4),xlab)  
title(ha(1),{'Vestibular Disability and Dizziness'})
title(ha(2),{'Health-Related Quality of Life'})
% Legend
annotation('textbox',[0.01 0.01 0.98 xmin],'String',leg_cell,'FontSize',submarksize,...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FitBoxToText','on');
% Figure letter labels
annot_wid_x = 0.04; annot_wid_y = 0.04;
annot_pos_x = [(x(1)+0.009)*ones(1,2),(x(2)+0.009)*ones(1,2)];
annot_pos_y = repmat([ymax-annot_wid_y-0.01,(ymin+ywid)-annot_wid_y-0.01],1,2);
for i = 1:4
    annotation('textbox',[annot_pos_x(i),annot_pos_y(i),annot_wid_x,annot_wid_y],...
        'String',char(64+i),'HorizontalAlignment','center',...
        'VerticalAlignment','middle','FontWeight','bold','FontSize',20,...
        'Fitboxtotext','off','BackgroundColor',[1,1,1]);
end 
fname1 = [fig_path,filesep,char(datetime('now','Format','yyyyMMdd')),'_SummaryQOLOverTime_AllSub.fig'];
savefig(fig1,fname1)
saveas(fig1,strrep(fname1,'fig','svg'))
%% Fig 2: Boxplot with year follow ups
ha = gobjects(4,1);
h1 = gobjects(2,1);
xmin = 0.08; xmax = 0.99; xspc = 0.09;
ymin = 0.21; ymax = 0.99; yspc = 0.02;
xwid = (xmax-xmin-xspc)/2; %set for 2 cols
x = xmin:(xwid+xspc):xmax;
ywid = (ymax-ymin-yspc)/2; %set for 2 rows
y = ymin:(ywid+yspc):ymax;
fig2 = figure(2);
clf;
set(fig2,'Color',[1,1,1],'units','inches','Position',[1 1 6 4])
for j = 1:4
    ha(j) = subplot(2,2,j); 
    h1(2) = fill([0.5 4.5 4.5 0.5],MCIDs(j)*[-1 -1 1 1],0.85*[1,1,1],'EdgeColor',0.85*[1,1,1]);
    hold on
    plot([0.5 4.5],[0,0],'k:')
    b = boxplot(surv_mat(:,:,j)','Color','k','Width',0.1,'Symbol','','ExtremeMode','clip');
    set(b,'LineWidth',1.25,'LineStyle','-')
    plot(1,0,'Color','k','Marker','.','MarkerSize',mark_size_big,'LineWidth',line_norm)
    h1(1) = plot(1:4,median(surv_mat(:,:,j),2,'omitnan'),'-','Color','k','LineWidth',line_bold);
    for i=1:length(subjects)
        text((2:4)+offs1(i)-0.3,surv_mat(2:end,i,j),sub_mark(i),'Color','k','FontSize',mark_size_med,'HorizontalAlignment','center'); % plot subject labels
    end
    hold off 
    set(ha(j), 'Layer', 'top');
    ylabel(ha(j),['\Delta',survs{j}]) 
end
%Set Position
ha(1).Position = [x(1) y(2) xwid ywid];
ha(2).Position = [x(2) y(2) xwid ywid];
ha(3).Position = [x(1) y(1) xwid ywid];
ha(4).Position = [x(2) y(1) xwid ywid];
set(ha,'box','on','XTick',1:4,'XLim',[0.75 4.25])
set(ha(1),'YDir','reverse','YLim',[-70,20])
set(ha(2),'YLim',[-0.039,0.259])
set(ha(3),'YDir','reverse','YLim',[-4.5,0.75])
set(ha(4),'YLim',[-0.83,0.83])
set(ha(1:2),'XTickLabel',[])
set(ha(3:4),'XTickLabel',{'0','0.5','1','2'});
xlabel(ha(3:4),xlab)
%Legends
leg1 = legend(ha(1),h1,leg1_labs,'Location','southwest','NumColumns',2,'box','off');
leg1.ItemTokenSize(1) = 15;
<<<<<<< HEAD
leg1.Position = [0.5-0.5*leg1.Position(3),0,leg1.Position(3:4)];
annotation('textbox',[0 leg1.Position(4) 1 xmin],'String',leg_cell,'FontSize',submarksize,...
    'HorizontalAlignment','center','VerticalAlignment','bottom','FitBoxToText','on');
=======

leg2 = annotation('textbox',[0.605,0.555,0.38,0.099],'String',leg_cell,'FontSize',8,'FitBoxToText','on');

text(ha(2),2.307,-0.0424,'Subjects')
%Set axes position now
for j = 1:4
    ha(j).Position = [xpos(j) ypos(j) xwid ywid];
end
>>>>>>> 943243a602ce712ce9534f1ba55fcab2038d611d
%Figure letter labels
annot_wid_x = 0.042;  annot_wid_y = 0.06;
annot_pos_x = [(x(1)+0.009)*ones(1,2),(x(2)+0.009)*ones(1,2)];
annot_pos_y = repmat([ymax-annot_wid_y-0.013,(ymin+ywid)-annot_wid_y-0.013],1,2);
for i = 1:4
    annotation('textbox',[annot_pos_x(i),annot_pos_y(i),annot_wid_x,annot_wid_y],...
        'String',char(64+i),'HorizontalAlignment','center',...
        'VerticalAlignment','middle','FontWeight','bold','FontSize',20,...
        'Fitboxtotext','off','BackgroundColor',[1,1,1]);
end 
fname2 = [fig_path,filesep,char(datetime('now','Format','yyyyMMdd')),'_SummaryQOLPreOpChange_AllSub.fig'];
savefig(fig2,fname2)
saveas(fig2,strrep(fname2,'fig','svg'))
end