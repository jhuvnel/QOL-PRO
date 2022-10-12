function [score_labs,all_scores,res] = scoreAllSurveys(surv,sub_row,surveys)
surv = fixSF6DNumIssue(surv); %Found issue with qualtrics numbering of SF-6D
all_subscores = cell(length(surveys),1);
all_values = cell(length(surveys),1);
for i = 1:length(surveys)
    scores = parseQualtricsResponses(surveys{i},i+1,surv,sub_row); %The i+1 is the section number of the survey in the document
    [subscores,values] = scoreSurvey(scores,surveys{i});
    all_subscores(i) = {subscores};
    all_values(i) = {values};
    res.(surveys{i}) = scores;
end
score_labs = vertcat(all_subscores{:});
all_scores = num2cell(vertcat(all_values{:}));
end
%% ParseQualtricsResponses
%Turn numeric responses from the Excel output of the Qualtrics into the
%letters/numbers expected of a paper response
function scores = parseQualtricsResponses(survey,num,surv,sub_row)
    Qnum = ['Q',num2str(num),'_',]; 
    labs = surv.Properties.VariableNames;
    switch survey
        case {'ABC','SF36','SF6D'}
            scores = table2cell(surv(sub_row,contains(labs,Qnum)))';
        case {'AI','VSS'}
            Qs = surv{sub_row,contains(labs,Qnum)}';
            if iscell(Qs)
                scores = cellfun(@str2double,Qs)-1;
            else
                scores = Qs-1;
            end
        case {'DHI','THI'}
            Qs = surv{sub_row,contains(labs,Qnum)}';
            if iscell(Qs)
                vec = cellfun(@str2double,Qs);
            else
                vec = Qs;
            end
            scores = cell(length(vec),1);
            scores(vec==1) = {'y'};
            scores(vec==2) = {'s'};
            scores(vec==3) = {'n'};    
        case 'EQ5D'
            scores = table2cell(surv(sub_row,contains(labs,Qnum)))';
            scores(cellfun(@ischar,scores)) = cellfun(@str2num,scores(cellfun(@ischar,scores)),'UniformOutput',false);
        case 'HUI3'
            Qs = surv{sub_row,contains(labs,Qnum)}';
            if iscell(Qs)
                vec = cellfun(@str2double,Qs);
            else
                vec = Qs;
            end
            scores = cell(length(vec),1);
            scores(vec==1) = {'a'};
            scores(vec==2) = {'b'};
            scores(vec==3) = {'c'};
            scores(vec==4) = {'d'};
            scores(vec==5) = {'e'};
            scores(vec==6) = {'f'};
        case 'NHIS'
            vec = NaN(8,1);
            scores = cell(length(vec),1);
            % May not be section 12 but the .# is still true
            % 1=12.2, 2=12.5 (19), 3=12.5 (5), 4=12.5 (6)
            % 5=12.5 (8) ambiguously also 18 but standardizing on 8
            % 6=12.5 (3), 7=12.4 (keep likert), 8=12.8 (y = response >2)
            NHIS_list = cellfun(@str2double,strsplit(surv{sub_row,contains(labs,[Qnum,'5'])}{:},','));
            vec(1,1) = surv{sub_row,contains(labs,[Qnum,'2'])}-1;
            if ~isnan(NHIS_list)    
                vec(2:6,1) = ismember([19,5,6,8,3],NHIS_list)';
            else
                vec(2:6,1) = 0; %NOT TRUE but a placeholder
            end
            vec(8,1) = surv{sub_row,contains(labs,[Qnum,'8'])}>2;
            scores(vec==0) = {'n'};
            scores(vec==1) = {'y'};
            scores{7,1} = surv{sub_row,contains(labs,[Qnum,'4'])};
        case 'VADL'
            Qs = surv{sub_row,contains(labs,Qnum)}';
            if iscell(Qs)                
                vec = cellfun(@str2double,Qs);
            else
                vec = Qs;
            end
            vec(vec == 12) = 0; %NaN case
            scores = vec;
        case {'VAS','OVAS'}
            Qs = surv{sub_row,contains(labs,Qnum)}';
            if iscell(Qs)
                vec = cellfun(@str2double,Qs);
            else
                vec = Qs;
            end
            vec(isnan(vec)) = 11; %NaN case
            scores = num2cell(vec);
        otherwise
            scores = [];
    end
    if isnumeric(scores)
        scores = num2cell(scores);
    end
end
%% Fix issue with the numbering of the SF-6D
%On 2022-01-26, AA discovered a recoding issue with the SF6D that was
%preventing proper analysis. Surveys completed before 2022-01-25 were not
%correctly encoded so that selecting the second option returned the number
%2. This function takes in a loaded table and fixes that issue for the
%effected surveys.
%On 2022-02-25, AA realized that she still hadn't fixed the issue with the
%recoding on the Qualtrics end, so she updated the survey end date that 
% this applied to.
function surv = fixSF6DNumIssue(surv)
    rows = surv.EndDate > datetime(2021,11,01) & surv.EndDate < datetime(2022,02,24);
    old_Q3_2 = surv.Q3_2;
    old_Q3_3 = surv.Q3_3;
    old_Q3_5 = surv.Q3_5;
    surv.Q3_2(rows&contains(old_Q3_2,'7')) = {'2'};
    surv.Q3_2(rows&contains(old_Q3_2,'8')) = {'3'};
    surv.Q3_2(rows&contains(old_Q3_2,'2')) = {'4'};
    surv.Q3_3(rows&contains(old_Q3_3,'6')) = {'2'};
    surv.Q3_3(rows&contains(old_Q3_3,'7')) = {'3'};
    surv.Q3_3(rows&contains(old_Q3_3,'2')) = {'4'};
    surv.Q3_3(rows&contains(old_Q3_3,'3')) = {'5'};
    surv.Q3_5(rows&contains(old_Q3_5,'6')) = {'2'};
    surv.Q3_5(rows&contains(old_Q3_5,'2')) = {'3'};
end