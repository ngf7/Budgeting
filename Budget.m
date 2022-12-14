
clear all
close all

%% get the withdraws and deposits from excel spreadsheet 
M=readtable('/Users/noellefala/Downloads/accountActivityExport.xlsx');
load('savedInfo.mat');

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

if exist('RecurringPayments','var')==0

    Withdrawals = M.Withdrawals(~isnan(M.Withdrawals));
    [v, w] = unique( M.Withdrawals, 'stable' );
    duplicate_indices = setdiff( 1:numel(M.Withdrawals), w );
    recurring_transactions=M.Description(duplicate_indices);
    
    corrected_duplicates=[];
    for i=1:size(recurring_transactions,1)
        display(M(duplicate_indices(i),:))
        %display(recurring_transactions(i))
        %display(M.Withdrawals(duplicate_indices(i)))
    
        l=input('Is this a recurring transaction? 1/0: ');
        if l
            corrected_duplicates=[corrected_duplicates duplicate_indices(i)];
        end
    end
    
    RecurringPayments = M(corrected_duplicates,:);
    RecurringDates = day(RecurringPayments.Date);
end



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
            MonthTransactions.Category(i)={'Fixed'};

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
OpeningBalance=zeros(1,3);
for i = 1:size(ThisMonthPayDays,1)
    if ~isempty(M.Balance(find(M.Date == ThisMonthPayDays(i)-caldays(1),1,'first')))
        OpeningBalance(i) = M.Balance(find(M.Date == ThisMonthPayDays(i)-caldays(1),1,'first'));
    end
end

%% User defines non-fixed categories they would like to track
%%%% input categories that you would like to split expenses into
Categories = {'Danielle Debt','Groceries','Food and Take-out','Bars and Booze',...
    'Transporation','EZ Pass','Gas/Maintenance','Shopping','Pharmacy/Personal',...
    'Recreational','Laundry','Palmer','Misc','Fixed'};
TableCols={'Danielle Debt Total','Danielle Debt Used','Danielle Debt Remains',...
    'Groceries Total','Groceries Used','Groceries Remains','Food and Take-out Total',...
    'Food and Take-out Used','Food and Take-out Remains','Bars and Booze Total',...
    'Bars and Booze Used','Bars and Booze Remains','Transporation Total',...
    'Transporation Used','Transporation Remains','EZ Pass Total','EZ Pass Used',...
    'EZ Pass Remains','Gas/Maintenance Total','Gas/Maintenance Used',...
    'Gas/Maintenance Remains','Shopping Total','Shopping Used','Shopping Remains',...
    'Pharmacy/Personal Total','Pharmacy/Personal Used','Pharmacy/Personal Remains',...
    'Recreational Total','Recreational Used','Recreational Remains','Laundry Total',...
    'Laundry Used','Laundry Remains','Palmer Total','Palmer Used','Palmer Remains',...
    'Misc Total','Misc Used','Misc Remains'};


%% Assign transactions to non-fixed categories
%%%% assign each transaction to a category
%make this in a for loop for each pay check and have save something so you
%dont ahve to go through everthing each time if youve already assigned
%stuff 
%Category = categorizaion.assignCategory(Categories,MonthTransactions,m);


%some more things to add to this, only go through the withdrawals


%fig = uifigure;
AdditionalIncome = 0;

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
        if strcmp(category,'Fixed')
            MonthTransactions.IsRecurring(m)=1;
        end        
    elseif ~isnan(MonthTransactions.Deposits(m))
        if MonthTransactions.Deposits(m)==PayAmount 
            MonthTransactions.Category(m)={'Paycheck'};
            MonthTransactions.IsCategorized(m)=1;
        else
            MonthTransactions.Category(m)={'Additional Income'};
            MonthTransactions.IsCategorized(m)=1;
            %AdditionalIncome = AdditionalIncome + MonthTransactions.Deposits(m);
        end

    end
end

close all

%% Assign fixed charges to each paycheck 
NextMoPay1=FuturePayDays(find(month(FuturePayDays)==month(ThisMonthPayDays(1)+calmonths(1)),1,'first'));

for i=1:size(RecurringPayments,1)
    [~,idx]=min(abs(RecurringDates(i) - day(ThisMonthPayDays)));
    if RecurringDates(i)<day(ThisMonthPayDays(idx))
        AsscPay = idx-1;
        if AsscPay>length(ThisMonthPayDays)
            RecurringPayments.AssociatedPay(i)=NextMoPay1;
        end
        RecurringPayments.AssociatedPay(i) = ThisMonthPayDays(AsscPay);
    else
        AsscPay=idx;
        RecurringPayments.AssociatedPay(i) = ThisMonthPayDays(AsscPay);
    end
end

% if the first payment of the next month is after thefollowing cahrge, must
% assign another entry of it to the last paycehck of the current month 

for i=1:size(RecurringPayments,1)
    if day(NextMoPay1)>RecurringDates(i)
        AssocPay2=ThisMonthPayDays(end);
        RecurringPayments.AssociatedPay2(i)=AssocPay2;
    else
        RecurringPayments.AssociatedPay2(i)=NextMoPay1;
    end
    
end




%% Get total amount of fixed payments coming out of each paycheck 

  
for i = 1:size(ThisMonthPayDays,1)
    FixedTotal(i) =  sum(RecurringPayments.Withdrawals(RecurringPayments.AssociatedPay==ThisMonthPayDays(i)));
    FixedTotal(i)=FixedTotal(i)+sum(RecurringPayments.Withdrawals(RecurringPayments.AssociatedPay2==ThisMonthPayDays(i)));
