function L = assignCategory_gui(Categories,S)

% uit = uitable(fig,'Data',MonthTransactions(m,:));
% fig.Position=[186 510 1031 207];



S.ls=uicontrol(S.fh,'Style','listbox','unit','pix',...
                 'position',[10 60 180 180],...
                 'min',0,'max',2,'string',Categories);
S.pb = uicontrol(S.fh,'style','push',...
                 'units','pix',...
                 'position',[10 10 180 40],...
                 'fontsize',14,...
                 'string','Set Category',...
                 'callback',{@pb_call,S});
L=S;
%c.Callback = @selection;
uiwait(S.fh)


    function L=pb_call(varargin)
        L = varargin{3};  % Get the structure.
        uiresume(L.fh)
%         L = get(S.ls,{'string','value'});  % Get the users choice.
%         
%         % We need to make sure we don't try to assign an empty string.
%         if ~isempty(L{1})
%             L{1}(L{2}(:)) = [];  % Delete the selected strings.
%             set(S.ls,'string',L{1},'val',1) % Set the new string.
%         end
%         S=varargin{3};
%         choice=get(S.ls,{'string','value'}); %get users choice
%         category = choice{1}(choice{2});
        %MonthTransactions.Category(m)=choice{1}(choice{2});
        %MonthTransactions.IsCategorized(m) =1;

