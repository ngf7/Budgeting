%% get the withdraws and deposits from excel spreadsheet 
M=readtable('/Users/noellefala/Downloads/accountActivityExport.xlsx');

%% find date of paycheck in the excel file (find based on string)
PastPayDays=M.Date(find(strcmp('Paychecks',M.Category)));
Dur=[];
for i = 1:size(PastPayDays,1)-1
    Days = [PastPayDays(end),PastPayDays(end-i)];
    Dur=vertcat(Dur,caldiff(Days));
end

%% predict future paychecks for this month dates based on frequency
FuturePayDays = PastPayDays(1)+Dur;
PastPayDays = vertcat(flip(PastPayDays),FuturePayDays);
ThisMonthPayDays = PastPayDays(find(month(PastPayDays)==month(today)));



%% save amount of paycheck to variable
PayAmount = M.Deposits(find(M.Date == PastPayDays(1)));
PayAmount = PayAmount(~isnan(M.Deposits(find(M.Date == PastPayDays(1)))));


%% find all the recurring expense
Withdrawals = M.Withdrawals(~isnan(M.Withdrawals));
[v, w] = unique( M.Withdrawals, 'stable' );
duplicate_indices = setdiff( 1:numel(M.Withdrawals), w );
recurring_transactions=M.Description(duplicate_indices);

%% user can decide which types of transactions are actually recurring
corrected_duplicates=[];
for i=1:size(recurring_transactions,1)
    display(M(duplicate_indices(i),:))
    %display(recurring_transactions(i))
    %display(M.Withdrawals(duplicate_indices(i)))

    l=input('Is this a recurring transaction? 1/0');
    if l
        corrected_duplicates=[corrected_duplicates duplicate_indices(i)];
    end
end

RecurringPayments = M(corrected_duplicates,:);
RecurringDates = day(RecurringPayments.Date);


%% subsample from all transactions only those which have occurred this month (or maybe change to from first paycheck of month)
start = ThisMonthPayDays(1);
last = datetime('now');
t = start:last;
[~,idx]=ismember(M.Date,t);
index = find(idx);
MonthTransactions = M(index,:);

%% categorize a transaction as recurring 
%bug for one specific trasnaction - medium membership for some reason this
%month is called somethign very disimilar to the previous months, cmaybe
%could code some fail safe lilike add a fixed category to teh next section
%that way it can get appropriately added in 
for i = 1:size(MonthTransactions)
    str=MonthTransactions.Description(i);
    for rec=1:size(RecurringPayments,1)
        rstr=RecurringPayments.Description(rec);
        [~,dist,~]=categorization.LCS(rstr{1,1},str{1,1});
        if abs(dist-length(str{1,1}))<5 && RecurringPayments.Withdrawals(rec)==MonthTransactions.Withdrawals(i)

            MonthTransactions.IsRecurring(i)=1;
            MonthTransactions.IsCategorized(i)=1;

        end
    end

    %if any(strcmp(RecurringPayments.Description,str{1,1}))
     %   x=strfind(RecurringPayments.Description,str{1,1});
      %  loc=find(~cellfun(@isempty,x));
       % if RecurringPayments.Withdrawals(loc)==MonthTransactions.Withdrawals(i)
        %    MonthTransactions.IsRecurring = 1;
        %end
    
   % end
end





%% Opening balance before each paycheck
%%%% make the balance in bank on the day before the paycheck the opening
% balance
OpeningBalance=[];
for i = 1:size(ThisMonthPayDays,1)
    OpeningBalance = [OpeningBalance M.Balance(find(M.Date == ThisMonthPayDays(i)-caldays(1),1,'first'))];
end

%% User defines non-fixed categories they would like to track
%%%% input categories that you would like to split expenses into
Categories = {'Danielle Debt','Groceries','Food and Take-out','Bars and Booze',...
    'Transporation','EZ Pass','Gas/Maintenance','Shopping','Pharmacy/Personal',...
    'Recreational','Laundry','Palmer','Misc','Fixed'};


%% Assign transactions to non-fixed categories
%%%% assign each transaction to a category
%make this in a for loop for each pay check and have save something so you
%dont ahve to go through everthing each time if youve already assigned
%stuff 
%Category = categorizaion.assignCategory(Categories,MonthTransactions,m);


%some more things to add to this, only go through the withdrawals


%fig = uifigure;
figure(1)

S.fh = figure('units','pixels',...
              'position',[500 500 200 260],...
              'menubar','none',...
              'name','GUI_1',...
              'numbertitle','off',...
              'resize','off');

for m = 1:size(MonthTransactions,1)
    if MonthTransactions.IsRecurring(m)~=1 && MonthTransactions.IsCategorized(m)~=1 && isnan(MonthTransactions.Deposits(m))
        figure(1);clf;
        f=figure(1);
                % Get the table in string form.
        MString = evalc('disp(MonthTransactions(m,1:4))');
        % Use TeX Markup for bold formatting and underscores.
        MString = strrep(MString,'<strong>','\bf');
        MString = strrep(MString,'</strong>','\rm');
        MString = strrep(MString,'_','\_');
        % Get a fixed-width font.
        FixedWidth = get(0,'FixedWidthFontName');
        % Output the table using the annotation command.
        annotation(gcf,'Textbox','String',MString,'Interpreter','Tex',...
            'FontName',FixedWidth,'FontSize',12,'Units','Normalized','Position',[0 0 1 1])
        set(gcf,'Position',[183 592 1068 97]);
  
        L = categorization.assignCategory_gui(Categories,S);
        choice=get(L.ls,{'string','value'}); %get users choice
        category = choice{1}(choice{2});
        MonthTransactions.Category(m)=category;
        MonthTransactions.IsCategorized(m) =1;
    end
end
    

%%
%%%% Make a table with all paychecks and categories


%user can input how much money they want to devote to each category, then

%user will assign each thing to a category and code will calculate how much
%is spent and remains 

% spent and remains feature of recurring bills