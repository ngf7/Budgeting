

function assignCategory(Categories,MonthTransactions,m)
figure(1)
clf
f=figure(1);

% Get the table in string form.
MString = evalc('disp(MonthTransactions(m,:))');
% Use TeX Markup for bold formatting and underscores.
MString = strrep(MString,'<strong>','\bf');
MString = strrep(MString,'</strong>','\rm');
MString = strrep(MString,'_','\_');
% Get a fixed-width font.
FixedWidth = get(0,'FixedWidthFontName');
% Output the table using the annotation command.
annotation(gcf,'Textbox','String',MString,'Interpreter','Tex',...
    'FontName',FixedWidth,'FontSize',12,'Units','Normalized','Position',[0 0 1 1])
set(gcf,'Position',[186 549 1179 168]);




function selection(src,event)
        val = c.Value;
        str = c.String;
        %str{val}
        %str=Categories{val};
        %Category=str(val);
        MonthTransactions.Category(m)=str(val);
        MonthTransactions.IsCategorized(m) =1;
end

c=uicontrol(f,'Style','popupmenu');
c.Position = [50,50, 100, 22];
c.String = Categories;
c.Callback = @selection;
%src=get(c,'Value');
%selection;

    


end