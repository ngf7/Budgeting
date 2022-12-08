%%%% get the withdraws and deposits from excel spreadsheet 
M=readtable('/Users/noellefala/Downloads/accountActivityExport.xlsx');

%%%% find date of paycheck in the excel file (find based on string)
PayDays=M.Date(find(strcmp('Paychecks',M.Category)));
Dur=[];
for i = 1:size(PayDays,1)-1
    Days = [PayDays(end),PayDays(end-i)];
    Dur=vertcat(Dur,caldiff(Days));
end

%%%% predict future paychecks for this month dates based on frequency
FuturePayDays = PayDays(1)+Dur;
PayDays = vertcat(flip(PayDays),FuturePayDays);
ThisMonthPayDays = PayDays(find(month(PayDays)==month(today)));



%%%% save amount of paycheck to variable
PayAmount = M.Deposits(find(M.Date == PayDays(1)));
PayAmount = PayAmount(~isnan(M.Deposits(find(M.Date == PayDays(1)))));


%%%% find all the recurring expense
Withdrawals = M.Withdrawals(~isnan(M.Withdrawals));
[v, w] = unique( M.Withdrawals, 'stable' );
duplicate_indices = setdiff( 1:numel(M.Withdrawals), w );
recurring_transactions=M.Description(duplicate_indices);

%%%% user can decide which transactions are actually recurring
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
%RecurringAmounts=
%RecurringOccurred=
%RecurringRemains

start = ThisMonthPayDays(1);
last = datetime('now');
t = start:last;
[~,idx]=ismember(M.Date,t);
index = find(idx);
MonthTransactions = M(index,:);

%for some transactions like Geico is string isnt completely identical so
%could set some threshold for the number of characters in the string that
%must be the same before we can decide that theyre the same 
for i = 1:size(MonthTransactions)
    str=MonthTransactions.Description(i);
    for recs=1:size(RecurringPayments,1)
        [~,dist,~]=categorization.LCS(RecurringPayments.Description(rec),str{1,1});
        if abs(dist-str{1,1})<5 && RecurringPayments.Withdrawals(rec)==MonthTransactions.Withdrawals(i)

            MonthTransactions.IsRecurring=1;

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






%%%% make the balance in bank on the day before the paycheck the opening
% balance
OpeningBalance=[];
for i = 1:size(ThisMonthPayDays,1)
    OpeningBalance = [OpeningBalance M.Balance(find(M.Date == ThisMonthPayDays(i)-caldays(1),1,'first'))];
end

%%%% input categories that you would like to split expenses into
Categories = {'Danielle Debt','Groceries','Food and Take-out','Bars and Booze',...
    'Transporation','EZ Pass','Gas/Maintenance','Shopping','Pharmacy/Personal',...
    'Recreational','Laundry','Palmer','Misc'};



%%%% assign each transaction to a category
%make this in a for loop for each pay check and have save something so you
%dont ahve to go through everthing each time if youve already assigned
%stuff 
Category = categorizaion.assignCategory(Categories,MonthTransactions,m);

fig = uifigure;

for m = 1:size(MonthTransactions,1)
    if MonthTransactions(m).IsRecurring~=1 && MonthTransactions.IsCategorized(m)~=1
        S = assignCategory_gui(Categories,MonthTransactions,m,fig);
        choice=get(S.ls,{'string','value'}); %get users choice
        category = choice{1}(choice{2});
        MonthTransactions.Category(m)=Category;
        MonthTransactions.IsCategorized(m) =1;
    end
end


    


%%%% Make a table with all paychecks and categories


%user can input how much money they want to devote to each category, then

%user will assign each thing to a category and code will calculate how much
%is spent and remains 

% spent and remains feature of recurring bills