end
FixedTotal = FixedTotal';

ExpensesByPaycheck=table(ThisMonthPayDays,FixedTotal);


%% Associated each MonthTransaction to a pay 

for i = 1:size(MonthTransactions,1)
    [~,idx]=min(abs(day(MonthTransactions.Date(i)) - day(ThisMonthPayDays)));
    if day(MonthTransactions.Date(i))<day(ThisMonthPayDays(idx))
        AsscPay = idx-1;
        MonthTransactions.AssociatedPay(i) = ThisMonthPayDays(AsscPay);
    else
        AsscPay=idx;
        MonthTransactions.AssociatedPay(i) = ThisMonthPayDays(AsscPay);
    end
end

%% get additional income per paycheck 
AdditionalIncome = zeros(1,3);
for i = 1:size(ThisMonthPayDays,1)
    AdditionalIncome(i)=sum(MonthTransactions.Deposits(strcmp(MonthTransactions.Category,'Additional Income') & MonthTransactions.AssociatedPay == ThisMonthPayDays(i)));
end


%% how much has already come out and how much remains to come out for fixed
UsedbyCat=[];
RemainsbyCat=[];

for i = 1:size(ThisMonthPayDays,1)
    ExpensesByPaycheck.FixedUsed(i) = sum(MonthTransactions.Withdrawals(strcmp(MonthTransactions.Category,'Fixed') & MonthTransactions.AssociatedPay == ThisMonthPayDays(i)));
    ExpensesByPaycheck.FixedRemains(i)= ExpensesByPaycheck.FixedTotal(i)-ExpensesByPaycheck.FixedUsed(i);
    UsedbyCat = vertcat(UsedbyCat,ExpensesByPaycheck.FixedUsed(i));
    RemainsbyCat= vertcat(RemainsbyCat,ExpensesByPaycheck.FixedRemains(i));

end

%% now user can give amount that they want to budget for each category of the month 
                 %Danielle Debt,Groceries,food & takeout, bars and booze,
                 % transportation,EZ pass,gas/maintainence, shopping, 
                 % pharmacy/personal,palmer, recreational,laundry,misc
%number of pays for this month 

%can make this a toggle tool so you can play around with how much you want
%to spend in each category 


% first make default settings for each category, then allow for interaction
% so that user can play with different scenarios
DefaultCatBudget = [50,50,100,30,10,10,50,25,25,25,10,10,10,0];
x =vertcat(DefaultCatBudget,DefaultCatBudget,DefaultCatBudget);
x(:,end)=[];

%now how much has been spent in each category already
for i = 1:size(ThisMonthPayDays,1)
    for c=1:length(Categories)-1
        Used = sum(MonthTransactions.Withdrawals(strcmp(MonthTransactions.Category,Categories{1,c}) & MonthTransactions.AssociatedPay == ThisMonthPayDays(i)));
        Remains = DefaultCatBudget(c)-Used;
        UsedbyCat(i,c+1) = Used;
        RemainsbyCat(i,c+1)= Remains;
    end
end

Total = [FixedTotal,x];

%first plot the fixed amount for each pay check and how much has been used
%in each category so far 

for i =1:size(ThisMonthPayDays)
    f=figure(i);clf
    f.Position= [260   529   950   295];
    hold on 
    b=bar(Total(i,:),'FaceColor',[.7 .7 .7]);
    
    pb = plot([b.XData;b.XData], [zeros(size(UsedbyCat(i,:))); UsedbyCat(i,:)],'Color','g','LineWidth', 20); 
    went_over = find(RemainsbyCat(i,:)<0);
    pbover=plot([b.XData(went_over);b.XData(went_over)], [zeros(size(UsedbyCat(i,went_over))); UsedbyCat(i,went_over)],'Color','r','LineWidth', 20); 
    xticks([1:14]);
    set(gca,'xticklabel',{'Fixed',Categories{1:end-1}})
    ylabel('Dollars')
    text(1:length(Total(i,:)),Total(i,:),num2str(Total(i,:)'),'vert','bottom','horiz','center');
    title(['Paycheck ' num2str(i)])
    %text(1:length(pb),UsedbyCat(i,:),num2str(UsedbyCat(i,:)'),'vert','bottom','horiz','center','Color','g');
    leftoverBud = (OpeningBalance(i)+PayAmount+AdditionalIncome(i))-sum(Total(i,:));
    leftoverSp = (OpeningBalance(i)+PayAmount+AdditionalIncome(i))-(Total(i,1)+sum(UsedbyCat(i,2:end)));
    
    dim = [.7 .5 .3 .3];
    str={['After Budgeted = $' num2str(leftoverBud)],['After Fixed + Spent = $' num2str(leftoverSp)]};
    annotation('textbox',dim,'String',str,'FitBoxToText','on')
end

        


% for i = 1:size(ThisMonthPayDays,1)
%     for c =1:length(RemainsbyCat)
%         BarInput(c,:)=[UsedbyCat(i,c),RemainsbyCat(i,c)];
%     end
%     figure(i);clf
%     %y = [UsedbyCat(i,:),RemainsbyCat(i,:);];
%     b=bar(BarInput,'stacked');
%     b(1).FaceColor=[.7 .7 .7];
%     b(2).FaceColor='g';
% 
% 
% end




%% saving stuff
save('savedInfo.mat','Categories','RecurringDates','RecurringPayments','MonthTransactions')


%% making a bar plot to show used and remains by category for each paycheck 

%plotting.

%user can input how much money they want to devote to each category, then

%user will assign each thing to a category and code will calculate how much
%is spent and remains 

% spent and remains feature of recurring bills