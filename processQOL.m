%% processQOL
%Processes the Excel file output from Qualtrics and provides user options
%for what to do.
%Assumes all the numeric responses were downloaded in accordance to the
%SOP on the MVI server under MVI/SOP
%No matter which option is selected, the .mat and .xlsx file with pooled
%REDCAP data will be saved in the respective folders.
%Opt 1 = just remake the REDCAP and MVI pooled .mat and .xlsx
%Opt 2 = add column to an MVI .xlsx file, AND remake MVI struct
%Opt 3 = return the scores for one instance of the survey being filled out
%(a quick score option) and load REDCAP/MVI files
%Outputs the REDCAP struct, pooled MVI data and one set of scores for opts
%2/3

function [REDCAP,all_results,scores,MVI_path] = processQOL(opt,MVI_path)
%% Figure out which version to run
opts = {'Remake REDCAP and MVI Summary Data','Add One Survey to MVI Excel File','Score One Survey'};
if nargin < 1
    [ind1,tf] = listdlg('PromptString','Select surveys to score.','ListString',opts,'SelectionMode','single','ListSize',[200 300]);
    if ~tf
        error('No process selected.')
    end
    opt = ind1;
end
if ~isnumeric(opt)||~ismember(opt,1:length(opts)) %Invalid input
    opt = 1; %Default option, happens regardless
end
if nargin < 2 || isempty(MVI_path)
    % Find the directory of IN PROGRESS/Questionnaires
    prompt = 'Select the MVI Study subject root folder.';
    MVI_path = uigetdir(prompt,prompt);
    if ~contains(MVI_path,'MVI')
        disp(['The selected path does not contain the text "MVI", so it may be wrong: ',MVI_path])
    end
end
%% Load in Qualtrics Excel File
surveys = {'HUI3','SF6D','SF36','EQ5D','DHI','VADL','ABC','VSS','VAS',...
    'OVAS','BVQ','THI','AI','NHIS'}; %Add as needed
% Load the raw, numeric survey data
Qualtrics_path = [MVI_path,filesep,'Qualtrics'];
files = dir(Qualtrics_path);
files([files.isdir]) = [];
files(~contains({files.name},'.xlsx')|~contains({files.name},'Questionnaires')) = [];
[~,t_ind] = sort(datetime({files.date}));
in_path = [Qualtrics_path,filesep,files(t_ind(end)).name];
%Load surveys
warning('off')
surv = readtable(in_path);
warning('on')
%REMOVE INCOMPLETE SURVEYS
surv(~surv.Finished,:) = [];
if isdatetime(surv.EndDate(1))
    identity = strcat(surv.Q1_2,{' | '},surv.Q1_3,{' | '},datestr(surv.EndDate));
else
    identity = strcat(surv.Q1_2,{' | '},surv.Q1_3,{' | '},surv.EndDate);
