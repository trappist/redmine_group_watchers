class GroupWatchersController < ApplicationController
  before_filter :find_project
  before_filter :require_login, :check_project_privacy, :only => [:watch, :unwatch]
  before_filter :authorize, :only => [:new, :destroy]
  helper :watchers

  def create
    if params[:watcher].is_a?(Hash) && request.post?
      user_ids = params[:watcher][:user_ids] || [params[:watcher][:user_id]]
      user_ids.each do |user_id|
        Watcher.create(:watchable => @watched, :user_id => user_id)
      end
    end
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => 'Watcher added.', :layout => true}}
      format.js
    end
  end

  def new
  end

  def destroy
    @watched.set_group_watcher(Principal.find(params[:group_id]||params[:user_id]), false) if request.post?
    respond_to do |format|
      format.html { redirect_to :back }
      format.js { render 'watchers/destroy' }
    end
  end

private
  def find_project
    if params[:object_type] && params[:object_id]
      klass = Object.const_get(params[:object_type].camelcase)
      return false unless klass.respond_to?('watched_by')
      @watched = klass.find(params[:object_id])
      @project = @watched.project
    elsif params[:project_id]
      @project = Project.visible.find_by_param(params[:project_id])
    end
  rescue
    render_404
  end

  def set_group_watcher(group, watching)
    @watched.set_group_watcher(group, watching)
    respond_to do |format|
      format.html { redirect_to_referer_or {render :text => (watching ? 'Group Watcher added.' : 'Group Watcher removed.'), :layout => true}}
      format.js { render :partial => 'set_watcher', :locals => {:user => group, :watched => @watched} }
    end
  end

  # If the user can manage watchers, he can manage group watchers
  #
  def authorize(ctrl = params[:controller], action = params[:action], global = false)
    allowed = User.current.allowed_to?({:controller => 'watchers', :action => action}, @project || @projects)
    if allowed
      true
    else
      if @project && @project.archived?
        render_403 :message => :notice_not_authorized_archived_project
      else
        deny_access
      end
    end
  end

end
