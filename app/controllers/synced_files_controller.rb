class SyncedFilesController < ApplicationController
  before_filter :set_page_title
  before_filter :get_path_details, :only => [:index]
  
  def index
    @nomadesk = Nomadesk.new(:host => 'teambox.nomadeskdemo.com', :user => "nomadesk@teambox.com", :pass => "password")
    
    if @organization.settings['nomadesk'] && @organization.settings['nomadesk']['bucket_name']
      @bucket = @nomadesk.get_bucket(@organization.settings['nomadesk']['bucket_name'])
      @files = @nomadesk.list(@bucket, params[:path])
    else
      # No bucket stored for the organisation redirect to new
      render :bucket_missing
    end
  end
  
  protected
    def get_path_details
      params[:path] ||= ""
      @path = "/#{params[:path]}"
      @folders = params[:path].split("/")
      @parent = (@folders[0,@folders.length-1] || []).join("/")
    end
end