end
subs = surv.Q1_2;
%% Run the options for this script
if opt == 1
    %% Save files with REDCAP Candidates who are NOT yet in the MVI trial
    is_cand = find(cellfun(@(x) x(1),subs)=='R'&surv.Finished==1&~contains(subs,{'R141'})); %Is a candidate
    sub_labs = cell(length(is_cand),6);
    score_mat = NaN(length(is_cand),51); %change when surveys change
    for i = 1:length(is_cand)
        h = is_cand(i);
        %Get the date and other characteristics
        date = {datestr(surv.EndDate(h),'dd-mmm-yyyy')};
        age = {str2num(surv.Q1_4_2{h})};
        if isempty(surv.Q1_4_2{h})
            age = NaN;
        end
        if isempty(surv.Q1_4_3{h})
            gender = {'U'};
        else
            gender = {upper(surv.Q1_4_3{h}(1))};
        end
        if isempty(surv.Q1_6(h))
            eth = {'U'};
        elseif surv.Q1_6(h)==1
            eth = {'NH'};
        else
            eth = {'H'};
        end
        race = strrep(strrep(strrep(strrep(strrep(surv.Q1_7(h),'1','W'),'2','B'),'3','A'),'4','N'),'5','I');
        if isempty(race{:})
            race = {'U'};
        end
        [score_labs1,scores] = scoreAllSurveys(surv,h,surveys);
        score_mat(i,:) = cell2mat(scores)';
        sub_labs(i,:) = [subs(h),age,gender,eth,race,date];
    end
    score_labs = [{'Subject','Age','Gender','Ethnicity','Race','Date'},strrep(strrep(strrep(score_labs1',' ','_'),'-',''),'/','')];
    scores = [cell2table(sub_labs),array2table(score_mat)];
    scores.Properties.VariableNames = score_labs;
    % Write Scores to Excel
    fname = 'REDCAPCandidateScores';
    writetable(scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','ByDate');
    REDCAP.ByDate = scores;
    scores = sortrows(scores,'Subject','ascend');
    writetable(scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','BySubject');
    REDCAP.BySubject = scores;
    % Write Scores to Mat Files
    scores.Date = datetime(scores.Date);
    %Write table with unique subjects only (if repeat measurements, take the
    %most recent on)
    %Fill in missing demographics
    %Age
    missing = find(isnan(scores.Age));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~isnan(scores.Age(contains(scores.Subject,sub))))
            temp = scores.Age(contains(scores.Subject,sub));
            temp(isnan(temp)) = [];
            scores.Age(missing(i)) = temp(1);
        end
    end
    %Gender
    missing = find(contains(scores.Gender,'U'));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~contains(scores.Gender(contains(scores.Subject,sub)),'U'))
            temp = scores.Gender(contains(scores.Subject,sub));
            temp(contains(temp,'U')) = [];
            scores.Gender(missing(i)) = temp(1);
        end
    end
    %Hispanic v/ non-Hispanic ethnicity
    missing = find(contains(scores.Ethnicity,'U'));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~contains(scores.Ethnicity(contains(scores.Subject,sub)),'U'))
            temp = scores.Ethnicity(contains(scores.Subject,sub));
            temp(contains(temp,'U')) = [];
            scores.Ethnicity(missing(i)) = temp(1);
        end
    end
    %Race
    missing = find(contains(scores.Race,'U'));
    for i = 1:length(missing)
        sub = scores.Subject(missing(i));
        if any(~contains(scores.Race(contains(scores.Subject,sub)),'U'))
            temp = scores.Race(contains(scores.Subject,sub));
            temp(contains(temp,'U')) = [];
            scores.Race(missing(i)) = temp(1);
        end
    end
    % Too many surveys per subject
    unique_subs = unique(scores.Subject);
    %If a subject fills out the survey twice in the same week, use the later one
    for i = 1:length(unique_subs)
        sub_i = find(contains(scores.Subject,unique_subs(i)));
        dates = scores.Date(sub_i);
        if length(dates)>1 && any(days(diff(dates))<7)
            scores(sub_i([days(diff(dates))<7;false]),:) = [];
        end
    end
    [~,ind_uniq] = unique(scores.Subject);
    uniq_scores = scores(ind_uniq,:);
    %Now make the table with subjects scores before and after, assumming 1 or 2
    %surveys per person
    rep_scores = scores;
    rep_scores.SurvNum = NaN(size(scores,1),1);
    for i = 1:length(unique_subs)
        sub_i = find(strcmp(rep_scores.Subject,unique_subs(i)));
        rep_scores.SurvNum(sub_i) = 1:length(sub_i);
        if(length(sub_i)) == 1
            rep_scores.SurvNum(sub_i) = NaN;
        end
    end
    rep_scores(rep_scores.SurvNum > 2,:) = [];
    rep_scores(isnan(rep_scores.SurvNum),:) = [];
    date_diff = days(rep_scores.Date(2:2:end) - rep_scores.Date(1:2:end))/30;
    month_range = 2; %the maximum range for deviation from the 6month target
    rep_scores(reshape(repmat(abs(date_diff'-6) > month_range,2,1),[],1),:) = [];
    REDCAP.unique = uniq_scores;
    REDCAP.repeated = rep_scores;
    writetable(uniq_scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','unique');
    writetable(rep_scores,[Qualtrics_path,filesep,fname,'.xlsx'],'FileType','spreadsheet','WriteVariableNames',true,'Sheet','repeated');
    save([Qualtrics_path,filesep,fname,'.mat'],'REDCAP')
    REDCAP_Demographics(REDCAP.BySubject);
    % Make a new pooled MVI subject file
    MVIdirnames = dir(MVI_path);
    MVIdirnames(~[MVIdirnames.isdir]) = [];
    MVIdirnames(~contains({MVIdirnames.name},'MVI')|~contains({MVIdirnames.name},'_R')) = [];
    MVIdirnames = {MVIdirnames.name}';
    MVI_fnames = strcat({[MVI_path,filesep]},MVIdirnames,{filesep},strrep(MVIdirnames,'_',''),{'_SurveyResponses.xlsx'});
    subjects = strrep(MVIdirnames,'_','');
    all_results = cell(length(MVI_fnames),1);
    %Assumes they all have the same score order
    for i = 1:length(MVI_fnames)
        if isfile(MVI_fnames{i})
            try %Fails on mac for some reason
                [~,~,scores2] = xlsread(MVI_fnames{i},'Scores');
            catch %Reads the first sheet as the right sheet, thankfully
                [~,~,scores2] = xlsread(MVI_fnames{i});
            end
            all_results{i} = [repmat(subjects(i),1,size(scores2,2)-1);scores2(:,2:end)]';
        end
    end
    %Trim off the excess
    all_results = [[{'Subject'},scores2(:,1)'];vertcat(all_results{:})];
    all_results(cellfun(@isnumeric,all_results(:,3)),3) = {''}; %Replace NaN with empty cell for visit name
    save([MVI_path,filesep','ALLMVI-SurveyResults.mat'],'all_results')
    writecell(all_results,[MVI_path,filesep','ALLMVI-SurveyResults.xlsx'])
    scores = []; %Not used because it represents scores for the one person requested
elseif opt == 2 
    %% Add to MVI Excel document
    %Select which row to score
    [sub_indx,tf] = listdlg('PromptString','Select surveys to score.','ListString',identity(end:-1:1),'SelectionMode','single','ListSize',[200 300]);
    if tf==0
        error('No surveys selected. Try again.')
    end
    sub_row = size(surv,1)+1-sub_indx;
    sub_name = surv.Q1_2{sub_row};
    %Select the file to put it into
    MVIdirnames = dir(MVI_path);
    MVIdirnames(~[MVIdirnames.isdir]) = [];
    MVIdirnames(~contains({MVIdirnames.name},'MVI')|~contains({MVIdirnames.name},'_R')) = [];
    MVIdirnames = {MVIdirnames.name}';
    MVI_fnames = strcat({[MVI_path,filesep]},MVIdirnames,{filesep},strrep(MVIdirnames,'_',''),{'_SurveyResponses.xlsx'});
    rel_file = MVI_fnames(contains(MVI_fnames,sub_name));
    if length(rel_file)==1&&isfile(rel_file) %Unique file exists as expected
        out_path = rel_file{:};
    elseif length(rel_file)==1 %MVI directory made but no file exists yet
        disp('MVI directory for this subject has been made but no file exists yet. Creating .xlsx file.')
        out_path = rel_file{:};
        writetable(table(),out_path);
    elseif length(rel_file)>1
        error(['More than one directory found for the subject name: ',sub_name,'. Unclear which file to add scores to.'])
    elseif isempty(rel_file)
        error(['No directories found for the subject name: ',sub_name,'. Create one in the MVI***R*** format and retry.'])
    end
    % Properly format the visit name
    %Get the right visit name
    visit = surv.Q1_3{sub_row};
    if isnumeric(visit)
        visit = num2str(visit);
    end
    %Remove the text so it can be standardized
    if contains(visit,'Visit')
        visit = strrep(strrep(visit,'Visit',''),' ','');
    elseif contains(visit,'visit')
        visit = strrep(strrep(visit,'visit',''),' ','');
    end
    val_vis = questdlg({'Does this visit name below look right? This will be the Excel column label.',visit},'','Yes','No','Yes');
    if ~strcmp(val_vis,'Yes')
        visit = inputdlg('Enter the correct visit name');
        visit = visit{:};
    end
    % Score
    [score_labs,scores,res] = scoreAllSurveys(surv,sub_row,surveys);
    % Figure out what column to put the responses in
    %Works for Excel columns A - ZZ
    Alphabet = num2cell('ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    col_names = [Alphabet,strcat(reshape(repmat(Alphabet,26,1),[],1)',repmat(Alphabet,1,26))];
    %Find where the visit should go
    [~,~,dates] = xlsread(out_path);
    %Get the date
    date = {datestr(surv.EndDate(sub_row),'dd-mmm-yyyy')};
    if isempty(dates) %Empty sheet
        col = 'B';
    else
        dates = dates(1,:);
        [~,b] = ismember(dates,date);
        if any(b) %already a column label
            col_num = find(b);
        else %add to the end
            col_num = length(b)+1;
        end
        col = col_names{col_num};
    end
    %Make labels for column 1
    col_labs = [{'Date';'Visit'};strcat('Q',cellfun(@num2str,num2cell(1:100),'UniformOutput',false))'];
    % Write to MVI Excel file
    %Write Column 1 labels
    writetable(cell2table([{'Date'};{'Visit'};score_labs]),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet','Scores','Range',['A1:A',num2str(length(scores)+2)]);
    %Write new results
    writetable(cell2table([date;{visit};scores]),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet','Scores','Range',[col,'1:',col,num2str(length(scores)+2)]);
    disp(identity(sub_row))
    disp([[{'Date'};{'Visit'};score_labs],[date;{visit};scores]])
    %Individual Responses
    for i = 1:length(surveys)
        test = res.(strrep(surveys{i},'-',''));
        %Write Column 1 labels
        writetable(cell2table(col_labs(1:length(test)+2)),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet',surveys{i},'Range',['A1:A',num2str(length(test)+2)]);
        %Write new results
        writetable(cell2table([date;{visit};test]),out_path,'FileType','spreadsheet','WriteVariableNames',false,'Sheet',surveys{i},'Range',[col,'1:',col,num2str(length(test)+2)]);
    end
    % Make a new pooled MVI subject file
    subjects = strrep(MVIdirnames,'_','');
    all_results = cell(length(MVI_fnames),1);
    %Assumes they all have the same score order
    for i = 1:length(MVI_fnames)
        if isfile(MVI_fnames{i})
            try %Fails on mac for some reason
                [~,~,scores2] = xlsread(MVI_fnames{i},'Scores');
            catch %Reads the first sheet as the right sheet, thankfully
                [~,~,scores2] = xlsread(MVI_fnames{i});
            end
            all_results{i} = [repmat(subjects(i),1,size(scores2,2)-1);scores2(:,2:end)]';
        end
    end
    %Trim off the excess
    all_results = [[{'Subject'},scores2(:,1)'];vertcat(all_results{:})];
    all_results(cellfun(@isnumeric,all_results(:,3)),3) = {''}; %Replace NaN with empty cell for visit name
    save([MVI_path,filesep','ALLMVI-SurveyResults.mat'],'all_results')
    writecell(all_results,[MVI_path,filesep','ALLMVI-SurveyResults.xlsx'])
    % Load REDCAP most recent file
    try
        load([Qualtrics_path,filesep,'REDCAPCandidateScores.mat'],'REDCAP')
    catch
        REDCAP = [];
    end
elseif opt==3 
    %% Score one survey instance
    %Select which row to score
    [indx,tf] = listdlg('PromptString','Select surveys to score.','ListString',identity(end:-1:1),...
        'SelectionMode','single','ListSize',[200 300]);
    if tf==0
        error('No surveys selected. Try again.')
    end
    sub_row = size(surv,1) + 1 - indx;
    [score_labs,all_scores] = scoreAllSurveys(surv,sub_row,surveys);
    scores = [{'Subject',identity{sub_row}};score_labs,all_scores];
    disp(scores)
    % Load REDCAP most recent file
    try
        load([Qualtrics_path,filesep,'REDCAPCandidateScores.mat'],'REDCAP')
    catch
        REDCAP = [];
    end
    % Load MVI most recent all_results file
    try
        load([MVI_path,filesep','ALLMVI-SurveyResults.mat'],'all_results')
    catch
        all_results = [];
    end
end
disp('Done!')
end