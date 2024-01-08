%% Plot QOL MVI Candidate
% Rerun script to generate REDCAP struct and load in the most recent MVI data
% As of 2024-01, we have run out of MATLAB markers. AA switched to letters and
% errorbars for this type of display
% Saves in the candidate's folder if one is found
function MVI_path = plotQOL_MVI_Candidate(MVI_path)
%% Reruns MVI all results
if nargin < 1 || isempty(MVI_path)
    MVI_path = [];
end
[~,all_results,scores,MVI_path] = processQOL(3,MVI_path);
temp = split(scores{1,2},' | ');
Rnum = temp{1};
Rdate = strrep(strrep(strrep(temp{end},'-',''),' ','-'),':','');
surveys = {'DHI Overall','VADL Overall','SF-36 Utility','HUI3 Overall'};
[~,surv_ind1] = ismember(surveys,all_results(1,:));
MVI_dat = cell2mat(all_results(strcmp(all_results(:,3),'0'),surv_ind1));
[~,surv_ind2] = ismember(surveys,scores(:,1));
Cand_dat = cell2mat(scores(surv_ind2,2))';
line_thick = 1.5;
submarksize = 8;
titles = {'DHI','VADL','SF36U','HUI3'};
XLim = [0.8 1.2];
YLim = [-10 110;0.1 10.9;0.23 0.97;-0.1 1.1];
fig = figure(1);
clf;
set(fig,'Color',[1,1,1],'Units','inches','Position',[1 1 5 5]);
h = gobjects(2,1);
ha = gobjects(1,4);
for i = 1:4
    ha(i) = subplot(1,4,i);
    hold on
    h(1) = errorbar(0.9,mean(MVI_dat(:,i)),std(MVI_dat(:,i)),'ko','LineWidth',line_thick,'MarkerSize',submarksize,'MarkerFaceColor','k');
    for j = 1:size(MVI_dat,1)
        text(0.95+0.15*rand(1,1),MVI_dat(j,i),char(64+j),'FontSize',9)
    end
    h(2) = plot(1.15,Cand_dat(i),'b*','MarkerSize',submarksize);
    hold off 
    title(ha(i),titles{i})
    axis([XLim,YLim(i,:)])
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
end
set(ha,'XTick',[],'XTickLabel',[])
set(ha(1:2),'YDir','reverse')
leg = legend(ha(1),h,{'MVI Mean±SD',[Rnum,' (',Rdate,')']},'NumColumns',length(h),'box','off');
leg.ItemTokenSize(1) = 7;
leg.Position = [0,0,0.99,0.1];
%Tries to save
cand_folder = [dir([strrep(MVI_path,'Study Subjects','Candidates'),filesep,strrep(Rnum,'R',''),' *']);...
    dir([strrep(MVI_path,'Study Subjects','Candidates'),filesep,strrep(Rnum,'R',''),',*'])];
if length(cand_folder)==1
    savefig(fig,[cand_folder.folder,filesep,cand_folder.name,filesep,Rnum,'-',Rdate,'-SurveyResponses.fig'])
    saveas(fig,[cand_folder.folder,filesep,cand_folder.name,filesep,Rnum,'-',Rdate,'-SurveyResponses.png'])
else %let the user save
    disp('Too many folders or no candidate folder found. Save manually with the following title:')
    disp([Rnum,'-',Rdate,'-SurveyResponses'])
end