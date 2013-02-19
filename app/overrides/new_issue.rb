Deface::Override.new(:virtual_path => "issues/new", 
                     :name => "rewrite_checkboxes", 
                     :replace => "p#watchers_form", 
                     :text => <<-EOS

<p id="watchers_form">
  <label><%= l(:label_issue_watchers) %></label>
  <span id="watchers_inputs">
    <%= watchers_checkboxes(@issue, @available_watchers) %>
  </span>
</p>
<p id="group_watchers_form">
  <label><%= l(:label_issue_group_watchers) %></label>
  <span id="group_watchers_inputs">
    <%= watchers_checkboxes(@issue, Group.sorted.all - @issue.group_watchers.all) %>
  </span>
  <br />
  <span class="search_for_watchers">
    <%= link_to l(:label_search_for_watchers),
                {:controller => 'watchers', :action => 'new', :project_id => @issue.project},
                :remote => true,
                :method => 'get' %>
  </span>
</p>

EOS
)
