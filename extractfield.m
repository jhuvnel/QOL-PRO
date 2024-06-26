function val = extractfield(struct,field,inds)
    if nargin < 3
        inds = 1:length(struct);
    end
    %Return everything in the field of a struct
    try
        test = struct.(field);
        if isnumeric(test)||islogical(test)||isdatetime(test)||isduration(test)
            val = [struct.(field)]';
        else
            val = {struct.(field)}';
        end
        val = val(inds);
    catch
        val = [];
    end
end