%% QOL_DemographicStruct
% Takes in a scores table output by QOL.m and put into
% Questionnaires/REDCAP

function surveys = REDCAP_Demographics(scores)
surveys.scores = scores;
surveys.N = size(surveys.scores,1);
surveys.gender_Female = sum(contains(surveys.scores.Gender,'F'));
surveys.gender_Male = sum(contains(surveys.scores.Gender,'M'));
surveys.gender_Undisclosed = sum(contains(surveys.scores.Gender,'U'));
surveys.gender_Other = sum(~contains(surveys.scores.Gender,{'F','M','U'}));
surveys.ethnicity_Hispanic = sum(~contains(surveys.scores.Ethnicity,{'NH','U'}));
surveys.ethnicity_NotHispanic = sum(contains(surveys.scores.Ethnicity,'NH'));
surveys.ethnicity_Undisclosed = sum(contains(surveys.scores.Ethnicity,'U'));
surveys.race_White = sum(contains(surveys.scores.Race,'W'));
surveys.race_BlackAfricanAmerican= sum(contains(surveys.scores.Race,'B'));
surveys.race_Asian = sum(contains(surveys.scores.Race,'A'));
surveys.race_AmericanIndianAlaskaNative = sum(contains(surveys.scores.Race,'N'));
surveys.race_NativeHawaiianPacificIslander = sum(contains(surveys.scores.Race,'I'));
surveys.race_Undisclosed = sum(contains(surveys.scores.Race,'U'));
surveys.age_mean = mean(surveys.scores.Age,'omitnan');
surveys.age_sd = std(surveys.scores.Age,1,'omitnan');
surveys.age_min = min(surveys.scores.Age);
surveys.age_max = max(surveys.scores.Age);
surveys.age_Undisclosed = sum(isnan(surveys.scores.Age));

disp(['Number of participants: ',num2str(surveys.N)])
disp('Gender Breakdown: ')
disp(['   Female: ',num2str(100*surveys.gender_Female/surveys.N,3),'%'])
disp(['   Male: ',num2str(100*surveys.gender_Male/surveys.N,3),'%'])
disp(['   Undisclosed: ',num2str(100*surveys.gender_Undisclosed/surveys.N,2),'%'])
disp(['   Other: ',num2str(100*surveys.gender_Other/surveys.N,2),'%'])
disp('Ethnicity Breakdown: ')
disp(['   Hispanic: ',num2str(100*surveys.ethnicity_Hispanic/surveys.N,2),'%'])
disp(['   Non-Hispanic: ',num2str(100*surveys.ethnicity_NotHispanic/surveys.N,3),'%'])
disp(['   Undisclosed: ',num2str(100*surveys.ethnicity_Undisclosed/surveys.N,2),'%'])
disp('Race Breakdown (may add to >100%): ')
disp(['   White: ',num2str(100*surveys.race_White/surveys.N,3),'%'])
disp(['   Black or African-American: ',num2str(100*surveys.race_BlackAfricanAmerican/surveys.N,2),'%'])
disp(['   Asian: ',num2str(100*surveys.race_Asian/surveys.N,2),'%'])
disp(['   American Indian or Alaska Native: ',num2str(100*surveys.race_AmericanIndianAlaskaNative/surveys.N,2),'%'])
disp(['   Native Hawaiian or Pacific Islander: ',num2str(100*surveys.race_NativeHawaiianPacificIslander /surveys.N,2),'%'])
disp(['   Undisclosed: ',num2str(100*surveys.race_Undisclosed/surveys.N,2),'%'])
disp('Age (yrs) Breakdown: ')
disp(['   Mean (SD): ',num2str(surveys.age_mean,3),' (',num2str(surveys.age_sd,3),')'])
disp(['   Range: ',num2str(surveys.age_min),'-',num2str(surveys.age_max)])
disp(['   Undisclosed: ',num2str(100*surveys.age_Undisclosed/surveys.N,2),'%'])
disp(newline)
end